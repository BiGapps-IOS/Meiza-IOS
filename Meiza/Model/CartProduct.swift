//
//  CartProduct.swift
//  Meiza
//
//  Created by Denis Windover on 07/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation


class CartProduct: Codable, Equatable, Hashable {
    
    var _tmpID: String = Date().millisecondsSince1970.toString
    var productID: Int
    private var _amount:    Double
    var unitType:  String
    var isChosen:  Bool = true
    var comment:   String?
    private var _product: Product?
    var toppings = [[Topping]]()
    var pizzaToppings: [[PizzaTopping]] = []
    var productOptions: [ProductOption] = []
    var levels: [Level] = []
    var currentLevelIndex: Int?
    
    static func == (lhs: CartProduct, rhs: CartProduct) -> Bool {
        return lhs._tmpID == rhs._tmpID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(_tmpID)
    }
    
    init(_ product: Product?){
        self._product = product
        self.productID = 0
        self._amount = 1
        self.unitType = "unit"
    }
    
    init(productID: Int, amount: Double, unitType: String, comment: String? = nil){
        self.productID = productID
        self._amount   = amount
        self.unitType  = unitType
        self.comment   = comment
    }
    
    func setProduct(_ product: Product){
        self._product = product
        if product.type == .pack {
            levels = product.levels
        }
    }
    
