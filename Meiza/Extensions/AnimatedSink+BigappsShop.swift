//
//  AnimatedSink+Meiza.swift
//  Meiza
//
//  Created by Denis Windover on 24/08/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import RxAnimated
import RxSwift
import RxCocoa
import UIKit
import DWExt

extension Set {

    @discardableResult mutating func insert(_ newMembers: [Set.Element]) -> [(inserted: Bool, memberAfterInsert: Set.Element)] {
        var returnArray: [(inserted: Bool, memberAfterInsert: Set.Element)] = []
        newMembers.forEach { (member) in
            returnArray.append(self.insert(member))
        }
        return returnArray
    }
}

extension Reactive where Base: UIView {
    public var borderColor: Binder<UIColor?> {
        return Binder(self.base) { view, color  in
            view.borderColor = color
        }
    }
}

extension Reactive where Base: UITextField {
    public var textColor: Binder<UIColor?> {
        return Binder(self.base) { view, color  in
            view.textColor = color
        }
    }
}

extension Reactive where Base: UIImageView {
    public var imageColor: Binder<UIColor> {
        return Binder(self.base) { view, color  in
            view.imageColor = color
        }
    }
}

extension AnimatedSink where Base: UILabel {
    
    public var font: Binder<UIFont> {
        let animation = self.type!
        return Binder(self.base) { label, font in
            animation.animate(view: label) {
                guard let label = label as? UILabel else { return }
                label.font = font
            }
        }
    }
    
    public var textColor: Binder<UIColor> {
        let animation = self.type!
        return Binder(self.base) { label, color in
            animation.animate(view: label) {
                guard let label = label as? UILabel else { return }
                label.textColor = color
            }
        }
    }

}

extension AnimatedSink where Base: UIButton {
    
    public var backgroundColor: Binder<UIColor> {
        let animateion = self.type!
        return Binder(self.base) { button, color in
            animateion.animate(view: button) {
                guard let button = button as? UIButton else{ return }
                button.backgroundColor = color
            }
        }
    }
    
    public var titleColor: Binder<UIColor> {
        let animateion = self.type!
        return Binder(self.base) { button, color in
            animateion.animate(view: button) {
                guard let btn = button as? UIButton else{ return }
                btn.setTitleColor(color, for: .normal)
            }
        }
    }
    
}
