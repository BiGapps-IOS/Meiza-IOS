//
//  Utils.swift
//  Meiza
//
//  Created by Denis Windover on 06/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import UserNotifications
import ObjectMapper

func attrUnderline(_ text: String, fontSize: CGFloat = 10) -> NSMutableAttributedString {
        
    let attr = NSMutableAttributedString()
    attr
        .underlined(text, fontSize: fontSize, color: AppData.shared.mainColor)

    return attr
    
}

func isPushNotificationStatusNotDetermined(completion: @escaping(Bool)->()){
    
    let current = UNUserNotificationCenter.current()

    current.getNotificationSettings(completionHandler: { (settings) in
        completion(settings.authorizationStatus == .notDetermined)
    })
    
}

func getDemoProducts() -> (category: Category, products: [Product])? {
    
    guard let path = Bundle.main.path(forResource: "DemoProducts", ofType: "json"),
          let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
          let json = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves),
          let jsonResult = json as? Dictionary<String, AnyObject>,
          let categoryDic = jsonResult["category"] as? [String: Any],
          let productsDic = jsonResult["products"] as? [[String: Any]],
          let category = Mapper<Category>().map(JSON: categoryDic) else{ return nil }
        
    let products = Mapper<Product>().mapArray(JSONArray: productsDic)
    
    if products.count > 0 {
        return (category: category, products: products)
    }
    
    
    return nil
}
