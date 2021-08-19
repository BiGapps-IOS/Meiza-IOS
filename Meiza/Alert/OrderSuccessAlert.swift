//
//  OrderSuccessAlert.swift
//  Meiza
//
//  Created by Denis Windover on 18/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit

class OrderSuccessAlert: AlertVC {
    
    @IBOutlet weak var lblTitle: UILabel!{
        didSet{
            lblTitle.text = "יש!\nקיבלנו את ההזמנה שלך".localized
        }
    }
    @IBOutlet weak var lblSubtitle: UILabel!{
        didSet{
            if paymentType == "cash" {
                lblSubtitle.text = "נציג יצור איתך קשר בהקדם על מנת לאשר את הזמנתך".localized
            }
            if AppData.shared.shop.directPayment {
                lblSubtitle.isHidden = true
            }
        }
    }
    @IBOutlet weak var btnGoMain: UIButton!{
        didSet{ btnGoMain.setTitleColor(AppData.shared.mainColor, for: .normal) }
    }
    
    
    var paymentType = "credit"
    var orderID: Int!

    @IBAction func btnGoMainTapped(_ sender: UIButton) {
        dismiss { [weak self] in
            Coordinator.shared.popMain(orderID: self?.orderID)
        }
    }
    
    @IBAction func btnCloseTapped(_ sender: UIButton) {
        dismiss {
            Coordinator.shared.popMain(orderID: nil)
        }
    }
}
