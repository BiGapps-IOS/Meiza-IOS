//
//  Shop.swift
//  Meiza
//
//  Created by Denis Windover on 05/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import ObjectMapper
import CoreLocation


class Shop: Mappable {
    
    var id:               Int
    var code:             String
    var name:             String?
    var image:            String?
    var description:      String?
    var about:            String?
    var address:          String?
    var phone:            String?
    var phone2:           String?
    var categories      = [Category]()
    var subcategories   = [Subcategory]()
    var paymentTypes    = ["credit"]
    var orderTypes      = [String]()
    var workingTimes    = [Week.Time]()
    var deliveryTimes   = [Week.Time]()
    var pickupTimes     = [Week.Time]()
    var paymentEndpoint:  String?
    var paymentKey:       String?
    private var _mainColor: String?
    var bgName:           String = ""
    var deliveryRadius:   Double = 0.0
    var _deliveryCost:    Double = 0.0
    var minimalOrder:     Double = 0.0
    var location:         CLLocation?
    var withSound:        Bool = false
    var layout:           Int = 1
    var withCoupons:      Bool = true
    var withoutFutureDelivery: Bool = false
    var withoutFuturePickup: Bool = false
    var deliveryZones   = [DeliveryZone]()
    var directPayment:    Bool = false
    var branches        = [Branch]()
    var maxPayments:      Int = 1
    var isAreaDelivery:   Bool = false
    var shopLat:          Double?
    var shopLon:          Double?
    
    var isDistanceOk: Bool {
        
        var delivRadius = self.deliveryRadius
        
        if deliveryZones.count > 0 {
            delivRadius = deliveryZones.sorted(by: { $0.to < $1.to }).last?.to ?? 0
        }
        
        guard let location = location, let userLat = User.currentUser?.lat, let userLon = User.currentUser?.lon else{ return false }
        let userLocation = CLLocation(latitude: userLat, longitude: userLon)
        return location.distance(from: userLocation) < CLLocationDistance(delivRadius * 1000)
    }
    
    var distanceFromMe: Double {
        guard let location = location, let userLat = User.currentUser?.lat, let userLon = User.currentUser?.lon else{ return 0 }
        let userLocation = CLLocation(latitude: userLat, longitude: userLon)
        return location.distance(from: userLocation)
    }
    
    var mainColor: UIColor? {
        return _mainColor?.hexStringToUIColor
    }
    
    var workingDaysStr: String {
        var str = ""
        workingTimes.forEach({ str += "\($0.hebrewDay)\n" })
        return str
    }
    
    var workingHoursStr: String {
        var str = ""
        workingTimes.forEach({ str += "\($0._from_to)\n" })
        return str
    }
    
    var maxPaymentsArr: [String] {
        var arr = [String]()
        for i in 1...maxPayments {
            arr.append(i.toString)
        }
        return arr
    }
    
    func getCodenameByCategoryId(_ id: Int?) -> String? {
        return categories.first(where: { $0.id == id })?.codename
    }
    
    required init?(map: Map) {
        guard let id: Int      = map["id"].value() else{ return nil }
        guard let code: String = map["code"].value() else{ return nil }
        
        self.id   = id
        self.code = code
        mapping(map: map)
    }
    
    func mapping(map: Map) {
        self.name                  <- map["name"]
        self.image                 <- map["image"]
        self.description           <- map["description"]
        self.about                 <- map["about"]
        self.address               <- map["address"]
        self.phone                 <- map["phone"]
        self.phone2                <- map["phone2"]
        self.categories            <- map["categories"]
        self.paymentTypes          <- map["paymentTypes"]
        self.orderTypes            <- map["orderTypes"]
        self.workingTimes          <- map["workingTimes"]
        self.deliveryTimes         <- map["deliveryTimes"]
        self.pickupTimes           <- map["pickupTimes"]
        self.paymentEndpoint       <- map["paymentEndpoint"]
        self.paymentKey            <- map["paymentKey"]
        self._mainColor            <- map["mainColor"]
        self.bgName                <- map["backgroundCodename"]
        self.deliveryRadius        <- map["deliveryRadius"]
        self._deliveryCost         <- map["deliveryCost"]
        self.minimalOrder          <- map["minimalOrder"]
        self.withSound             <- map["withSound"]
        self.layout                <- map["layout"]
        self.withCoupons           <- map["withCoupons"]
        self.withoutFutureDelivery <- map["withoutFuture_delivery"]
        self.withoutFuturePickup   <- map["withoutFuture_pickup"]
        self.deliveryZones         <- map["deliveryZones"]
        self.directPayment         <- map["directPayment"]
        self.branches              <- map["branches"]
        self.subcategories         <- map["subcategories"]
        self.maxPayments           <- map["maxPayments"]
        self.isAreaDelivery        <- map["isAreaDelivery"]
        self.shopLat               <- map["shopLat"]
        self.shopLon               <- map["shopLon"]
        
        if shopLat != nil && shopLon != nil {
            self.location = CLLocation(latitude: self.shopLat!, longitude: self.shopLon!)
        }
        else{
            let geo = CLGeocoder()
            geo.geocodeAddressString(address ?? "") { placemarks, error in
                self.location = placemarks?[0].location
            }
        }
    }
    
}

