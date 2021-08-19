//
//  AppDelegate.swift
//  Meiza
//
//  Created by Denis Windover on 24/08/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import OneSignal
import DWExt
import GoogleMaps
import GooglePlaces

var currentLanguage: String {
    get{
        return UserDefaults.standard.object(forKey: "app_lang") as? String ?? "en"
    }
    set{
        UserDefaults.standard.setValue(newValue, forKey: "app_lang")
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        DispatchQueue.main.async {
            print("!!!!!!!!!!! \(currentLanguage)")
            UserDefaults.standard.set(currentLanguage, forKey: "AppleLanguage")
            UserDefaults.standard.setValue(currentLanguage, forKey: "app_lang")
            UserDefaults.standard.synchronize()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                Bundle.swizzleLocalization()
            }
            
        }
        
        let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false, kOSSettingsKeyInAppLaunchURL: false]
        
        OneSignal.initWithLaunchOptions(launchOptions, appId: ONE_SIGNAL_APP_ID, handleNotificationReceived: { notification in
            print(notification?.payload.rawPayload ?? [:])
        }, handleNotificationAction: { notification in
            print(notification?.notification.payload.rawPayload ?? [:])
        }, settings: onesignalInitSettings)
        
        OneSignal.inFocusDisplayType = .notification
        
        DTIToastCenter.defaultCenter.registerCenter()
        
        AppData.shared.start()
        ConnectionManager.shared.start()
        
        // Google init
        GMSServices.provideAPIKey(GOOGLE_API_KEY)
        GMSPlacesClient.provideAPIKey(GOOGLE_API_KEY)
        
        UIView.appearance().semanticContentAttribute = .forceLeftToRight
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quitEs the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        BG_DATE = Date().timeIntervalSince1970
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if CHECK_IF_NEED_TO_REFRESH {
            Coordinator.shared.pushSplash()
        }
        BG_DATE = nil
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    static func getMainDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

}

extension Bundle {
    static func swizzleLocalization() {
        DispatchQueue.main.async {
            let orginalSelector = #selector(localizedString(forKey:value:table:))
            guard let orginalMethod = class_getInstanceMethod(self, orginalSelector) else { return }
            
            let mySelector = #selector(myLocaLizedString(forKey:value:table:))
            guard let myMethod = class_getInstanceMethod(self, mySelector) else { return }
            
            if class_addMethod(self, orginalSelector, method_getImplementation(myMethod), method_getTypeEncoding(myMethod)) {
                DispatchQueue.main.async {
                    class_replaceMethod(self, mySelector, method_getImplementation(orginalMethod), method_getTypeEncoding(orginalMethod))
                }
            } else {
                DispatchQueue.main.async {
                    method_exchangeImplementations(orginalMethod, myMethod)
                }
                
            }
        }
    }

    @objc private func myLocaLizedString(forKey key: String,value: String?, table: String?) -> String {
//        print("key: \(key)\nvalue: \(value ?? "")\ntable: \(table ?? "")")
        
        guard let bundlePath = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
            let bundle = Bundle(path: bundlePath) else {
                return Bundle.main.myLocaLizedString(forKey: key, value: value, table: table)
        }
        return bundle.myLocaLizedString(forKey: key, value: value, table: table)
    }
    
}
