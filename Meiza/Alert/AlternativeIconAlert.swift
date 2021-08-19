//
//  AlternativeIconAlert.swift
//  Meiza
//
//  Created by Denis Windover on 24/08/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class AlternativeIconViewModel {
    
    let disposeBag = DisposeBag()
    let icon: Observable<UIImage?>
    let name: Observable<String>
    
    init(_ icon: UIImage?, name: String){
        self.icon = Observable.just(icon)
        self.name = Observable.just("האם ברצונך לשנות לאייקון של \(name)?")
    }
    
    
}


class AlternativeIconAlert: AlertVC {
    
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var ivAppIcon: UIImageView!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnOk: UIButton!
    
    var viewModel: AlternativeIconViewModel!
    var isIconAproved: (Bool)->() = { _ in }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.icon.bind(to: ivAppIcon.rx.image).disposed(by: disposeBag)
        viewModel.name.bind(to: lblTitle.rx.text).disposed(by: disposeBag)
        
        btnCancel.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: {
                self?.isIconAproved(false)
            })
        }).disposed(by: disposeBag)
        
        btnOk.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: {
                self?.isIconAproved(true)
            })
        }).disposed(by: disposeBag)
        
    }

}
