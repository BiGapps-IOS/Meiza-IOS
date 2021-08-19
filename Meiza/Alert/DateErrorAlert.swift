//
//  DateErrorAlert.swift
//  Meiza
//
//  Created by Denis Windover on 17/09/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift

class DateErrorAlert: AlertVC {
    
    
    @IBOutlet weak var btnOk: UIButton!
    
    @IBOutlet weak var lblMessage: UILabel!{
        didSet{
            if (orderType == "delivery" && AppData.shared.shop.withoutFutureDelivery) || (orderType == "pickup" && AppData.shared.shop.withoutFuturePickup) {
                lblMessage.text = "לא ניתן להזמין לעכשיו".localized
            }
        }
    }
    
    
    var actionOK: ()->() = {}
    var orderType: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        btnOk.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: {
                self?.actionOK()
            })
        }).disposed(by: disposeBag)
    }

}
