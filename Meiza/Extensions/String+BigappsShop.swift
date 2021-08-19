//
//  String+Meiza.swift
//  Meiza
//
//  Created by Denis Windover on 16/11/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

extension String {

    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }

    func heightOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.height
    }

    func sizeOfString(usingFont font: UIFont) -> CGSize {
        let fontAttributes = [NSAttributedString.Key.font: font]
        return self.size(withAttributes: fontAttributes)
    }
}

extension String {
    
    func isFullNameValid() -> Bool {
        
        //let fullNameFormat = "[א-תa-zA-Z]{2,15}+[ ][א-תa-zA-Z]{2,15}"
        let fullNameFormat = "([א-תa-zA-Zء-ي]{2,}[ ]){1,3}+[א-תa-zA-Zء-ي]{2,}"
        let fullNamePredicate = NSPredicate(format:"SELF MATCHES %@", fullNameFormat)
        return fullNamePredicate.evaluate(with: self)
        
    }
    
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
    
        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.width)
    }
}

extension String {
    func replace(_ with: String, at index: Int) -> String {
        var modifiedString = String()
        for (i, char) in self.enumerated() {
            modifiedString += String((i == index) ? with : String(char))
        }
        return modifiedString
    }
    
    func size(for fontSize: CGFloat) -> CGFloat {
        
        if let font = UIFont(name: "Heebo-Regular", size: fontSize) {
            let fontAttributes = [NSAttributedString.Key.font: font]
            return (self as NSString).size(withAttributes: fontAttributes).width
        }
        return 0
    }
}


extension String {
    
    var localized: String {
        if currentLanguage == "en" { return self }
        
        guard let word = AppData.shared.localized[self] as? [String: Any],
              let localized = word[currentLanguage] as? String else { return self }
        
        return localized
        
    }

}
