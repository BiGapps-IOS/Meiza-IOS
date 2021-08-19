//
//  LoginVC.swift
//  Meiza
//
//  Created by Denis Windover on 05/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxAnimated

////MARK: - VIEWMODEL
//class LoginViewModel {
//
//    let disposeBag     = DisposeBag()
//    var isEnterEnabled = BehaviorRelay<Bool>(value: false)
//    var enterDidTap    = PublishSubject<Void>()
//    var marketCode     = BehaviorRelay<String?>(value: nil)
//    var loginDidTap    = PublishSubject<Void>()
//
//
//    init(){
//
//        enterDidTap
//            .withLatestFrom(marketCode)
//            .flatMap({ code in
//                return RequestManager.shared.setShop(code ?? "")
//            }).subscribe(onNext: { [weak self] result in
//                if let shop = result.shop {
//                    self?.getProducts(shop, cartProductIDs: AppData.shared.cartProducts.value.map({ $0.productID }))
//                }
//                if let error = result.error {
//                    error.toast(3)
//                }
//            }).disposed(by: disposeBag)
//
//
//        marketCode.filter({ $0 != nil }).map({ !$0!.isEmpty }).bind(to: isEnterEnabled).disposed(by: disposeBag)
//
//        loginDidTap.subscribe(onNext: { [weak self] _ in
//            AlertCoordinator.shared.verifyPhone { [weak self] phone in
//                AlertCoordinator.shared.verifyCode(phone) { [weak self] userID in
//                    User.currentUser?.id = userID
//                    self?.getShop()
//                }
//            }
//        }).disposed(by: disposeBag)
//
//    }
//
//    private func getShop(){
//        RequestManager.shared.setShop(shopID: User.currentUser?.shopID).subscribe(onNext: { [weak self] result in
//            if let shop = result.shop {
//                self?.getProducts(shop, cartProductIDs: AppData.shared.cartProducts.value.map({ $0.productID }))
//            }
//            if let error = result.error {
//                error.toast(4)
//            }
//        }).disposed(by: disposeBag)
//    }
//
//    private func getProducts(_ shop: Shop, cartProductIDs: [Int]){
//
//        func products(){
//            RequestManager.shared.getProducts(shop.id, cartProductIDs: cartProductIDs).subscribe(onNext: { result in
//                if let products = result.products {
//                    AppData.shared.categoryProducts = products.categoryProducts
//                    AppData.shared.products.accept(Set(products.cart))
//                    Coordinator.shared.pushMain()
//
//                }else if let error = result.error {
//                    error.toast()
//                }
//            }).disposed(by: self.disposeBag)
//        }
//
//
//        AlertCoordinator.shared.shop(shop) {
//            if User.currentUser == nil {
//                User.initCurrentUser(shop: shop)
//            }
//            AppData.shared.shop = shop
//
//            DispatchQueue.main.async {
//                if shop.id == 14 {
//
//                    AlertCoordinator.shared.alternativeIcon(UIImage(named: "AppIcon-14"), name: shop.name ?? "") { isAproved in
//                        if isAproved{
//                            if UIApplication.shared.supportsAlternateIcons {
//
//                                UIApplication.shared.setAlternateIconName("AppIcon-14") { _ in
//
//                                    products()
//
//                                }
//                                return
//                            }
//                        }else{
//                            products()
//                        }
//                    }
//                    return
//                }
//
//                products()
//            }
//        }
//
//    }
//
////    private func getProducts
//
//}
//
//
////MARK: - VIEW
//class LoginVC: BaseVC {
//
//    @IBOutlet weak var txtMarketNum: UITextField!
//    @IBOutlet weak var btnEnter: UIButton!
//    @IBOutlet weak var btnLogin: UIButton!
//
//
//    var viewModel = LoginViewModel()
//
//    let btnLoginAttributes: [NSAttributedString.Key: Any] = [
//    .font: UIFont(name: "Heebo-Regular", size: 14)!,
//    .foregroundColor: UIColor.black,
//    .underlineStyle: NSUnderlineStyle.single.rawValue]
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        let attr = NSMutableAttributedString(string: "התחבר", attributes: btnLoginAttributes)
//
//        btnLogin.setAttributedTitle(attr, for: .normal)
//
//        //MARK: - OUTPUTS
//        btnLogin.rx.tap.bind(to: viewModel.loginDidTap).disposed(by: disposeBag)
//        txtMarketNum.rx.text.bind(to: viewModel.marketCode).disposed(by: disposeBag)
//        btnEnter.rx.tap.bind(to: viewModel.enterDidTap).disposed(by: disposeBag)
//        btnEnter.rx.tap.subscribe(onNext: { [weak self] _ in
//            self?.view.endEditing(true)
//        }).disposed(by: disposeBag)
//
//        //MARK: - INPUTS
//        viewModel.isEnterEnabled.map({ $0 ? 1 : 0.5 }).bind(to: btnEnter.rx.animated.fade(duration: 0.5).alpha).disposed(by: disposeBag)
//        viewModel.isEnterEnabled.bind(to: btnEnter.rx.isEnabled).disposed(by: disposeBag)
//    }
//
//
//}
