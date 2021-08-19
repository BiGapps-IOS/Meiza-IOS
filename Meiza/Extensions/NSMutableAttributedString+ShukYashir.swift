//
//  NSMutableAttributedString+Meiza.swift
//  Meiza
//
//  Created by Denis Windover on 05/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit

extension NSMutableAttributedString {
    
    public func setAsLink(textToFind:String, linkURL:String) -> Bool {
        
        let foundRange = self.mutableString.range(of: textToFind)
        if foundRange.location != NSNotFound {
            self.addAttribute(.link, value: linkURL, range: foundRange)
            return true
        }
        return false
    }
    
//    @discardableResult func bold(_ text: String, fontSize:CGFloat = 17, color:UIColor = .black, alignment:NSTextAlignment = .right) -> NSMutableAttributedString {
//        let style = NSMutableParagraphStyle()
//        style.alignment = alignment
//        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont(name: "VarelaRound-Bold", size: fontSize)!, .foregroundColor:color, .paragraphStyle:style]
//        let boldString = NSMutableAttributedString(string:text, attributes: attrs)
//        append(boldString)
//
//        return self
//    }
    
    @discardableResult func normal(_ text: String, isMedium: Bool = false, fontSize:CGFloat = 17, color:UIColor = .black, alignment:NSTextAlignment = .center, lineSpacing:CGFloat = 2) -> NSMutableAttributedString {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        //style.lineSpacing = lineSpacing
        let attrs: [NSAttributedString.Key: Any] = [.font: isMedium ? UIFont(name: "Heebo-Medium", size: fontSize)! : UIFont(name: "Heebo-Regular", size: fontSize)!, .foregroundColor:color, .paragraphStyle:style]
        let normal = NSMutableAttributedString(string:text, attributes: attrs)
        append(normal)
        
        return self
    }
    
    @discardableResult func strikethrough(_ text: String, isStrike: Bool = true, isMedium: Bool = false, fontSize:CGFloat = 17, color:UIColor = .black, alignment:NSTextAlignment = .center, lineSpacing:CGFloat = 2) -> NSMutableAttributedString {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        let attrs: [NSAttributedString.Key: Any] = [.font: isMedium ? UIFont(name: "Heebo-Medium", size: fontSize)! : UIFont(name: "Heebo-Regular", size: fontSize)!, .foregroundColor:color, .paragraphStyle:style]
        let attrStr = NSMutableAttributedString(string:text, attributes: attrs)
     
        if isStrike{
            attrStr.addAttribute(NSAttributedString.Key.baselineOffset, value: 0, range: NSMakeRange(0, attrStr.length))
            attrStr.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSNumber(value: NSUnderlineStyle.thick.rawValue), range: NSMakeRange(0, attrStr.length))
            attrStr.addAttribute(NSAttributedString.Key.strikethroughColor, value: color, range: NSMakeRange(0, attrStr.length))
        }
        
        append(attrStr)
        
        return self
    }
    
    @discardableResult func underlined(_ text: String, fontSize:CGFloat = 15, color:UIColor = .black, alignment:NSTextAlignment = .center) -> NSMutableAttributedString {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        //style.lineSpacing = lineSpacing
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont(name: "Heebo-Regular", size: fontSize)!, .foregroundColor:color, .paragraphStyle:style, .underlineStyle: NSUnderlineStyle.single.rawValue]
        let underlined = NSMutableAttributedString(string:text, attributes: attrs)
        append(underlined)
        
        return self
    }
}
