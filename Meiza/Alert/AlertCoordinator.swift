//
//  AlertCoordinator.swift
//  Meiza
//
//  Created by Denis Windover on 05/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class AlertCoordinator{
    
    static let shared = AlertCoordinator()
    
    func verifyPhone(phone: @escaping(String)->()){
        let alert = _verifyPhoneAlert
        alert.phone = { _phone in
            phone(_phone)
        }
        NAV.present(alert, animated: false, completion: nil)
    }
    func removeProductFromCart(remove: @escaping()->()){
        let alert = _removeProductFromCartAlert
        alert.remove = {
            remove()
        }
        
        if NAV.presentedViewController != nil {
            NAV.presentedViewController?.present(alert, animated: false, completion: nil)
        }else{
            NAV.present(alert, animated: false, completion: nil)
        }
    }
    
    var _timestamp: Double = 0
    func productWasAdded(_ status: String, imageUrl: String?, timestamp: Double = Date().timeIntervalSince1970){
        
        if _timestamp == 0 {
            _timestamp = timestamp
        }
        
        if _timestamp != timestamp { return }
        
        if NAV.presentedViewController != nil && AppData.shared.editingPack.value != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.productWasAdded(status, imageUrl: imageUrl, timestamp: timestamp)
            }
            return
        }
        
        let alert = _productWasAddedAlert
        alert.imageUrl = imageUrl
        var message = "המוצר התווסף בהצלחה".localized
        switch status {
        case "update":
            message = "המוצר עודכן".localized
        case "remove":
            message = "המוצר הוסר בהצלחה".localized
        default:
            break
        }
        
        alert.message = message
        
        _timestamp = 0
        
        if NAV.presentedViewController != nil {
            NAV.presentedViewController?.present(alert, animated: false, completion: nil)
        }else{
            NAV.present(alert, animated: false, completion: nil)
        }
        
    }
    func shop(_ shop: Shop, enter: @escaping()->()){
        let alert = _shopAlert
        alert.shop = shop
        alert.enter = {
            enter()
        }
        if NAV.presentedViewController != nil {
            NAV.presentedViewController?.present(alert, animated: false, completion: nil)
        }else{
            NAV.present(alert, animated: false, completion: nil)
        }
        
    }
    func pushNotification(){
        NAV.present(_pushNotificationAlert, animated: false, completion: nil)
    }
    func verifyCode(_ phone: String, userID: @escaping(Int)->()){
        let alert = _verifyCodeAlert
        alert.viewModel = VerifyCodeViewModel(phone)
        alert.userID = { _userID in
            userID(_userID)
        }
        NAV.present(alert, animated: false, completion: nil)
    }
    func orderSuccess(_ paymentType: String = "credit", orderID: Int){
        let alert = _orderSuccessAlert
        alert.paymentType = paymentType
        alert.orderID = orderID
        NAV.present(alert, animated: false, completion: nil)
    }
    func logout(logout: @escaping()->()){
        let alert = _logoutAlert
        alert.logout = {
            logout()
        }
        NAV.presentedViewController?.present(alert, animated: false, completion: nil)
    }
    
    func calendar(_ delivertType: String) -> Observable<String?> {
        
        let alert = _calendarAlert
        alert.deliveryType = delivertType
        NAV.present(alert, animated: false, completion: nil)
        
        return Observable.create { observer in
            
            alert.actionDate = { dateStr in
                observer.onNext(dateStr)
            }
            
            return Disposables.create()
        }
        
    }
    
    func alternativeIcon(_ icon: UIImage?, name: String, completion: @escaping(Bool)->()) {
        
        let alert = _alternativeIconAlert
        alert.viewModel = AlternativeIconViewModel(icon, name: name)
        alert.isIconAproved = { isApreoved in
            completion(isApreoved)
        }
        
        NAV.present(alert, animated: false, completion: nil)
        
    }
    
    func productDescription(_ product: Product?, cartProduct: CartProduct? = nil) {
        guard product != nil || cartProduct != nil else { return }
        let alert = _productDescriptionAlert
        alert.product = product
        alert.cartProduct = cartProduct
        NAV.present(alert, animated: false, completion: nil)
    }
    
    func productComment(_ cartProduct: CartProduct) {
        let alert = _productCommentAlert
        alert.cartProduct = cartProduct
        NAV.present(alert, animated: false, completion: nil)
    }
    
    func toppings(_ product: Product, level: Level? = nil, existLevelProduct: CartProduct? = nil, isProductForReplacing: Bool = false) {
        let alert = _toppingsAlert
        alert.viewModel = ToppingAlertViewModel(product, level: level, existLevelProduct: existLevelProduct, isProductForReplacing: isProductForReplacing)
        NAV.present(alert, animated: false, completion: nil)
    }
    
    func additionalProduct(completion: @escaping(Bool)->()) {
        let alert = _additionalProductAlert
        alert.actionAdd = { action in
            completion(action)
        }
        
        NAV.presentedViewController?.present(alert, animated: false, completion: nil)
    }
    
    func addSameProduct(_ isPizza: Bool = false) -> Observable<Bool> {
        
        let alert = _additionalProductAlert
        alert.isPizza = isPizza
        
        NAV.presentedViewController?.present(alert, animated: false, completion: nil)
        
        return Observable.create { observer in
            
            alert.actionAdd = { action in
                observer.onNext(action)
            }
            
            return Disposables.create()
        }
        
    }
    
    func radiusErrorOrder() {
        if NAV.presentedViewController != nil {
            NAV.presentedViewController?.present(_radiusErrorOrderAlert, animated: false, completion: nil)
        }else{
            NAV.present(_radiusErrorOrderAlert, animated: false, completion: nil)
        }
        
    }
    func minimumErrorOrder() {
        NAV.present(_minimumErrorOrderAlert, animated: false, completion: nil)
    }
    func usedToppings(_ orderProduct: OrderProduct) {
        let alert = _usedToppingsAlert
        alert.viewModel = UsedToppingAlertViewModel(orderProduct)
        NAV.present(alert, animated: false, completion: nil)
    }
    
    func dateError(_ orderType: String, completion: @escaping()->()) {
        let alert = _dateErrorAlert
        alert.orderType = orderType
        alert.actionOK = {
            completion()
        }
        NAV.present(alert, animated: false, completion: nil)
    }
    
    func coupon(){
        NAV.present(_couponAlert, animated: false, completion: nil)
    }
    func couponSuccess(_ discount: Double){
        let alert = _couponSuccessAlert
        alert.discount = discount
        NAV.present(alert, animated: false, completion: nil)
    }
    
    func deliveryCost(completion: @escaping()->()) {
        
        if AppData.shared.deliveryCost == 0 {
            let alert = _deliveryCostZeroAlert
            alert.actionContinue = {
                completion()
            }
            NAV.present(alert, animated: false, completion: nil)
        }else{
            let alert = _deliveryCostAlert
            alert.actionContinue = {
                completion()
            }
            NAV.present(alert, animated: false, completion: nil)
        }
    }
    
    func branches(completion: @escaping(Branch?)->()){
        
        if AppData.shared.shop.branches.count == 0 {
            completion(nil)
        }else{
            let alert = _branchesAlert
            alert.viewModel = BranchesViewModel(AppData.shared.shop.branches)
            alert.actionContinue = { _branch in
                completion(_branch)
            }
            NAV.present(alert, animated: false, completion: nil)
        }
        
    }
    
    func productOptions(_ productOptions: [ProductOption], title: String? = nil, level: Level?) -> Observable<ProductOption> {
        
        let vc = _productOptionsAlert
        vc.viewModel = ProductOptionsViewModel(productOptions, title: title, level: level)
        NAV.presentedViewController?.present(vc, animated: false, completion: nil)
        
        return Observable.create { observer in
            
            vc.optionAction = { option in
                observer.onNext(option)
            }
            
            return Disposables.create()
        }
        
    }
    
    func welcomeShop(_ shop: ShopBasic, completion: @escaping()->()){
        let alert = _welcomeShopAlert
        alert.shop = shop
        alert.actionStart = {
            completion()
        }
        
        NAV.present(alert, animated: false, completion: nil)
    }
    
    func toast(text: String, interval: Double = 1, isLast: Bool = false){
        let alert = _toastAlert
        alert.interval = interval
        alert.message = text
        alert.isLastProduct = isLast
        
        if NAV.presentedViewController != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                self.toast(text: text, interval: interval, isLast: isLast)
            })
        }else{
            NAV.present(alert, animated: false, completion: nil)
        }
    }
    
    func pack(completion: @escaping()->()){
        let alert = _packAlert
        alert.oneMore = {
            completion()
        }
        
        NAV.present(alert, animated: false, completion: nil)
    }
    
    func finishPack(_ product: Product){
        let alert = _finishPackAlert
        alert.product = product
        
        if NAV.presentedViewController != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                self.finishPack(product)
            })
        }else{
            NAV.present(alert, animated: false, completion: nil)
        }
    }

    
}


