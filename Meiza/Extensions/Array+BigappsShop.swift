//
//  Array+Meiza.swift
//  Meiza
//
//  Created by Denis Windover on 17/11/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation


extension Array {
    
    func index(_ index: Int) -> Element? {
        if let element = self[safe: index] {
            return element
        }
        return nil
    }
    
}
