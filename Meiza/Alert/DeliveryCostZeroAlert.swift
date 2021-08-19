//
//  DeliveryCostZeroAlert.swift
//  Meiza
//
//  Created by Denis Windover on 01/11/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift



class DeliveryCostZeroAlert: AlertVC {
    
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnContinue: UIButton!
    
    
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
