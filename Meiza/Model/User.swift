//
//  User.swift
//  Meiza
//
//  Created by Denis Windover on 06/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import RxSwift

class User: Codable {
    
    private static var _currentUser:User?
    
    var shopCode: String = ""
    var shopID:   Int
    
    var id: Int? {
        didSet{ save() }
    }
    var jwt: String? {
        didSet{ save() }
    }
    var comment: String? {
        didSet{ save() }
    }
    var comment2: String? {
        didSet{ save() }
    }
    var fullName: String? {
        didSet{ save() }
    }
    var email: String? {
        didSet{ save() }
    }
    var phone: String? {
        didSet{ save() }
    }
    var city: String? {
        didSet { save() }
    }
    var street: String? {
        didSet { save() }
    }
    var streetNum: String? {
        didSet { save() }
    }
    var entranceCode: String? {
        didSet { save() }
    }
    var apartment: String? {
        didSet { save() }
    }
    var floor: String? {
        didSet { save() }
    }
    var isAgreePrivacy: Bool = false {
        didSet { save() }
    }
    var zcreditToken: String? {
        didSet { save() }
    }
    var creditCartLast4Digits: String? {
        didSet{ save() }
    }
    var passID: String? {
        didSet{ save() }
    }
    var yearExp: String? {
        didSet{ save() }
    }
    var monthExp: String? {
        didSet{ save() }
    }
    var lat: Double? {
        didSet { save() }
    }
    var lon: Double? {
        didSet { save() }
    }
    
    var expDate: String? {
        if let _year = yearExp, let _month = monthExp {
            return "\(_month)\(String(_year.suffix(2)))"
        }
        return nil
    }
    
    var isNeedRemoveTempLocation = false
    
    init(shopCode: String, shopID: Int){
        self.shopCode = shopCode
        self.shopID = shopID
    }
    
    static var currentUser: User? {
        get{
            if _currentUser == nil {
                if let data = UserDefaults.standard.value(forKey: "currentUser") as? Data{
                    if let user = try? PropertyListDecoder().decode(User.self, from: data){
                        _currentUser = user
                    }
                }
            }
            return _currentUser
        }
    }
    
    func save(){
        if let encoded = try? PropertyListEncoder().encode(self){
            UserDefaults.standard.set(encoded, forKey: "currentUser")
            RequestManager.shared.userDidSave.onNext(())
        }else{
            print("!!!ERROR SAVING CURRENT USER!!!")
        }
        
    }
    
    
    
    static func logout(){
        UserDefaults.standard.removeObject(forKey: "currentUser")
        _currentUser = nil
        CartProduct.deleteAllCartProducts()
        DispatchQueue.main.async {
            if UIApplication.shared.alternateIconName != nil {
                UIApplication.shared.setAlternateIconName(nil, completionHandler: nil)
            }
        }
    }
    
    static func initCurrentUser(shop: Shop){
        let user = User(shopCode: shop.code, shopID: shop.id)
        user.save()
        _currentUser = user
    }
    
    static func initCurrentUser(shopID: Int){
        let user = User(shopCode: "", shopID: shopID)
        user.save()
        _currentUser = user
    }
    
}
