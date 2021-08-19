//
//  PizzaTopping.swift
//  Meiza
//
//  Created by Denis Windover on 11/11/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import UIKit
import ObjectMapper

struct PizzaTopping: Codable, Equatable {
    
    var topping: Topping
    var pieces: [Int] = []
    
    var id: Int {
        return topping.id
    }
    
    var price: Double {
        let quarterPrice: Double = topping.price / 4
        let price = Double(pieces.count) * quarterPrice
        return price
    }
    
    var allPieces: String {
        var str = "0000"
        pieces.forEach { pieceNum in
            str = str.replace("1", at: pieceNum - 1)
        }
        return str
    }
    
    func piecesToString(_ count: Int, isFree: Bool = true) -> String {
        
        var str = "0000"
        if isFree {
            pieces[0...count-1].forEach{ pieceNum in
                str = str.replace("1", at: pieceNum - 1)
            }
        }else{
            pieces[pieces.count - count...pieces.count-1].forEach{ pieceNum in
                str = str.replace("1", at: pieceNum - 1)
            }
        }
        return str
        
//        switch count{
//        case 1: return isFree ? "1000" : "0001"
//        case 2: return isFree ? "1100" : "0011"
//        case 3: return isFree ? "1110" : "0111"
//        case 4: return "1111"
//        default: return "0000"
//        }
        
    }
    
    func piecesToPay(_ count: Int) -> (freePieces: String, payPieces: String){
        var freePieces = "0000"
        if count < pieces.count {
            pieces[0...pieces.count-1-count].forEach { pieceNum in
                freePieces = freePieces.replace("1", at: pieceNum - 1)
            }
        }
        
        var payPieces = "0000"
        pieces[pieces.count-count...pieces.count-1].forEach { pieceNum in
            payPieces = payPieces.replace("1", at: pieceNum - 1)
        }
        
        return (freePieces: freePieces, payPieces: payPieces)
        
    }
    
    
    var picture: UIImage? {
        return UIImage(named: topping.codename ?? "")
    }
    
    static func == (lhs: PizzaTopping, rhs: PizzaTopping) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ProductOption: Codable, Equatable, Mappable {
    
    var id: Int!
    var price: Double = 0
    var name: String = ""
    
    init?(map: Map) {
        
    }
    
    mutating func mapping(map: Map) {
        self.id    <- map["id"]
        self.price <- map["price"]
        self.name  <- map["productOption.name"]
    }
    
    static func productOptionNil() -> ProductOption {
        return ProductOption(id: -1000)
    }
    
    init(id: Int){
        self.id = id
    }
    
}
