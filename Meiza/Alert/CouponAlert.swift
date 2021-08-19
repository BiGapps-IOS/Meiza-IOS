//
//  CouponAlert.swift
//  Meiza
//
//  Created by Denis Windover on 06/10/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxAnimated

class CouponAlertViewModel {
    
    let disposeBag = DisposeBag()
    var couponName = BehaviorRelay<String?>(value: nil)
    var sendCouponDidTap = PublishSubject<Void>()
    var color = BehaviorRelay<UIColor>(value: .black)
    var errorText = BehaviorRelay<String?>(value: nil)
    var dismissAlert = PublishSubject<Double>()
    
    init(){
        
        sendCouponDidTap.map({ [unowned self] _ in return self.couponName.value?.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter({ $0?.isEmpty == false })
            .flatMap({ RequestManager.shared.checkCoupon($0!) })
            .subscribe(onNext: { [weak self] response in
                if let error = response.error {
                    self?.errorText.accept(error.errorMessage?.localized)
                    self?.color.accept(.red)
                }else if let discount = response.discount {
                    AppData.shared.coupon = (name: self?.couponName.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", discount: discount)
                    self?.dismissAlert.onNext(discount)
                }
            }).disposed(by: disposeBag)
        
    }
    
}

class CouponAlert: AlertVC {
    
    
    @IBOutlet weak var lblErrorMessage: UILabel!
    @IBOutlet weak var txtCoupon: UITextField!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnSendCoupon: UIButton! {
        didSet{ btnSendCoupon.backgroundColor = AppData.shared.mainColor }
    }
    
    var viewModel = CouponAlertViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        txtCoupon.becomeFirstResponder()
        
        txtCoupon.rx.text.bind(to: viewModel.couponName).disposed(by: disposeBag)
        
        btnClose.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: nil)
        }).disposed(by: disposeBag)
        
        btnCancel.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: nil)
        }).disposed(by: disposeBag)
        
        btnSendCoupon.rx.tap.bind(to: viewModel.sendCouponDidTap).disposed(by: disposeBag)
        
        txtCoupon.rx.controlEvent(.editingChanged).map({ _ in return "" }).bind(to: lblErrorMessage.rx.text).disposed(by: disposeBag)
        txtCoupon.rx.controlEvent(.editingChanged).map({ _ in return UIColor.black }).bind(to: viewModel.color).disposed(by: disposeBag)
        
        
        viewModel.color.bind(to: txtCoupon.rx.textColor).disposed(by: disposeBag)
        viewModel.errorText.bind(to: lblErrorMessage.rx.text).disposed(by: disposeBag)
        viewModel.dismissAlert.subscribe(onNext: { [weak self] _discount in
            self?.dismiss(completion: {
                AlertCoordinator.shared.couponSuccess(_discount)
            })
        }).disposed(by: disposeBag)
        
    }

}
