//
//  PackAlert.swift
//  Meiza
//
//  Created by Denis Windover on 14/01/2021.
//  Copyright © 2021 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift



class PackAlert: AlertVC {
    
    
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnAddOneMore: UIButton!{
        didSet{
            btnAddOneMore.setTitleColor(AppData.shared.mainColor, for: .normal)
            btnAddOneMore.borderColor = AppData.shared.mainColor
        }
    }
    @IBOutlet weak var btnUpdateExist: UIButton!
    

    var oneMore: ()->() = {}
    
    override func viewDidLoad() {
        super.viewDidLoad()

        btnClose.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: nil)
        }).disposed(by: disposeBag)
        
        btnAddOneMore.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: {
                self?.oneMore()
            })
        }).disposed(by: disposeBag)
        
        btnUpdateExist.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: {
                Coordinator.shared.pushCart()
            })
        }).disposed(by: disposeBag)
        
        
    }


}
