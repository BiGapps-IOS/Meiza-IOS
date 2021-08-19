//
//  Level.swift
//  Meiza
//
//  Created by Denis Windover on 04/01/2021.
//  Copyright © 2021 BigApps. All rights reserved.
//

import Foundation
import ObjectMapper

class Level: Mappable, Codable, Equatable, Hashable {
    
    var id: Int!
    var description: String = ""
    var productsAmount: Int = 1
    var toppingsFree: Int = 0
    var optionsPaid: Bool = false
    var toppingsAddPaid: Bool = false
    var products: [Product] = [Product]()
    
    var selectedProducts: [CartProduct] = []
    
    required init?(map: Map) {
        if map.JSON["id"] == nil { return nil }
        mapping(map: map)
    }
    
    init(level: Level) {
        self.id              = level.id
        self.description     = level.description
        self.productsAmount  = level.productsAmount
        self.toppingsFree    = level.toppingsFree
        self.optionsPaid     = level.optionsPaid
        self.toppingsAddPaid = level.toppingsAddPaid
        self.products        = level.products
    }
    
    func levelPrice() -> Double {
        
        var price: Double = 0
        
        for selectedProduct in selectedProducts {
            if optionsPaid {
                selectedProduct.productOptions.forEach({ if $0.price > 0 { price += $0.price } })
            }
            if let pizzaToppings = selectedProduct.pizzaToppings.index(0) {
                for pizzaTopping in pizzaToppings {
                    if let _p = pizzaToppingPriceInCart(pizzaTopping, confirmedPizzaToppings: pizzaToppings + selectedProduct.productOptions) {
                        price += _p
                    }
                }
            }
            if let toppings = selectedProduct.toppings.index(0) {
                for i in 0..<toppings.count {
                    let topping = toppings[i]
                    if toppingsFree - i <= 0 {
                        price += topping.price
                    }
                }
            }
        }
        
        return price
    }
    
    func pizzaToppingPriceOutsideCart(_ confirmedPizzaToppings: [Any]) -> Double? {
        
        let maxFreePieces = toppingsFree * 4
        let currentPieces = confirmedPizzaToppings.filter({ !($0 is ProductOption) }).reduce(0) { res, topping -> Int in
            guard let pizzaTop = topping as? PizzaTopping else{ return res }
            return res + pizzaTop.pieces.count
        }
        
        if maxFreePieces - currentPieces > 0 {
            return 0
        }
        
        return nil
        
    }
    
    func pizzaToppingPriceInCart(_ topping: PizzaTopping?, confirmedPizzaToppings: [Any]) -> Double? {

        guard let topping = topping else{ return nil }
        
        let maxFreePieces = toppingsFree * 4
        var currentPieces = 0
        
        for i in 0..<confirmedPizzaToppings.filter({ !($0 is ProductOption ) }).count {
            if let confirmedTopping = (confirmedPizzaToppings.filter({ !($0 is ProductOption) })[i] as? PizzaTopping) {
                currentPieces += confirmedTopping.pieces.count
            }
            
            if topping == (confirmedPizzaToppings.filter({ !($0 is ProductOption) })[i] as? PizzaTopping) {
                if maxFreePieces - currentPieces >= 0 {
                    return 0
                }else{
                    let piecesForPaid = currentPieces - maxFreePieces
                    let quarterPrice: Double = topping.topping.price / 4
                    let piecesForPaidCurrentTopping = piecesForPaid >= topping.pieces.count ? topping.pieces.count : piecesForPaid
                    return Double(piecesForPaidCurrentTopping) * quarterPrice //Double(abs(maxFreePieces - currentPieces)) * quarterPrice
                }
            }
            
        }
        
        return nil
        
    }
    
    func toppingPriceInCart(_ topping: Topping?, confirmedToppings: [Any]) -> Double? {

        guard let topping = topping else{ return nil }
        
        var currentTopping = 0
        
        for i in 0..<confirmedToppings.filter({ !($0 is ProductOption ) }).count {
            if let _ = (confirmedToppings.filter({ !($0 is ProductOption) })[i] as? Topping) {
                currentTopping += 1
            }
            
            if topping == (confirmedToppings.filter({ !($0 is ProductOption) })[i] as? Topping) {
                if toppingsFree - currentTopping >= 0 {
                    return 0
                }else{
                    return topping.price
                }
            }
            
        }
        
        return nil
        
    }
    
    func mapping(map: Map) {
        self.id              <- map["id"]
        self.description     <- map["description"]
        self.productsAmount  <- map["productsAmount"]
        self.toppingsFree    <- map["toppingsFree"]
        self.optionsPaid     <- map["optionsPaid"]
        self.toppingsAddPaid <- map["toppingsAddPaid"]
        self.products        <- map["products"]
    }
    
    static func == (lhs: Level, rhs: Level) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
