//
//  SplashVC.swift
//  Meiza
//
//  Created by Denis Windover on 06/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

//MARK: - VIEWMODEL
class SplashViewModel {
    
    let disposeBag           = DisposeBag()
    private var shop         = BehaviorRelay<Shop?>(value: nil)
    private var cartProducts = BehaviorRelay<Set<Product>?>(value: nil)
    
    init(){
        
        let isDataCompleted: Observable<Bool> = Observable<Bool>.combineLatest(shop, cartProducts){ shop, cartProducts in
            return shop != nil && cartProducts != nil
        }
        
        isDataCompleted.subscribe(onNext: { complete in
            if complete{
                Coordinator.shared.pushMain()
            }
        }).disposed(by: disposeBag)
        
        shop.filter({ $0 != nil }).subscribe(onNext: { [weak self] _shop in
            if User.currentUser == nil {
                User.initCurrentUser(shop: _shop!)
            }
            AppData.shared.shop = _shop
            self?.getProducts(AppData.shared.cartProducts.value.map({ $0.productID }))
        }).disposed(by: disposeBag)
        
        cartProducts.filter({ $0 != nil }).map({ $0! }).bind(to: AppData.shared.products).disposed(by: disposeBag)
        
        setShop()
        
    }
    
    private func setShop(){
        
        RequestManager.shared.setShop(false).subscribe(onNext: { [weak self] result in
            if let shop = result.shop {
                self?.shop.accept(shop)
            }else if let _ = result.error {
                self?.setShop()
            }
        }).disposed(by: disposeBag)
    }
    
    private func getProducts(_ cartProductIDs: [Int]){
        RequestManager.shared.getProducts(cartProductIDs, loader: false).subscribe(onNext: { [weak self] result in
            if let products = result.products {
                AppData.shared.categoryProducts = products.categoryProducts
                self?.cartProducts.accept(Set(products.cart))
            }else if let error = result.error {
                error.toast()
            }
        }).disposed(by: disposeBag)
    }
    
    
}

//MARK: - VIEW
class SplashVC: BaseVC {
    
    @IBOutlet weak var viewLoader: UIView!
    @IBOutlet weak var lblVersion: UILabel!{
        didSet{
            lblVersion.text = APP_VERSION
        }
    }
    

    var viewModel: SplashViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        RequestManager.shared.getShops { [weak self] title, shops, tags in
            if shops.count == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self?.viewModel = SplashViewModel()
                }
            }else{

                Coordinator.shared.pushShops(shops, tags: tags, title: title)
            }
        }

        viewLoader.addSubview(Loader.getProgressIndicatorView(withFrame: CGRect.init(x: 0, y: 0, width: 50, height: 50), color: AppData.shared.mainColor))
    }
    
    
    @IBAction func btnBigappsTapped(_ sender: UIButton) {
        guard let url = URL(string: "http://bigapps.co.il/") else{ return }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
}
