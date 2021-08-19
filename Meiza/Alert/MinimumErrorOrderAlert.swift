//
//  MinimumErrorOrderAlert.swift
//  Meiza
//
//  Created by Denis Windover on 02/09/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit

class MinimumErrorOrderAlert: AlertVC {
    
    @IBOutlet var views: [UILabel]!{
        didSet{ views.forEach({ $0.textColor = AppData.shared.mainColor }) }
    }
    @IBOutlet weak var lblMinOrder: UILabel!{
        didSet{ lblMinOrder.text = "\("מינימום הזמנה".localized): ₪\(String(format: "%.2f", Double(AppData.shared.shop.minimalOrder)))" }
    }

    @IBAction func btnCloseTapped(_ sender: Any) {
        self.dismiss(completion: nil)
    }
    
}
