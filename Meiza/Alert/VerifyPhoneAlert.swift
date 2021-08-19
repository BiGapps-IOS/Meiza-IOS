//
//  VerifyPhoneAlert.swift
//  Meiza
//
//  Created by Denis Windover on 06/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxAnimated


class VerifyPhoneViewModel {
    
    let disposeBag = DisposeBag()
    var phone = BehaviorRelay<String>(value: "")
    var isPhoneValid = BehaviorRelay<Bool>(value: false)
    var okDidTap = PublishSubject<Void>()
    var validPhone = PublishSubject<String>()
    
    init(){
        
        phone.map({ $0.count == 10 }).bind(to: isPhoneValid).disposed(by: disposeBag)
        
        okDidTap
            .withLatestFrom(phone)
            .flatMap { RequestManager.shared.userPhone($0) }
            .subscribe(onNext: { [weak self] error in
                if let error = error {
                    error.toast()
                }else{
                    self?.validPhone.onNext(self?.phone.value ?? "")
                }
                
            }).disposed(by: disposeBag)
        
    }
    
}

class VerifyPhoneAlert: AlertVC {
    
    
    @IBOutlet weak var btnOK: UIButton!
    @IBOutlet weak var viewPhone: UIView!
    @IBOutlet weak var txtPhone: UITextField!
    
    var viewModel = VerifyPhoneViewModel()
    var phone: (String)->() = { _ in }
    
    var didLoad = false
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didLoad{
            didLoad = true
            viewPhone.dropShadow()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtPhone.becomeFirstResponder()
        
        //MARK: - OUTPUTS
        btnOK.rx.tap.bind(to: viewModel.okDidTap).disposed(by: disposeBag)
        txtPhone.rx.text.orEmpty.bind(to: viewModel.phone).disposed(by: disposeBag)
        btnOK.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.view.endEditing(true)
        }).disposed(by: disposeBag)
        
        //MARK: - INPUTS
        viewModel.isPhoneValid.bind(to: btnOK.rx.animated.fade(duration: 0.5).isEnabled).disposed(by: disposeBag)
        viewModel.validPhone.subscribe(onNext: { [weak self] phone in
            self?.dismiss(completion: { [weak self] in
                self?.phone(phone)
            })
        }).disposed(by: disposeBag)
    }
    

    @IBAction func btnCancelTapped(_ sender: UIButton) {
        self.dismiss(completion: nil)
    }
    

}
