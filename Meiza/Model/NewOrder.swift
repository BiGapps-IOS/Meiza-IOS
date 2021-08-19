//
//  Order.swift
//  Haled
//
//  Created by Denis Windover on 14/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation



struct NewOrder {
    
    var orderType:                   String
    var deliveryTime:                Week.Time?
    var paymentType:                 String?
    var referenceNum:                Int?
    var branch:                      Branch?
    var payments = 1
    
    
    init(orderType: String, deliveryTime: Week.Time?, branch: Branch?) {
        self.orderType = orderType
        self.deliveryTime = deliveryTime
        self.branch = branch
    }
    
    var products: [String: Any] {
        var index = 0
        let _productsArray = AppData.shared.cartProducts.value.compactMap { cartProduct -> [String: Any]? in
            if cartProduct.isChosen && cartProduct.amount > 0 && cartProduct.product != nil {
                index += 1
                if cartProduct.toppings.count == 0 && cartProduct.pizzaToppings.count == 0 && cartProduct.levels.count == 0 {
                    return ["products[\(index)][shopProductId]": cartProduct.productID,
                    "products[\(index)][unitType]": cartProduct.unitType,
                    "products[\(index)][amount]": cartProduct.amount,
                    "products[\(index)][comment]": cartProduct.comment ?? ""]
                }else{
                    var toppings: [String: Any] = [:]
                    
                    if cartProduct.product?.type == .pizza {
                        
                        for i in 0..<cartProduct.pizzaToppings.count {
                            let p = ["products[\(index)][shopProductId]": cartProduct.productID,
                            "products[\(index)][unitType]": cartProduct.unitType,
                            "products[\(index)][amount]": 1,
                            "products[\(index)][comment]": cartProduct.comment ?? "",
                            "products[\(index)][shopProductOptionId]": (cartProduct.productOptions.index(i)?.id ?? 0) > 0 ? cartProduct.productOptions.index(i)!.id! : "",
                            "products[\(index)][shopToppingIds]": cartProduct.pizzaToppings.index(i)?.map({ $0.id }) ?? "",
                            "products[\(index)][shopToppingPositions]": cartProduct.pizzaToppings.index(i)?.map({ pizzaTopping -> String in
                                var str = "0000"
                                pizzaTopping.pieces.forEach { pieceNum in
                                    str = str.replace("1", at: pieceNum - 1)
                                }
                                return str
                            }) ?? ""] as [String : Any]
                            toppings = toppings.merging(p, uniquingKeysWith: { (first, _) in first })
                            index += 1
                        }
                        
                    }else if cartProduct.product?.type == .pack {
                        
                        toppings = ["products[\(index)][shopProductId]": cartProduct.productID,
                        "products[\(index)][unitType]": cartProduct.unitType,
                        "products[\(index)][amount]": cartProduct.amount,
                        "products[\(index)][comment]": cartProduct.comment ?? "",
                        "products[\(index)][isPack]": 1] as [String : Any]
                        
                        let packIndex = index
                        var _toppings: [String: Any] = [:]
                        for i in 0..<cartProduct.levels.count {
                            var _topsLevel: [String: Any] = [:]
                            let level = cartProduct.levels[i]
                            let products = level.products
                            
                            for levelProduct in level.selectedProducts {
                                
                                index += 1
                                let product = products.first(where: { $0.id == levelProduct.productID })
                                
                                if levelProduct.toppings.count == 0 && levelProduct.pizzaToppings.count == 0 && levelProduct.levels.count == 0 {
                                    _topsLevel = ["products[\(index)][shopProductId]": levelProduct.productID,
                                    "products[\(index)][unitType]": levelProduct.unitType,
                                    "products[\(index)][amount]": levelProduct.amount,
                                    "products[\(index)][comment]": levelProduct.comment ?? "",
                                    "products[\(index)][levelId]": level.id ?? 0,
                                    "products[\(index)][relatedToPack]": packIndex] as [String : Any]
                                }else{
                                    if product?.type == .pizza {
                                        
                                        var _topsLevelProduct: [String: Any] = [:]
                                        
                                        let freeToppingsPieces = level.toppingsFree * 4
                                        var alreadyCalculated = 0
                                        
                                        func isNotFree(_ pieces: [Int]) -> Bool {
                                            if level.toppingsAddPaid == false {
                                                return false
                                            }
                                            if alreadyCalculated + pieces.count <= freeToppingsPieces {
                                                alreadyCalculated += pieces.count
                                                return false
                                            }else{
                                                return true
                                            }
                                            
                                        }
                                        
                                        _topsLevel = [
                                            "products[\(index)][shopProductId]": levelProduct.productID,
                                            "products[\(index)][unitType]": levelProduct.unitType,
                                            "products[\(index)][amount]": 1,
                                            "products[\(index)][comment]": levelProduct.comment ?? "",
                                            "products[\(index)][shopProductOptionIsPaid]": level.optionsPaid,
                                            "products[\(index)][shopProductOptionId]": (levelProduct.productOptions.index(0)?.id ?? 0) > 0 ? levelProduct.productOptions.index(0)!.id! : "",
                                            "products[\(index)][levelId]": level.id ?? 0,
                                            "products[\(index)][relatedToPack]": packIndex,
                                            "products[\(index)][shopToppingPositions]": [String]()] as [String : Any]
                                        

                                        for pizzaTopping in levelProduct.pizzaToppings[0] {
                                            
                                            if level.toppingsFree == 0 && isNotFree(pizzaTopping.pieces) {
                                                _topsLevel["products[\(index)][shopToppingPositions]"] = (_topsLevel["products[\(index)][shopToppingPositions]"] as? [String] ?? []) + [pizzaTopping.allPieces]
                                                _topsLevel["products[\(index)][shopToppingIsPaid]"] = (_topsLevel["products[\(index)][shopToppingIsPaid]"] as? [Bool] ?? []) + [true]
                                                _topsLevel["products[\(index)][shopToppingIds]"] = (_topsLevel["products[\(index)][shopToppingIds]"] as? [Int] ?? []) + [pizzaTopping.id]
                                            }else if isNotFree(pizzaTopping.pieces)  {
                                                
                                                let toppingPiecesCount = (levelProduct.pizzaToppings.index(0)?.flatMap({ $0.pieces }) ?? []).count
                                                var piecesForPaid = toppingPiecesCount - alreadyCalculated
                                                
                                                if freeToppingsPieces - alreadyCalculated > 0 {
                                                    if pizzaTopping.piecesToString(freeToppingsPieces - alreadyCalculated) != "0000" {
                                                        
                                                        /////////////////////////////////////////////////
                                                        
                                                        _topsLevel["products[\(index)][shopToppingPositions]"] = (_topsLevel["products[\(index)][shopToppingPositions]"] as? [String] ?? []) + [pizzaTopping.piecesToString(freeToppingsPieces - alreadyCalculated)]
                                                        _topsLevel["products[\(index)][shopToppingIsPaid]"] = (_topsLevel["products[\(index)][shopToppingIsPaid]"] as? [Bool] ?? []) + [false]
                                                        _topsLevel["products[\(index)][shopToppingIds]"] = (_topsLevel["products[\(index)][shopToppingIds]"] as? [Int] ?? []) + [pizzaTopping.id]
                                                        
                                                        let piecesForPaidSameTopping = pizzaTopping.pieces.count - (freeToppingsPieces - alreadyCalculated)
                                                        if piecesForPaidSameTopping > 0 {
                                                            if pizzaTopping.piecesToString(piecesForPaidSameTopping, isFree: false) != "0000" {
                                                                
                                                                _topsLevel["products[\(index)][shopToppingPositions]"] = (_topsLevel["products[\(index)][shopToppingPositions]"] as? [String] ?? []) + [pizzaTopping.piecesToString(piecesForPaidSameTopping, isFree: false)]
                                                                _topsLevel["products[\(index)][shopToppingIsPaid]"] = (_topsLevel["products[\(index)][shopToppingIsPaid]"] as? [Bool] ?? []) + [true]
                                                                _topsLevel["products[\(index)][shopToppingIds]"] = (_topsLevel["products[\(index)][shopToppingIds]"] as? [Int] ?? []) + [pizzaTopping.id]
                                                                
                                                                alreadyCalculated += pizzaTopping.pieces.count
                                                                piecesForPaid = toppingPiecesCount - alreadyCalculated
                                                            }
                                                        }
                                                    }
                                                }else{
                                                    if pizzaTopping.allPieces != "0000" {
                                                        _topsLevel["products[\(index)][shopToppingPositions]"] = (_topsLevel["products[\(index)][shopToppingPositions]"] as? [String] ?? []) + [pizzaTopping.allPieces]
                                                        _topsLevel["products[\(index)][shopToppingIsPaid]"] = (_topsLevel["products[\(index)][shopToppingIsPaid]"] as? [Bool] ?? []) + [true]
                                                        _topsLevel["products[\(index)][shopToppingIds]"] = (_topsLevel["products[\(index)][shopToppingIds]"] as? [Int] ?? []) + [pizzaTopping.id]
                                                        
                                                        alreadyCalculated += piecesForPaid
                                                        piecesForPaid = toppingPiecesCount - alreadyCalculated
                                                    }
                                                }
                                                
                                            }else{
                                                _topsLevel["products[\(index)][shopToppingPositions]"] = (_topsLevel["products[\(index)][shopToppingPositions]"] as? [String] ?? []) + [pizzaTopping.allPieces]
                                                _topsLevel["products[\(index)][shopToppingIsPaid]"] = (_topsLevel["products[\(index)][shopToppingIsPaid]"] as? [Bool] ?? []) + [false]
                                                _topsLevel["products[\(index)][shopToppingIds]"] = (_topsLevel["products[\(index)][shopToppingIds]"] as? [Int] ?? []) + [pizzaTopping.id]
                                                
                                            }
                                            
                                        }
                                        
                                        _topsLevel = _topsLevel.merging(_topsLevelProduct, uniquingKeysWith: { (first, _) in first })
                                        
                                    }else{
                                        
                                        var shopToppingIsPaid: [Bool] = []
                                        for i in 0..<(levelProduct.toppings.flatMap({ $0 })).count {
                                            shopToppingIsPaid.append(i+1 > level.toppingsFree)
                                        }
                                        
                                        _topsLevel = [
                                            "products[\(index)][shopProductId]": levelProduct.productID,
                                            "products[\(index)][unitType]": levelProduct.unitType,
                                            "products[\(index)][amount]": 1,
                                            "products[\(index)][comment]": levelProduct.comment ?? "",
                                            "products[\(index)][shopToppingIsPaid]": shopToppingIsPaid,
                                            "products[\(index)][shopToppingIds]": levelProduct.toppings.map({ $0.map({ $0.id ?? 0 }) }).flatMap({ $0 }),
                                            "products[\(index)][shopProductOptionIsPaid]": level.optionsPaid,
                                            "products[\(index)][shopProductOptionId]": (levelProduct.productOptions.index(0)?.id ?? 0) > 0 ? levelProduct.productOptions.index(0)!.id! : "",
                                            "products[\(index)][levelId]": level.id ?? 0,
                                            "products[\(index)][relatedToPack]": packIndex,
                                            "products[\(index)][shopToppingPositions]": [String]()] as [String : Any]
                                        
                                        var _topsLevelProduct: [String: Any] = [:]
                                        
                                        _topsLevel = _topsLevel.merging(_topsLevelProduct, uniquingKeysWith: { (first, _) in first })
                                    }
                                }
                                
                                _toppings = _toppings.merging(_topsLevel, uniquingKeysWith: { (first, _) in first })
                                
                            }
                        }
                        
                        toppings = toppings.merging(_toppings, uniquingKeysWith: { (first, _) in first })
                        index += 1
                        
                    }else{
                        for i in 0..<cartProduct.toppings.count {
                            
                            if let _toppings = cartProduct.toppings.index(i) {
                                let p = ["products[\(index)][shopProductId]": cartProduct.productID,
                                "products[\(index)][unitType]": cartProduct.unitType,
                                "products[\(index)][amount]": 1,
                                "products[\(index)][comment]": cartProduct.comment ?? "",
                                "products[\(index)][shopToppingIds]": _toppings.map({ $0.id ?? 0 }),
                                "products[\(index)][shopProductOptionId]": (cartProduct.productOptions.index(i)?.id ?? 0) > 0 ? cartProduct.productOptions.index(i)!.id! : ""
                                ] as [String : Any]
                                toppings = toppings.merging(p, uniquingKeysWith: { (first, _) in first })
                                index += 1
                            }
                            
                        }
                    }
                    
                    index -= 1
                    return toppings
                }
                
            }
            return nil
            }.flatMap({ $0 }).reduce([String: Any]()) { (dict, tuple) in
                var nextDict = dict
                nextDict.updateValue(tuple.1, forKey: tuple.0)
                return nextDict
            }
        
        return _productsArray
    }
    
    
}
