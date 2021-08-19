//
//  ProductSection.swift
//  Meiza
//
//  Created by Denis Windover on 12/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import RxDataSources

struct ProductSection {
    var header: String
    var items:  [CartProduct]
}

extension ProductSection: SectionModelType {
    typealias Item = CartProduct
    init(original: ProductSection, items: [CartProduct]) {
        self = original
        self.items = items
    }
}

struct OrderProductSection {
    var header: String
    var items:  [OrderProduct]
}

extension OrderProductSection: SectionModelType {
    typealias Item = OrderProduct
    init(original: OrderProductSection, items: [OrderProduct]) {
        self = original
        self.items = items
    }
}
