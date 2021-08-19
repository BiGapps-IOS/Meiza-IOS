//
//  DeliveryCostAlert.swift
//  Meiza
//
//  Created by Denis Windover on 25/10/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift

class DeliveryCostAlert: AlertVC {
    
    
    @IBOutlet weak var btnContinue: UIButton!{
        didSet{
            btnContinue.setTitleColor(AppData.shared.mainColor, for: .normal)
            btnContinue.borderColor = AppData.shared.mainColor
        }
    }
    @IBOutlet weak var lblMessage: UILabel!{
        didSet{
            lblMessage.text = "₪ \(AppData.shared.deliveryCost.clean)"
        }
    }
    @IBOutlet weak var btnClose: UIButton!
    
    var actionContinue: ()->() = {}
    

    override func viewDidLoad() {
        super.viewDidLoad()

        btnClose.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: {})
        }).disposed(by: disposeBag)
        
        btnContinue.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: {
                self?.actionContinue()
            })
        }).disposed(by: disposeBag)
    }
    


}
