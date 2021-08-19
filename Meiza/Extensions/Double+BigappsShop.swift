//
//  Double+Meiza.swift
//  Meiza
//
//  Created by Denis Windover on 26/08/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation

extension Double{
    
    var rounded2fD: Double {
        return (self * 100).rounded(.toNearestOrEven) / 100
    }
    
    var toString: String{
        return "\(self)"
    }
    
    var clean: String{

        // "1,605,436" where Locale == en_US
//        print("raw value: \(self) ---------------------------------------------------")
//        print("en_US value: \(String(format: "%.0f", locale: Locale.init(identifier: "en_US"), self)) - - - - - - - - - - - - - -")
//        print("clean: \(String(format: "%.2f", self)) + + + + + + + + + + + + + + + +")
        
        return String(format: "%.2f", locale: Locale.init(identifier: "en_US"), self)
    }
    
    var clean2: String{
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
    
    var rounded2f: String{
        return String(format: "%.1f", self)
    }
    

}
