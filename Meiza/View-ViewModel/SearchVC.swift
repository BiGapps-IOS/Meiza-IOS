//
//  SearchVC.swift
//  Meiza
//
//  Created by Denis Windover on 19/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxAnimated

//MARK: - VIEWMODEL
class SearchViewModel {
    
    let disposeBag         = DisposeBag()
    var clearActiveProduct = PublishSubject<Void>()
    var searchText         = BehaviorRelay<String>(value: "")
    var products           = BehaviorRelay<[Product]>(value: [])
    
    init(){
        
        clearActiveProduct.map({ _ in return nil }).bind(to: AppData.shared.currentActiveProduct).disposed(by: disposeBag)
        
        searchText
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .flatMap({ $0.isEmpty ? Observable.just((products: [Product](), error: nil)) : RequestManager.shared.searchProducts($0.trimmingCharacters(in: .whitespacesAndNewlines), categoryId: nil) })
            .map({ $0.products != nil ? $0.products! : [] })
            .bind(to: products).disposed(by: disposeBag)
        
    }
    
}

//MARK: - VIEW
class SearchVC: BaseVC {
    
    
  
    @IBOutlet weak var tblViewProducts: UITableView!
    @IBOutlet weak var txtSearch: UITextField!
    @IBOutlet weak var ivSearchIcon: UIImageView!{
        didSet{ ivSearchIcon.imageColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var viewSearch: UIView!
    
    
    var viewModel = SearchViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnBack.setImageColor(color: AppData.shared.mainColor)
        btnMenu.setImageColor(color: AppData.shared.mainColor)
        
        txtSearch.becomeFirstResponder()
        
        txtSearch.rx.text.orEmpty
        .scan("") { prev, new -> String in
            if new.containsEmoji{
                return prev ?? ""
            }else{
                return new
            }
        }.subscribe(txtSearch.rx.text).disposed(by: disposeBag)

        tblViewProducts.rx.setDelegate(self).disposed(by: disposeBag)
        
        //MARK: - OUTPUTS
        txtSearch.rx.text.orEmpty.bind(to: viewModel.searchText).disposed(by: disposeBag)
        
        
        //MARK: - INPUTS
        viewModel.products.bind(to: tblViewProducts.rx.items(cellIdentifier: "ProductCell2", cellType: ProductCell2.self)){ item, product, cell in
            cell.viewModel = ProductCell2ViewModel(product)
            cell.viewMain?.dropShadow()
        }.disposed(by: disposeBag)
    }
    
    var didLoad = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didLoad{
            didLoad = true
            viewSearch.dropShadow()
        }
    }

}

extension SearchVC: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }

}

//MARK: - TABLEVIEW DELEGATE
extension SearchVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as? ProductCell2)?.ivProduct.image = nil
    }

}