//MARK: REFERENCES
extension AlertCoordinator{
    
    private var _verifyPhoneAlert: VerifyPhoneAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "VerifyPhoneAlert") as! VerifyPhoneAlert
    }
    private var _removeProductFromCartAlert: RemoveProductFromCartAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "RemoveProductFromCartAlert") as! RemoveProductFromCartAlert
    }
    private var _productWasAddedAlert: ProductWasAddedAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "ProductWasAddedAlert") as! ProductWasAddedAlert
    }
    private var _shopAlert: ShopAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "ShopAlert") as! ShopAlert
    }
    private var _pushNotificationAlert: PushNotificationAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "PushNotificationAlert") as! PushNotificationAlert
    }
    private var _verifyCodeAlert: VerifyCodeAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "VerifyCodeAlert") as! VerifyCodeAlert
    }
    private var _orderSuccessAlert: OrderSuccessAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "OrderSuccessAlert") as! OrderSuccessAlert
    }
    private var _logoutAlert: LogoutAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "LogoutAlert") as! LogoutAlert
    }
    private var _calendarAlert: CalendarAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "CalendarAlert") as! CalendarAlert
    }
    private var _productDescriptionAlert: ProductDescriptionAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "ProductDescriptionAlert") as! ProductDescriptionAlert
    }
    private var _productCommentAlert: ProductCommentAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "ProductCommentAlert") as! ProductCommentAlert
    }
    private var _alternativeIconAlert: AlternativeIconAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "AlternativeIconAlert") as! AlternativeIconAlert
    }
    private var _toppingsAlert: ToppingsAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "ToppingsAlert") as! ToppingsAlert
    }
    private var _additionalProductAlert: AdditionalProductAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "AdditionalProductAlert") as! AdditionalProductAlert
    }
    private var _radiusErrorOrderAlert: RadiusErrorOrderAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "RadiusErrorOrderAlert") as! RadiusErrorOrderAlert
    }
    private var _minimumErrorOrderAlert: MinimumErrorOrderAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "MinimumErrorOrderAlert") as! MinimumErrorOrderAlert
    }
    private var _usedToppingsAlert: UsedToppingsAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "UsedToppingsAlert") as! UsedToppingsAlert
    }
    private var _dateErrorAlert: DateErrorAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "DateErrorAlert") as! DateErrorAlert
    }
    private var _couponAlert: CouponAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "CouponAlert") as! CouponAlert
    }
    private var _couponSuccessAlert: CouponSuccessAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "CouponSuccessAlert") as! CouponSuccessAlert
    }
    private var _deliveryCostAlert: DeliveryCostAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "DeliveryCostAlert") as! DeliveryCostAlert
    }
    private var _deliveryCostZeroAlert: DeliveryCostZeroAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "DeliveryCostZeroAlert") as! DeliveryCostZeroAlert
    }
    private var _branchesAlert: BranchesAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "BranchesAlert") as! BranchesAlert
    }
    private var _productOptionsAlert: ProductOptionsAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "ProductOptionsAlert") as! ProductOptionsAlert
    }
    private var _welcomeShopAlert: WelcomeShopAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "WelcomeShopAlert") as! WelcomeShopAlert
    }
    private var _toastAlert: ToastAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "ToastAlert") as! ToastAlert
    }
    private var _packAlert: PackAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "PackAlert") as! PackAlert
    }
    private var _finishPackAlert: FinishPackAlert{
        return UIStoryboard(name: "Alert", bundle: nil).instantiateViewController(withIdentifier: "FinishPackAlert") as! FinishPackAlert
    }
    
    
}
