//
//  CouponSuccessAlert.swift
//  Meiza
//
//  Created by Denis Windover on 06/10/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift

class CouponSuccessAlert: AlertVC {
    
    @IBOutlet weak var lblMessage: UILabel!{
        didSet{ lblMessage.text = "קופון על סך 1111 הנחה הוזן בהצלחה ויקוזז מההזמנה".localized.replacingOccurrences(of: "1111", with: "\(discount ?? 0)%") }
    }
    @IBOutlet weak var btnContinue: UIButton!
    
    var discount: Double!

    override func viewDidLoad() {
        super.viewDidLoad()

        btnContinue.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: {
                if AppData.shared.shop.branches.count == 0 {
                    Coordinator.shared.pushSummary(nil)
                }
            })
        }).disposed(by: disposeBag)
    }

}
