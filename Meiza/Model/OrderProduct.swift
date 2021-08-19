//
//  OrderProduct.swift
//  Meiza
//
//  Created by Denis Windover on 19/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import ObjectMapper


class OrderProduct: Mappable {

    var amount:         Double!
    private var _price: Double?
    var unitType:       String!
    var comment:        String?
    var product:        Product!
    var usedToppings  = [UsedTopping]()
    var billLink:       String?
    var productOption:  ProductOption?
    
    var price: Double {
        return  (_price != nil ? amount * _price! : amount * (product.unitTypes.first(where: { $0.type == unitType })?.price ?? 0)) + toppingsPrice
    }
    
    private var toppingsPrice: Double {
        return usedToppings.reduce(0.0) { res, topping -> Double in
            return res + topping.total
        } + (productOption?.price ?? 0)
    }
    
    required init?(map: Map) {
        if map.JSON["amount"]      == nil { return nil }
        if map.JSON["unitType"]    == nil { return nil }
        if map.JSON["shopProduct"] == nil { return nil }
        
        mapping(map: map)
    }
    
    func mapping(map: Map) {
        self.amount       <- map["amount"]
        self._price       <- map["price"]
        self.unitType     <- map["unitType"]
        self.product      <- map["shopProduct"]
        self.comment      <- map["comment"]
        self.usedToppings <- map["toppings"]
        self.productOption <- map["productOption.shopProductOption"]
    }
    
}

class UsedTopping: Mappable {
    
    var id:    Int = 0
    var name:  String = ""
    var price: Double = 0.0
    var total: Double = 0.0
    
    required init?(map: Map) {
        mapping(map: map)
    }
    
    func mapping(map: Map) {
        self.id    <- map["shopTopping.id"]
        self.name  <- map["shopTopping.topping.name"]
        self.price <- map["price"]
        self.total <- map["total"]
    }
    
    
}
