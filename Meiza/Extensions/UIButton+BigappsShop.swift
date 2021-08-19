//
//  UIButton+BigappsShop.swift
//  Meiza
//
//  Created by Denis Windover on 20/12/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    
    @IBInspectable public var numOfLines: Int{
        set {
            self.titleLabel?.numberOfLines = newValue
            self.titleLabel?.textAlignment = .center
            self.titleLabel?.adjustsFontSizeToFitWidth = true
        }
        get {
            self.titleLabel?.numberOfLines ?? 0
        }
    }
    
    
    public func setImageColor(color: UIColor) {
        let templateImage = self.imageView?.image?.withRenderingMode(.alwaysTemplate)
        self.setImage(templateImage, for: .normal)
        self.imageView?.tintColor = color
    }
    
}
