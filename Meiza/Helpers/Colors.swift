//
//  Colors.swift
//  Meiza
//
//  Created by Denis Windover on 05/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    open class var myBlue: UIColor {
        get{ UIColor(named: "BLUE") ?? .blue }
    }
    
    open class var myBlackOp50: UIColor {
        get{ UIColor(named: "BLACK_OP50") ?? .black }
    }
    
    open class var myDarkBlue: UIColor {
        get{ UIColor(named: "DARK_BLUE") ?? .blue }
    }
    
    open class var myLightGray: UIColor {
        get{ UIColor(named: "LIGHT_GRAY") ?? .lightGray }
    }
    
}


