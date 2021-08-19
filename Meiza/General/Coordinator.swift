//
//  Coordinator.swift
//  Meiza
//
//  Created by Denis Windover on 05/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation


class Coordinator {
    
    static let shared = Coordinator()
    
    func pushShops(_ shops: [ShopBasic], tags: [Tag], title: String){
        let vc = _shopsVC
        vc.viewModel = ShopsViewModel(shops, tags: tags, title: title)
        NAV.pushViewController(vc, animated: true)
    }
    
    func pushSplash(){
        let vc = _splashVC
        DispatchQueue.main.async {
            NAV.presentedViewController?.dismiss(animated: false, completion: nil)
            NAV.setAnimationFadeEffect()
            NAV.viewControllers = [vc]
        }
    }
    
    func logout(){
        NAV.setAnimationFadeEffect()
    }
    func goBack(){
        NAV.popViewController(animated: true)
    }
    func pushMain(_ clearStack: Bool = true){
        
        if clearStack {
            NAV.setAnimationFadeEffect()
            NAV.viewControllers = [_mainVC]
        }else{
            NAV.pushViewController(_mainVC, animated: true)
        }
        
    }
    func popMain(_ categoryIndex: Int? = nil, orderID: Int? = nil){
        guard let mainVC = NAV.viewControllers.first(where: { $0 is MainVC }) as? MainVC else{ return }
        let index = categoryIndex ?? mainVC.viewModel.currentCategoryIndex.value
        mainVC.viewModel.currentCategoryIndex.accept(index)
        mainVC.viewModel.orderID = orderID
        NAV.popToViewController(mainVC, animated: orderID == nil)
    }
    func pushCheckout(){
        NAV.pushViewController(_checkoutVC, animated: true)
    }
    func pushSummary(_ branch: Branch?){
        
        let vc = _summaryVC
        vc.viewModel = SummaryViewModel(branch)
        
        if !(NAV.viewControllers[NAV.viewControllers.count - 1] is SummaryVC) {
            NAV.pushViewController(vc, animated: true)
        }
    }
    func pushAddressDetails(_ order: NewOrder?){
        if !(NAV.viewControllers.last is AddressDetailsVC) {
            let vc = _addressDetailsVC
            vc.viewModel = AddressDetailsViewModel(order)
            NAV.pushViewController(vc, animated: true)
        }
    }
    func pushCreditCardDetails(_ order: NewOrder){
        let vc = _creditCartDetailsVC
        vc.viewModel = CreditCardDetailsViewModel(order)
        NAV.pushViewController(vc, animated: true)
    }
    func pushCVVConfirmation(_ order: NewOrder){
        let vc = _cvvConfirmationVC
        vc.viewModel = CVVConfirmationViewModel(order)
        NAV.pushViewController(vc, animated: true)
    }
    func pushSearch(){
        NAV.pushViewController(_searchVC, animated: true)
    }
    func openMenuVC(){
        NAV.present(_menuVC, animated: false, completion: nil)
    }
    func pushInfo(_ type: InfoType){
        if !(NAV.viewControllers.last is InfoVC) || (NAV.viewControllers.last as? InfoVC)?.viewModel.type != type {
            let vc = _infoVC
            vc.viewModel = InfoViewModel(type)
            NAV.pushViewController(vc, animated: true)
        }
    }
    func pushOrders(_ orderID: Int? = nil){
        if !(NAV.viewControllers.last is OrdersVC) {
            let vc = _ordersVC
            vc.viewModel = OrdersViewModel(orderID)
            NAV.pushViewController(vc, animated: orderID == nil)
        }
    }
    func pushOrder(_ order: Order, animated: Bool = true){
        let vc = _orderVC
        vc.viewModel = OrderViewModel(order)
        NAV.pushViewController(vc, animated: animated)
    }
    func pushSupport(){
        if !(NAV.viewControllers.last is SupportVC) {
            NAV.pushViewController(_supportVC, animated: true)
        }
    }
    func pushCart() {
        NAV.pushViewController(_cartVC, animated: true)
    }
    func image(_ img: UIImage) {
        let vc = _imageVC
        vc.image = img
        
        NAV.pushViewController(vc, animated: true)
    }
    
    func popToSummaryVCAfterOrderDateError() {
        
        Loader.show()
        
        AppData.shared.updateAllData { [unowned self] in
            if NAV.viewControllers.count > 3, let existSummaryVC = NAV.viewControllers.first(where: { $0 is SummaryVC }) as? SummaryVC {
                
                let vc = _summaryVC
                vc.viewModel = SummaryViewModel(existSummaryVC.viewModel.branch)
                
                NAV.setAnimationFadeEffect()
                NAV.viewControllers = [NAV.viewControllers[0], NAV.viewControllers[1], NAV.viewControllers[2], vc]
                Loader.dismiss()
            }
        }
        
    }
    