// func demoSucategories() -> [Subcategory] {
//    let sub1 = Subcategory()
//    sub1.id = 1
//    sub1.parentId = "category_1"
//    sub1.name = "אאאאאא"
//
//    let sub2 = Subcategory()
//    sub2.id = 2
//    sub2.parentId = "category_1"
//    sub2.name = "בבבבבב"
//
//    let sub3 = Subcategory()
//    sub3.id = 3
//    sub3.parentId = "category_1"
//    sub3.name = "גגגגגג"
//
//    return [sub1,sub2,sub3]
//}

class ShopBasic: Mappable {
    
    var id: Int!
    var name: String = ""
    var image: String?
    var tags: [Int] = []
    var address: String = ""
    var location: CLLocation?
    var deliveryTimeMinutesFrom: Int?
    var deliveryTimeMinutesTo:   Int?
    var isMakingDelivery:        Bool! = false
    var shopLat:                 Double?
    var shopLon:                 Double?
    
    required init?(map: Map) {
        guard let _: Int = map["id"].value() else{ return nil }
        mapping(map: map)
    }
    
    var deliveryTime: String? {
        guard let from = deliveryTimeMinutesFrom,
              let to = deliveryTimeMinutesTo else{ return nil }
        return "\(from)-\(to) " + "דק׳".localized
    }
    
    func mapping(map: Map) {
        id                      <- map["id"]
        name                    <- map["name"]
        image                   <- map["image"]
        tags                    <- map["shopTags"]
        address                 <- map["address"]
        deliveryTimeMinutesFrom <- map["deliveryTimeMinutesFrom"]
        deliveryTimeMinutesTo   <- map["deliveryTimeMinutesTo"]
        isMakingDelivery        <- map["isMakingDelivery"]
        self.shopLat            <- map["shopLat"]
        self.shopLon            <- map["shopLon"]
    }
    
}

class Tag: Branch {}

class Branch: Mappable {
    
    var id: Int
    var name: String
    
    
    required init?(map: Map) {
        guard let id: Int = map["id"].value() else{ return nil }
        guard let name: String = map["name"].value() else{ return nil }
        
        self.id = id
        self.name = name
    }
    
    func mapping(map: Map) {
        
    }
    
    
}

class DeliveryZone: Mappable {
    
    var deliveryCost: Double
    var from: Double
    var to: Double
    
    required init?(map: Map) {
        guard let deliveryCost: Double = map["deliveryCost"].value() else{ return nil }
        guard let from: Double         = map["from"].value() else{ return nil }
        guard let to: Double           = map["to"].value() else{ return nil }
        
        self.deliveryCost = deliveryCost
        self.from         = from
        self.to           = to
    }
    
    func mapping(map: Map) {
        
    }
}

class Category: Mappable {
    
    var id: Int?
    var name: String?
    var codename: String?
    var icon: String?
    
    var subcategories: [Subcategory] {
        return AppData.shared.shop.subcategories.filter({ $0.parentId == id })
    }
    
    required init?(map: Map) {
        mapping(map: map)
    }
    
    func mapping(map: Map) {
        self.name     <- map["name"]
        self.codename <- map["codename"]
        self.icon     <- map["icon"]
        self.id       <- map["id"]
    }
    
}

class Subcategory: Mappable {
    
    var name: String?
    var codename: String?
    var id: Int?
    var parentId: Int?
    private var _icon: String?
    
    var icon: UIImage? {
        return UIImage(named: "logo_your_shop")
    }
    
    init(){}
    
    required init?(map: Map) {
        mapping(map: map)
    }
    
    func mapping(map: Map) {
        self.name     <- map["name"]
        self.codename <- map["codename"]
        self._icon    <- map["icon"]
        self.parentId <- map["parent_id"]
        self.id       <- map["id"]
    }
    
    
    
    
}

class Week: Mappable {
    
    var sunday    = [Time]()
    var monday    = [Time]()
    var tuesday   = [Time]()
    var wednesday = [Time]()
    var thursday  = [Time]()
    var friday    = [Time]()
    var saturday  = [Time]()
    
    required init?(map: Map) {
        mapping(map: map)
    }
    
    func mapping(map: Map) {
        self.sunday    <- map["sunday"]
        self.monday    <- map["monday"]
        self.tuesday   <- map["tuesday"]
        self.wednesday <- map["wednesday"]
        self.thursday  <- map["thursday"]
        self.friday    <- map["friday"]
        self.saturday  <- map["saturday"]
    }
    
    class Time: Mappable {
        
        var id:      Int = 0
        var weekday: String = ""
        var from:    String = ""
        var to:      String = ""
        var date:    Double = 0
        
        var from_to: String {
            return hebrewDay + " - " + from + " - " + to 
        }
        
        var _from_to: String {
            return from + " - " + to
        }
        
        var hebrewDay: String {
            switch weekday {
            case "sunday": return "יום ראשון".localized
            case "monday": return "יום שני".localized
            case "tuesday": return "יום שלישי".localized
            case "wednesday": return "יום רביעי".localized
            case "thursday": return "יום חמישי".localized
            case "friday": return "יום שישי".localized
            case "saturday": return "יום שבת".localized
            default: return ""
            }
        }
        
        required init?(map: Map) {
            mapping(map: map)
        }
        
        func mapping(map: Map) {
            self.id       <- map["id"]
            self.weekday  <- map["weekday"]
            self.from     <- map["from"]
            self.to       <- map["to"]
            self.date     <- map["date"]
        }
    }
    
    
}

extension String {
    
    fileprivate var hexStringToUIColor: UIColor {
        var cString:String = self.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
}
