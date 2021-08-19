//
//  Constants.swift
//  Meiza
//
//  Created by Denis Windover on 05/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import UIKit
import DWExt


let WIDTH = UIScreen.main.bounds.width

let HEIGHT = UIScreen.main.bounds.height

let WINDOW = UIApplication.shared.keyWindow!

let SYSTEM_VERSION = UIDevice.current.systemVersion

var APP_VERSION:String {
    get{
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        //let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        return "v.\(version!)"
    }
}

let ONE_SIGNAL_APP_ID = "b311e2f3-04fe-4e50-a7c8-d827019a0f22"
let GOOGLE_API_KEY = "AIzaSyBrIwfWUqbKus21Odtc6tW3Lo_jv3a2fa8"

let APP_LINK = URL(string: "itms-apps://itunes.apple.com/app/apple-store/id\(APPLE_APP_ID)?mt=8")
let APPLE_APP_ID = ""

let NAV = UIApplication.shared.keyWindow!.rootViewController as! UINavigationController

func ERROR_TOAST(){
    SHOW_TOAST("SOMETHING WENT WRONG! TRY AGAIN!")
}

func SHOW_TOAST(_ text:String){
    DTIToastCenter.defaultCenter.makeText(text: text)
}

let DEFAULT_ZCREDIT_TERMINAL_NUM = "0882016016"
var ZCREDIT_TERMINAL_NUM: String {
    if let suplier = AppData.shared.shop.paymentEndpoint {
        return suplier
    }
    return DEFAULT_ZCREDIT_TERMINAL_NUM
}
let DEFAULT_ZCREDIT_PASS = "Z0882016016"
var ZCREDIT_PASS: String {
    if let pass = AppData.shared.shop.paymentKey {
        return pass
    }
    return DEFAULT_ZCREDIT_PASS
}

var SHOP_ID: Int? {
    set{
        AppData.shared.shopID = newValue
    }
    get{
        return AppData.shared.shopID
    }
}

var LAST_USED_SHOP_ID: Int? {
    set{
        UserDefaults.standard.set(newValue, forKey: "LAST_USED_SHOP_ID")
    }
    get{
        return UserDefaults.standard.value(forKey: "LAST_USED_SHOP_ID") as? Int
    }
}

var IS_NEED_REMIND_ORDER: Bool {
    set{
        UserDefaults.standard.set(false, forKey: "remindOrder")
    }
    get{
        if let remindOrder = UserDefaults.standard.value(forKey: "remindOrder") as? Bool {
            return remindOrder
        }
        return true
    }
    
}

var BG_DATE: Double?
var CHECK_IF_NEED_TO_REFRESH: Bool {
    guard let ts = BG_DATE else{ return false }
    if Date().timeIntervalSince1970 - ts >= 300 {
        return true
    }
    return false
}

var IS_PRODUCTION:Bool{
    #if DEBUG
        return false
    #else
        return true
    #endif
}
