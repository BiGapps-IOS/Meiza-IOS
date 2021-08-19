//
//  Product.swift
//  Meiza
//
//  Created by Denis Windover on 06/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import ObjectMapper

enum ProductType: String {
    case regular, pizza, pack
}

class Product: Mappable, Equatable, Hashable, Codable {
    
    var id:                  Int!
    var isNew:               Bool = false
    var isStock:             Bool = false
    var isSeason:            Bool = false
    var isSale:              Bool = false
    var defaultUnitType:     String!
    var unitTypes:           [UnitType]!
    var name:                String = ""
    var image:               String?
    var imageBig:            String?
    var category:            String = ""
    var description:         String?
    var toppings           = [Topping]()
    var toppingsDescription:  String = ""
    var optionsDescription:  String = ""
    private var _type:       String = "regular"
    var productOptions:      [ProductOption] = []
    var maxToppings:          Int?
    var levels:              [Level] = []
    var subcategoryCodename: String?
    
    var type: ProductType {
        return ProductType(rawValue: _type) ?? .regular
    }
    
    var categoryID: Int {
        
        if let index = AppData.shared.shop.categories.firstIndex(where: { $0.codename == category }) {
            return index + 1
        }
        return 1
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(product: Product) {
        self.id                  = product.id
        self.isNew               = product.isNew
        self.isStock             = product.isStock
        self.isSeason            = product.isSeason
        self.isSale              = product.isSale
        self.defaultUnitType     = product.defaultUnitType
        self.unitTypes           = product.unitTypes
        self.name                = product.name
        self.category            = product.category
        self.image               = product.image
        self.imageBig            = product.imageBig
        self.description         = product.description
        self.toppings            = product.toppings
        self.toppingsDescription = product.toppingsDescription
        self._type               = product._type
        self.productOptions      = product.productOptions
        self.optionsDescription  = product.optionsDescription
        self.maxToppings         = product.maxToppings
        self.levels              = product.levels.compactMap({ Level(level: $0) })
        self.subcategoryCodename       = product.subcategoryCodename
    }
    
    required init?(map: Map) {
        if map.JSON["id"]              == nil { return nil }
        if map.JSON["defaultUnitType"] == nil { return nil }
        if map.JSON["unitTypes"]       == nil { return nil }
        
        mapping(map: map)
    }
    
    func mapping(map: Map) {
        self.id                  <- map["id"]
        self.isNew               <- map["isNew"]
        self.isStock             <- map["isStock"]
        self.isSeason            <- map["isSeason"]
        self.isSale              <- map["isSale"]
        self.defaultUnitType     <- map["defaultUnitType"]
        self.unitTypes           <- map["unitTypes"]
        self.name                <- map["product.name"]
        self.category            <- map["product.category"]
        self.image               <- map["product.image"]
        self.imageBig            <- map["product.imageBig"]
        self.description         <- map["product.description"]
        self.toppings            <- map["shopToppings"]
        self.toppingsDescription <- map["product.toppingsDescription"]
        self._type               <- map["product.productType"]
        self.productOptions      <- map["shopProductOptions"]
        self.optionsDescription  <- map["product.optionsDescription"]
        self.maxToppings         <- map["product.maxToppings"]
        self.levels              <- map["product.levels"]
        self.subcategoryCodename       <- map["product.subCategory"]
    }
    
}

class UnitType: Mappable, Codable {
    
    private var _multiplier: Double!
    private var _price: Double!
    var multiplier: Double!
    var price: Double!
    var type: String!
    
    required init?(map: Map) {
        if map.JSON["type"]       == nil { return nil }
        if map.JSON["multiplier"] == nil { return nil }
        if map.JSON["price"]      == nil { return nil }
        
        mapping(map: map)
    }
    
    func mapping(map: Map) {
        self.type       <- map["type"]
        self._price      <- map["price"]
        self._multiplier <- map["multiplier"]
        self.price = self._price.rounded2fD
        self.multiplier = self._multiplier.rounded2fD
    }
    
    
}

class Topping: Mappable, Codable, Equatable {
    
    var id:    Int!
    var name:  String = ""
    var price: Double = 0.0
    var codename: String? = nil
    
    static func == (lhs: Topping, rhs: Topping) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    required init?(map: Map) {
        if map.JSON["id"] == nil { return nil }
    }
    
    func mapping(map: Map) {
        self.id       <- map["id"]
        self.name     <- map["topping.name"]
        self.price    <- map["price"]
        self.codename <- map["topping.codename"]
    }
    
}
