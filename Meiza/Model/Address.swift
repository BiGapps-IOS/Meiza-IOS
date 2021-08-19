//
//  Address.swift
//  Meiza
//
//  Created by Denis Windover on 08/11/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//


import Foundation
import ObjectMapper
import CoreLocation


class Address: Mappable, CustomStringConvertible {
    
    var address:       String
    var mainText:      String = ""
    var secondaryText: String = ""
    var placeID:       String?
    var lat:           Double?
    var lon:           Double?
    var types:         [String] = []
    
    init(_ address: String, location: CLLocation){
        self.address = address
        self.lat = location.coordinate.latitude
        self.lon = location.coordinate.longitude
    }
    
    required init?(map: Map) {
        guard
            let address: String = map["description"].value(),
            let placeID: String = map["place_id"].value()
            else{ return nil }
        
        self.address = address.replacingOccurrences(of: ", ישראל", with: "")
        self.placeID = placeID
        self.types = map["types"].value() ?? []
        self.mainText <- map["structured_formatting.main_text"]
        self.secondaryText <- map["structured_formatting.secondary_text"]
    }
    
    func mapping(map: Map) {
        
    }
    
    init?(addressComponents: [[String:Any]]?, coordinates: CLLocation){
        
        guard let addressComponents = addressComponents else{ return nil }
        
        var streetNumber = ""
        var route: String?
        var city: String?
        
        addressComponents.forEach { component in
            if let types = component["types"] as? [String], let longName = component["long_name"] as? String {
                if types.contains("street_number"){
                    streetNumber = longName
                }else if types.contains("route") || types.contains("establishment") || types.contains("point_of_interest") || types.contains("transit_station"){
                    route = longName
                }else if types.contains("locality"){
                    city = longName
                }
            }
        }
        
        self.address = ("\(route ?? "")" + " " + streetNumber).trimmingCharacters(in: .whitespacesAndNewlines) + ", " + "\(city ?? "")"
        self.mainText = ("\(route ?? "")" + " " + streetNumber).trimmingCharacters(in: .whitespacesAndNewlines)
        self.secondaryText = city ?? ""
        self.lat = coordinates.coordinate.latitude
        self.lon = coordinates.coordinate.longitude
        
    }
    
    var description: String {
        return "address: \(address)\nplaceID: \(placeID ?? "nil")\nlat: \(lat ?? 0)\nlon: \(lon ?? 0)\ntypes: \(types)"
    }
}
