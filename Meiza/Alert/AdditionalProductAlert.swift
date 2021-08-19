//
//  AdditionalProductAlert.swift
//  Meiza
//
//  Created by Denis Windover on 28/08/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class AdditionalProductAlert: AlertVC {
    
    
    @IBOutlet weak var btnYes: UIButton!{
        didSet{
            btnYes.setTitleColor(AppData.shared.mainColor, for: .normal)
            btnYes.borderColor = AppData.shared.mainColor
        }
    }
    @IBOutlet weak var btnNo: UIButton!{
        didSet{ btnNo.setTitleColor(AppData.shared.mainColor, for: .normal) }
    }
    
    @IBOutlet weak var lblTitle: UILabel!{
        didSet{ if isPizza{ lblTitle.text = "האם תרצה להזמין פיצה נוספת?".localized } }
    }
    
    var actionAdd: (Bool)->() = { _ in }
    var isPizza = false

    override func viewDidLoad() {
        super.viewDidLoad()

        btnNo.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: {
                self?.actionAdd(false)
            })
        }).disposed(by: disposeBag)
        
        btnYes.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: {
                self?.actionAdd(true)
            })
        }).disposed(by: disposeBag)
        
    }
    


}
