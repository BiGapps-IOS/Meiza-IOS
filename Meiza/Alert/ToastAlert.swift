//
//  ToastAlert.swift
//  Meiza
//
//  Created by Denis Windover on 05/01/2021.
//  Copyright © 2021 BigApps. All rights reserved.
//

import UIKit

class ToastAlert: AlertVC {
    
    
    @IBOutlet weak var lblMessage: UILabel!{
        didSet{
            lblMessage.text = message
        }
    }
    @IBOutlet weak var btnClose: UIButton!
    
    var message: String = ""
    var interval: Double = 1
    var isLastProduct = false
//    var alertDidClose: ()->() = {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        btnClose.rx.tap.subscribe(onNext: { [weak self] _ in
//            self?.dismiss(completion: {
//                Coordinator.shared.popMain()
//            })
//        }).disposed(by: disposeBag)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.dismiss(completion: { [weak self] in
                if self?.isLastProduct == true {
                    Coordinator.shared.popMain()
                }
            })
        }
        
        
        
    }


}
