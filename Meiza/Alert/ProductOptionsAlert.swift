//
//  ProductOptionsAlert.swift
//  Meiza
//
//  Created by Denis Windover on 15/11/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift


class ProductOptionsViewModel {
    
    let disposeBag = DisposeBag()
    var options = BehaviorRelay<[ProductOption]>(value: [])
    var optionDidSelect = PublishSubject<IndexPath>()
    var chosenOption = PublishSubject<ProductOption?>()
    var title = BehaviorRelay<String?>(value: nil)
    var level: Level?
    
    init(_ productOptions: [ProductOption], title: String?, level: Level?) {
        
        self.level = level
        Observable.just(productOptions).bind(to: options).disposed(by: disposeBag)
        
        self.title.accept(title ?? "\n")
        
        optionDidSelect.withLatestFrom(options) { indexPath, _options -> ProductOption? in
            return _options[indexPath.row]
        }.bind(to: chosenOption).disposed(by: disposeBag)
        
    }
    
}


class ProductOptionsAlert: AlertVC {
    
    
    @IBOutlet weak var tblProductOptions: UITableView!
    @IBOutlet weak var lblTitle: UILabel!{
        didSet{ lblTitle.textColor = AppData.shared.mainColor }
    }
    
    @IBOutlet weak var btnClose: UIButton!
    
    var viewModel: ProductOptionsViewModel!
    
    var optionAction: (ProductOption)->() = { _ in }

    override func viewDidLoad() {
        super.viewDidLoad()

        btnClose.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: {
                (NAV.presentedViewController as? AlertVC)?.dismiss(completion: nil)
            })
        }).disposed(by: disposeBag)
        
        tblProductOptions.rx.itemSelected.bind(to: viewModel.optionDidSelect).disposed(by: disposeBag)
        
        viewModel.options.bind(to: tblProductOptions.rx.items(cellIdentifier: "ToppingCell", cellType: ToppingCell.self)){ [weak self] row, option, cell in
            
            cell.lblName.text = option.name
            cell.lblPrice.text =
                option.price == 0 || self?.viewModel.level?.optionsPaid == false ? "ללא עלות".localized : "₪\(option.price.clean)"
            
        }.disposed(by: disposeBag)
        
        viewModel.chosenOption.subscribe(onNext: { [weak self] option in
            guard let option = option else{ return }
            
            self?.dismiss(completion: {
                self?.optionAction(option)
            })
            
        }).disposed(by: disposeBag)
        
        viewModel.title.bind(to: lblTitle.rx.text).disposed(by: disposeBag)
        
    }

}
