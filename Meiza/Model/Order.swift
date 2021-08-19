//
//  Order.swift
//  Meiza
//
//  Created by Denis Windover on 19/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import ObjectMapper


class Order: Mappable {
    
    var id:                    Int!
    private var _createdDate:  Double!
    private var _deliveryDate: Double!
    var deliveryFrom:          String = ""
    var deliveryTo:            String = ""
    var comment:               String?
    var orderType:             String = ""
    var paymentType:           String = ""
    var status:                String!
    var products:              [OrderProduct] = []
    var deliveryCost:          Double = 0
    var totalNew:              Double?
    var discount:              Double = 0
    var link:                  String?
    var totalPay:              Double = 0
    
    var price: Double {
        return totalPay != 0 ? totalPay : (totalNew ?? (products.compactMap({ $0.price }).reduce(0, +) + deliveryCost) * (1 - (discount / 100)))
    }
    
    var createdDate: Date {
        return Date(timeIntervalSince1970: _createdDate)
    }
    var deliveryDate: Date {
        return Date(timeIntervalSince1970: _deliveryDate)
    }
    var statusHebrew: String {
        switch status{
        case "new": return "חדשה".localized
        case "in_process": return "בהכנה".localized
        case "collected": return "מוכנה".localized
        case "paid": return "סופק".localized
        default: return ""
        }
    }
    
    var statusColor: UIColor {
        return status == "paid" ? AppData.shared.mainColor : .black
    }
    
    var deliveryDateStr: String {
        return "\(deliveryDate.formattedFullDateString)\n\(deliveryFrom)-\(deliveryTo)"
    }
    var orderTypeHebrew: String {
        return orderType == "delivery" ? "משלוח".localized : "איסוף עצמי".localized
    }
    
    
    required init?(map: Map) {
        if map.JSON["id"]           == nil { return nil }
        if map.JSON["createdDate"]  == nil { return nil }
        if map.JSON["deliveryDate"] == nil { return nil }
        if map.JSON["status"]       == nil { return nil }
        
        mapping(map: map)
    }
    
    func mapping(map: Map) {
        self.id            <- map["id"]
        self._createdDate  <- map["createdDate"]
        self._deliveryDate <- map["deliveryDate"]
        self.deliveryFrom  <- map["deliveryFrom"]
        self.deliveryTo    <- map["deliveryTo"]
        self.comment       <- map["comment"]
        self.orderType     <- map["orderType"]
        self.paymentType   <- map["paymentType"]
        self.status        <- map["status"]
        self.products      <- map["products"]
        self.deliveryCost  <- map["deliveryCost"]
        self.totalNew      <- map["totalNew"]
        self.discount      <- map["discount"]
        self.link          <- map["link"]
        self.totalPay      <- map["totalPay"]
    }
    
    
    
    
    
    
    
}
