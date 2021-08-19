//
//  RadiusErrorOrderAlert.swift
//  Meiza
//
//  Created by Denis Windover on 02/09/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RadiusErrorOrderAlert: AlertVC {
    
    
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var lblTitle: UILabel!{
        didSet{ lblTitle.textColor = AppData.shared.mainColor }
    }
    
    @IBOutlet weak var lblAddress: UILabel!{
        didSet{ lblAddress.text = AppData.shared.shop.address }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        btnClose.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: nil)
        }).disposed(by: disposeBag)
    }
    


}