    func setComment(_ comment: String?){
        self.comment = comment
        AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value)
        CartProduct.saveCartProducts(AppData.shared.cartProducts.value)
    }
    
    var product: Product? {
        return _product ?? AppData.shared.products.value.first(where: { $0.id == self.productID })
    }
    
    var price: Double {
        
        var toppingsPrice: Double = 0
        var toppingsCount: Int = 0
        
        if product?.type == .pack {
            var _price: Double = 0.0
            if let _p = product?.unitTypes.first(where: { $0.type == unitType }) {
                _price += _p.price
            }
            levels.forEach({ _price += $0.levelPrice() })
            return _price
            
        }else if product?.type == .pizza {
            toppingsCount = pizzaToppings.count
            toppingsPrice = pizzaToppings.reduce(0.0) { res, topping -> Double in
                return res + topping.reduce(0.0, { (_res, _topping) -> Double in
                    return _res + Double(_topping.price)
                })
            }
        }else{
            toppingsCount = toppings.count
            toppingsPrice = toppings.reduce(0.0) { res, topping -> Double in
                return res + topping.reduce(0.0, { (_res, _topping) -> Double in
                    return _res + Double(_topping.price)
                })
            }
        }
        
        let productOptionsPrice: Double = productOptions.reduce(0.0) { res, option -> Double in
            return res + option.price
        }
        
        if let _product = product, let type = _product.unitTypes.first(where: { $0.type == unitType }) {
            return (toppingsCount > 0 ? Double(toppingsCount) * type.price : _amount * type.price) + toppingsPrice + productOptionsPrice
        }
        return 0.0
    }
    
    var amount: Double {
        if product?.type == .pack {
            return 1
        }
        else if product?.type == .pizza {
            return pizzaToppings.count > 0 ? Double(pizzaToppings.count) : 1
        }
        return toppings.count > 0 ? Double(toppings.count) : _amount
    }
    
    static func getCartProducts() -> [CartProduct] {
        guard let data = UserDefaults.standard.value(forKey: "cartProducts") as? Data,
            let cartProducts = try? PropertyListDecoder().decode([CartProduct].self, from: data) else{ return [] }
        return cartProducts
    }
    
    static func saveCartProducts(_ cartProducts: [CartProduct]) {
        let _cartProducts = cartProducts
        _cartProducts.forEach({ $0._product = nil })
        if let encoded = try? PropertyListEncoder().encode(_cartProducts){
            UserDefaults.standard.set(encoded, forKey: "cartProducts")
        }else{
            print("!!!ERROR SAVING CART PRODUCTS!!!")
        }
        AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value) // to refresh prices of cart products
    }

    
    static func updateIsChosen(for cartProduct: CartProduct?){
        guard let cartProduct = cartProduct else{ return }
        cartProduct.isChosen = !cartProduct.isChosen
        AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value)
        CartProduct.saveCartProducts(AppData.shared.cartProducts.value)
    }
    
    static func updateIsChosenAllObjects(_ value: Bool){
        AppData.shared.cartProducts.value.forEach({ $0.isChosen = value })
        AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value)
        CartProduct.saveCartProducts(AppData.shared.cartProducts.value)
    }
    
    static func removeProductFromCart(_ product: Product?, cartProduct: CartProduct?){
        guard let product = product else{ return }
        
        if let cartProduct = cartProduct, product.type == .pack {
            AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value.filter({ $0._tmpID != cartProduct._tmpID }))
        }else{
            AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value.filter({ $0.productID != product.id }))
            AppData.shared.products.accept(AppData.shared.products.value.filter({ $0.id != product.id }))
        }
        
        CartProduct.saveCartProducts(AppData.shared.cartProducts.value)
        
    }
    
    static func addPackToCart(_ pack: CartProduct, product: Product){
//        pack.setProduct(product)
        var set = AppData.shared.products.value
        set.insert(product)
        AppData.shared.products.accept(set)
        AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value + [pack])
        CartProduct.saveCartProducts(AppData.shared.cartProducts.value)
        
        if IS_NEED_REMIND_ORDER { RequestManager.shared.remindOrder() }
    }
    
    static func addToCart(_ product: Product?, amount: Double, unitType: String){
        guard let product = product else{ return }
        
        let cartProduct = CartProduct(productID: product.id, amount: amount, unitType: unitType)
        var set = AppData.shared.products.value
        set.insert(product)
        AppData.shared.products.accept(set)
        AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value.filter({ $0.productID != cartProduct.productID }) + [cartProduct])
        CartProduct.saveCartProducts(AppData.shared.cartProducts.value)
        
        if IS_NEED_REMIND_ORDER { RequestManager.shared.remindOrder() }
        
    }
    
    static func addToCartWithPizzaToppings(_ product: Product?, pizzaToppings: [PizzaTopping], option: ProductOption){
        let unitType = "unit"
        let amount: Double = 1
        guard let product = product else{ return }
        
        if AppData.shared.cartProducts.value.first(where: { $0.productID == product.id }) != nil {
            AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.pizzaToppings.append(pizzaToppings)
            AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.productOptions.append(option)
            AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value)
        }else{
            let cartProduct = CartProduct(productID: product.id, amount: amount, unitType: unitType)
            cartProduct.pizzaToppings.append(pizzaToppings)
            cartProduct.productOptions.append(option)
            var set = AppData.shared.products.value
            set.insert(product)
            AppData.shared.products.accept(set)
            AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value.filter({ $0.productID != cartProduct.productID }) + [cartProduct])
        }
        
        CartProduct.saveCartProducts(AppData.shared.cartProducts.value)
        
    }
    
    static func addToCartWithToppings(_ product: Product?, toppings: [Topping], option: ProductOption?){
        let unitType = "unit"
        let amount: Double = 1
        guard let product = product else{ return }
        
        if AppData.shared.cartProducts.value.first(where: { $0.productID == product.id }) != nil {
            AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.toppings.append(toppings)
            AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.productOptions.append(option ?? ProductOption.productOptionNil())
            AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value)
        }else{
            let cartProduct = CartProduct(productID: product.id, amount: amount, unitType: unitType)
            cartProduct.toppings.append(toppings)
            cartProduct.productOptions.append(option ?? ProductOption.productOptionNil())
            var set = AppData.shared.products.value
            set.insert(product)
            AppData.shared.products.accept(set)
            AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value.filter({ $0.productID != cartProduct.productID }) + [cartProduct])
        }
        
        CartProduct.saveCartProducts(AppData.shared.cartProducts.value)
        
    }
    
    static func removeTopping(_ product: Product, index: Int){
        
        if product.type == .pizza {
            if (AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.pizzaToppings.count ?? 0) > index {
                AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.pizzaToppings.remove(at: index)
                if (AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.productOptions.count ?? 0) > index {
                    AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.productOptions.remove(at: index)
                }
                
                // if no topping remains then need to delete cartProduct from cartProducts
                if (AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.pizzaToppings.count ?? 0) == 0 {
                    AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value.filter({ $0.productID != product.id }))
                    AppData.shared.products.accept(AppData.shared.products.value.filter({ $0.id != product.id }))
                }else{
                    AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value)
                }
            }
        }else{
            if (AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.toppings.count ?? 0) > index {
                AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.toppings.remove(at: index)
                // if no topping remains then need to delete cartProduct from cartProducts
                if (AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.toppings.count ?? 0) == 0 {
                    AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value.filter({ $0.productID != product.id }))
                    AppData.shared.products.accept(AppData.shared.products.value.filter({ $0.id != product.id }))
                }else{
                    AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value)
                }
            }
        }
        
        CartProduct.saveCartProducts(AppData.shared.cartProducts.value)
        
    }
    
    static func isChosenAll() -> Bool {
        return !AppData.shared.cartProducts.value.contains(where: { $0.isChosen == false })
    }
    
    static func deleteAllCartProducts(){
        UserDefaults.standard.removeObject(forKey: "cartProducts")
        AppData.shared.cartProducts.accept([])
        AppData.shared.products.accept(Set<Product>())
    }
}
