//
//  CVVConfirmationVC.swift
//  PizzaShop
//
//  Created by Denis Windover on 17/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//
import UIKit
import RxCocoa
import RxSwift


//MARK: - VIEWMODEL
class CVVConfirmationViewModel {
    
    let disposeBag            = DisposeBag()
    var creditCardLast4Digits = BehaviorRelay<String>(value: "XXXX-XXXX-XXXX-\(User.currentUser?.creditCartLast4Digits ?? "")")
    var addAnotherCreditCard  = PublishSubject<Void>()
    var send                  = PublishSubject<Void>()
    var isCVVValid:             Observable<Bool>
    var cvv                   = BehaviorRelay<String?>(value: nil)
    let pickerPaymentsDataSource = BehaviorRelay<[String]>(value: AppData.shared.shop.maxPaymentsArr)
    let paymentsDidSelect     = PublishSubject<Int>()
    let payments              = BehaviorRelay<Int?>(value: 1)
    var isPaymentsHidden:       Observable<Bool>
    
    
    
    init(_ order: NewOrder){
        
        isCVVValid = cvv.map({ $0?.count == 3 || $0?.count == 4 })
        
        isPaymentsHidden = pickerPaymentsDataSource.map({ $0.count < 2 })
        
        addAnotherCreditCard.subscribe(onNext: { _ in
            Coordinator.shared.pushCreditCardDetails(order)
        }).disposed(by: disposeBag)
        
        paymentsDidSelect.withLatestFrom(pickerPaymentsDataSource, resultSelector: { $1[$0].toInt }).bind(to: payments).disposed(by: disposeBag)
        
        // with J5
        send
            .filter({ AppData.shared.shop.directPayment == false })
            .withLatestFrom(cvv)
            .flatMap({ [unowned self] in return RequestManager.shared.zcreditJ5Transaction($0 ?? "", deliveryPrice: order.orderType == "delivery" ? (AppData.shared.polygonsDeliveryCost ?? AppData.shared.deliveryCost) : 0.0, payments: payments.value ?? 1) })
            .subscribe(onNext: { [weak self] result in
                
                if let referenceNum = result.referenceNum {
                    var _order = order
                    _order.referenceNum = referenceNum
                    _order.payments = self?.payments.value ?? 1
                    self?.makeOrder(_order)
                }
                if let error = result.error {
                    error.toast(3)
                }
                
            }).disposed(by: disposeBag)
        
        //without J5
        send
            .filter({ AppData.shared.shop.directPayment == true })
            .withLatestFrom(cvv)
            .subscribe(onNext: { [weak self] _cvv in
                var _order = order
                _order.payments = self?.payments.value ?? 1
                self?.makeOrder(_order, cvv: _cvv)
            }).disposed(by: disposeBag)
        
    }
    
    private func makeOrder(_ order: NewOrder, cvv: String? = nil){
        
        RequestManager.shared.makeOrder(order, cvv: cvv).subscribe(onNext: { response in
            if let error = response.error {
                if let type = (error as? RequestManager.APIError.General)?.type {
                    if type == .dateError {
                        AlertCoordinator.shared.dateError(order.orderType) {
                            if !((order.orderType == "delivery" && AppData.shared.shop.withoutFutureDelivery) || (order.orderType == "pickup" && AppData.shared.shop.withoutFuturePickup)) {
                                Coordinator.shared.popToSummaryVCAfterOrderDateError()
                            }
                        }
                        return
                    }
                }
                error.toast(3)
            }
            else if let id = response.orderID {
                CartProduct.deleteAllCartProducts()
                AlertCoordinator.shared.orderSuccess(order.paymentType ?? "", orderID: id)
            }
        }).disposed(by: disposeBag)
    }
    
    
}


//MARK: - VIEW
class CVVConfirmationVC: BaseVC {
    
    
    @IBOutlet weak var lblCreditCardLast4Difits: UILabel!
    @IBOutlet weak var txtCVV: UITextField!
    @IBOutlet weak var btnSend: UIButton!
    @IBOutlet weak var btnAddAnotherCrediCard: UIButton!{
        didSet{ btnAddAnotherCrediCard.setTitleColor(AppData.shared.mainColor, for: .normal) }
    }
    @IBOutlet var views: [UIView]!
    
    @IBOutlet weak var lblPayments: UILabel!
    @IBOutlet weak var viewPayments: UIView!
    @IBOutlet weak var ivArrowPayments: UIImageView!
    @IBOutlet weak var txtPayments: UITextField!
    
    
    
    var viewModel: CVVConfirmationViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        [btnBack, btnMenu].forEach({ $0?.imageColor = AppData.shared.mainColor })
        
        //MARK: - OUTPUTS
        let paymentsInputView = DWInputPicker.getFromNib()
        txtPayments.inputView = paymentsInputView
        paymentsInputView.picker.rx.itemSelected.map({ $0.row }).bind(to: viewModel.paymentsDidSelect).disposed(by: disposeBag)
        
        btnSend.rx.tap.bind(to: viewModel.send).disposed(by: disposeBag)
        btnAddAnotherCrediCard.rx.tap.bind(to: viewModel.addAnotherCreditCard).disposed(by: disposeBag)
        txtCVV.rx.text.bind(to: viewModel.cvv).disposed(by: disposeBag)
        
        btnSend.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.view.endEditing(true)
        }).disposed(by: disposeBag)
    
        
        //MARK: - INPUTS
        viewModel.isCVVValid.bind(to: btnSend.rx.isEnabled).disposed(by: disposeBag)
        viewModel.isCVVValid.map({ $0 ? AppData.shared.mainColor : .lightGray }).bind(to: btnSend.rx.animated.fade(duration: 0.5).backgroundColor).disposed(by: disposeBag)
        viewModel.creditCardLast4Digits.bind(to: lblCreditCardLast4Difits.rx.text).disposed(by: disposeBag)
        
        
        viewModel.pickerPaymentsDataSource.bind(to: paymentsInputView.picker.rx.itemTitles){ _, payments in
            return payments
        }.disposed(by: disposeBag)
        
        viewModel.payments.map({ $0?.toString }).subscribe(txtPayments.rx.text).disposed(by: disposeBag)
        
        viewModel.isPaymentsHidden.bind(to: viewPayments.rx.isHidden).disposed(by: disposeBag)
        viewModel.isPaymentsHidden.bind(to: lblPayments.rx.isHidden).disposed(by: disposeBag)
        
        paymentsInputView.btnChoose.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.view.endEditing(true)
            self?.rotateArrow(false, imageView: self?.ivArrowPayments)
        }).disposed(by: disposeBag)
    }
    
    var didLoad = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didLoad {
            didLoad = true
            views.forEach({ $0.dropShadow() })
        }
    }

    //MARK: - HELPERS
    fileprivate func rotateArrow(_ open: Bool, imageView: UIImageView?){
        let position = open ? CGAffineTransform(rotationAngle: CGFloat(Double.pi * 1)) : CGAffineTransform.identity
        
        UIView.animate(withDuration: 0.25, animations: {
            if imageView?.transform != position{
                imageView?.transform = position
            }
        }) { (completed) in}
    }

}
