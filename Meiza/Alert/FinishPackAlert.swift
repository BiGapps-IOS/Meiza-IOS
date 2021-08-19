//
//  FinishPackAlert.swift
//  Meiza
//
//  Created by Denis Windover on 19/01/2021.
//  Copyright © 2021 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class FinishPackAlert: AlertVC {
    
    
    @IBOutlet weak var lblMessage: UILabel!{
        didSet{
            lblMessage.text = "\("האם תרצה להזמין עוד".localized) \"\(product.name)\"?"
        }
    }
    @IBOutlet weak var btnYes: UIButton!{
        didSet{
            btnYes.setTitleColor(AppData.shared.mainColor, for: .normal)
            btnYes.borderColor = AppData.shared.mainColor
        }
    }
    @IBOutlet weak var btnNo: UIButton!
    
    var product: Product!

    override func viewDidLoad() {
        super.viewDidLoad()

        btnYes.rx.tap.subscribe(onNext: { [unowned self] _ in
            self.dismiss(completion: {
                Coordinator.shared.oneMorePack(self.product)
            })
        }).disposed(by: disposeBag)
        
        btnNo.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: {
                Coordinator.shared.popMain()
            })
        }).disposed(by: disposeBag)
        
    }
    

}