    func map(_ newOrder: NewOrder){
   
        let vc = _mapVC
        vc.order = newOrder
        
        NAV.pushViewController(vc, animated: true)
    }
    
//    func searchAddress(completion: @escaping(_ lat: Double, _ lon: Double, _ address: String)->()){
//        let vc = _searchAddressVC
//        vc.didGetAddress = { coord in
//            completion(coord.lat, coord.lon, coord.address)
//        }
//        NAV.present(vc, animated: true, completion: nil)
//    }
    
    func searchAddress(_ order: NewOrder){
        
        let vc = _searchAddressVC
        vc.order = order
        NAV.pushViewController(vc, animated: true)
    }
    
    func bill(_ link: String){
        let vc = _billVC
        vc.link = link
        NAV.present(vc, animated: true, completion: nil)
    }
    
    func editPack(_ pack: CartProduct){
        let vc = _packProductsVC
        vc.viewModel = PackProductsViewModel(pack)
        NAV.pushViewController(vc, animated: true)
    }
    
    func level(_ level: Level, levelProductToDelete levelProduct: CartProduct){
        let vc = _levelVC
        vc.viewModel = LevelViewModel(level, levelProductToDelete: levelProduct)
        
        NAV.pushViewController(vc, animated: true)
    }
    
    func level(_ product: Product, cartProduct: CartProduct?, levelIndex: Int = 0){
        
        let vc = _levelVC
        var _product = product
        if cartProduct == nil {
            _product = Product(product: product)
        }
        
        vc.viewModel = LevelViewModel(_product, cartProduct: cartProduct ?? CartProduct(_product), levelIndex: levelIndex)
        
        NAV.pushViewController(vc, animated: true)
    }
    
    func oneMorePack(_ product: Product){
        guard let mainVC = NAV.viewControllers.first(where: { $0 is MainVC }) as? MainVC else { return }
        mainVC.isNeedToClearPack = false
        let vc = _levelVC
        let _product = Product(product: product)
        vc.viewModel = LevelViewModel(_product, cartProduct: CartProduct(_product), levelIndex: 0)
        NAV.viewControllers = [mainVC]
        NAV.pushViewController(vc, animated: true)
    }
    
}

extension Coordinator{
    
    private var _splashVC: SplashVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SplashVC") as! SplashVC
    }
    private var _mainVC: MainVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainVC") as! MainVC
    }
    private var _checkoutVC: CheckoutVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CheckoutVC") as! CheckoutVC
    }
    private var _summaryVC: SummaryVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SummaryVC") as! SummaryVC
    }
    private var _addressDetailsVC: AddressDetailsVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddressDetailsVC") as! AddressDetailsVC
    }
    private var _creditCartDetailsVC: CreditCartDetailsVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CreditCartDetailsVC") as! CreditCartDetailsVC
    }
    private var _cvvConfirmationVC: CVVConfirmationVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CVVConfirmationVC") as! CVVConfirmationVC
    }
    private var _searchVC: SearchVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchVC") as! SearchVC
    }
    private var _menuVC: MenuVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MenuVC") as! MenuVC
    }
    private var _infoVC: InfoVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "InfoVC") as! InfoVC
    }
    private var _ordersVC: OrdersVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OrdersVC") as! OrdersVC
    }
    private var _orderVC: OrderVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OrderVC") as! OrderVC
    }
    private var _supportVC: SupportVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SupportVC") as! SupportVC
    }
    private var _cartVC: CartVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CartVC") as! CartVC
    }
    private var _imageVC: ImageVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ImageVC") as! ImageVC
    }
    private var _mapVC: MapVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MapVC") as! MapVC
    }
    private var _searchAddressVC: SearchAddressVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchAddressVC") as! SearchAddressVC
    }
    private var _billVC: BillVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BillVC") as! BillVC
    }
    private var _shopsVC: ShopsVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ShopsVC") as! ShopsVC
    }
    private var _packProductsVC: PackProductsVC{
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PackProductsVC") as! PackProductsVC
    }
    private var _levelVC: LevelVC{
        return UIStoryboard(name: "Pack", bundle: nil).instantiateViewController(withIdentifier: "LevelVC") as! LevelVC
    }
    
}
