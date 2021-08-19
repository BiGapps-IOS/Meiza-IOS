//
//  CreditCartDetailsVC.swift
//  PizzaShop
//
//  Created by Denis Windover on 17/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxAnimated


//MARK: - VIEWMODEL
class CreditCardDetailsViewModel {
    
    let disposeBag            = DisposeBag()
    var fullname              = BehaviorRelay<String?>(value: nil)
    var passID                = BehaviorRelay<String?>(value: nil)
    var creditCardNumber      = BehaviorRelay<String?>(value: nil)
    var cvv                   = BehaviorRelay<String?>(value: nil)
    var year                  = BehaviorRelay<String?>(value: nil)
    var month                 = BehaviorRelay<String?>(value: nil)
    var saveDidTap            = PublishSubject<Void>()
    var isDataValid:            Observable<Bool>
    var pickerYearDatasource  = BehaviorRelay<[String]>(value: [])
    var pickerMonthDatasource = BehaviorRelay<[String]>(value: ["", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"])
    var yearDidSelect         = PublishSubject<Int>()
    var monthDidSelect        = PublishSubject<Int>()
    private var token         = BehaviorRelay<String?>(value: nil)
    let pickerPaymentsDataSource = BehaviorRelay<[String]>(value: AppData.shared.shop.maxPaymentsArr)
    let paymentsDidSelect     = PublishSubject<Int>()
    let payments              = BehaviorRelay<Int?>(value: 1)
    var isPaymentsHidden:       Observable<Bool>
    
    init(_ order: NewOrder){
        
        isDataValid = Observable<Bool>.combineLatest(fullname, passID, creditCardNumber, cvv, year, month){ _fullname, _passID, _creditCardNumber, _cvv, _year, _month in
            let fullnameValid = !(_fullname?.isEmpty ?? true)
            let passIDValid = !(_passID?.isEmpty ?? true)
            let creditCardNumberValid = (_creditCardNumber?.count ?? 0) >= 8
            let cvvValid = (_cvv?.count ?? 0) == 3 || (_cvv?.count ?? 0) == 4
            let yearValid = !(_year?.isEmpty ?? true)
            let monthValid = !(_month?.isEmpty ?? true)
            
            return fullnameValid && passIDValid && creditCardNumberValid && cvvValid && yearValid && monthValid
        }
        
        isPaymentsHidden = pickerPaymentsDataSource.map({ $0.count < 2 })
        
        pickerYearDatasource.accept(getPickerYearDatasource())
        
        yearDidSelect.map({ [weak self] row in self?.pickerYearDatasource.value[row] }).bind(to: year).disposed(by: disposeBag)
        monthDidSelect.map({ [weak self] row in self?.pickerMonthDatasource.value[row] }).bind(to: month).disposed(by: disposeBag)
        paymentsDidSelect.withLatestFrom(pickerPaymentsDataSource, resultSelector: { $1[$0].toInt }).bind(to: payments).disposed(by: disposeBag)
        
        saveDidTap
            .withLatestFrom(creditCardNumber)
            .flatMap({ [unowned self] cc in return RequestManager.shared.getZCreditToken(cc ?? "", expDate: "\(self.month.value ?? "")\(String((self.year.value ?? "0000").suffix(2)))") })
            .filter({ result in if result.error != nil{ result.error?.toast(3) }; return result.token != nil })
            .map({ $0.token })
            .bind(to: token)
            .disposed(by: disposeBag)
        
        token.subscribe(onNext: { [weak self] _token in
            if let _token = _token {
                User.currentUser?.passID = self?.passID.value
                User.currentUser?.creditCartLast4Digits = String((self?.creditCardNumber.value ?? "").suffix(4))
                User.currentUser?.yearExp = self?.year.value
                User.currentUser?.monthExp = self?.month.value
                User.currentUser?.zcreditToken = _token
                
                self?.zcreditJ5Transaction(order)
            }
        }).disposed(by: disposeBag)
        
    }
    
    private func getPickerYearDatasource() -> [String] {
        let year = Calendar.current.component(.year, from: Date())
        var years = ["", year.toString]
        for i in 1..<10 {
            years.append((year + i).toString)
        }
        
        return years
    }
    
    private func zcreditJ5Transaction(_ order: NewOrder){
        
        if AppData.shared.shop.directPayment == true {
            var _order = order
            _order.payments = self.payments.value ?? 1
            makeOrder(_order, cvv: self.cvv.value)
        }else{
            RequestManager.shared.zcreditJ5Transaction(self.cvv.value ?? "", deliveryPrice: order.orderType == "delivery" ? AppData.shared.polygonsDeliveryCost ?? AppData.shared.deliveryCost : 0.0, payments: payments.value ?? 1).subscribe(onNext: { [weak self] result in
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
        }
        
        
        
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
class CreditCartDetailsVC: BaseVC {
    
    
    @IBOutlet weak var txtFullname: UITextField!
    @IBOutlet weak var txtPassID: UITextField!
    @IBOutlet weak var txtCreditCardNumber: UITextField!
    @IBOutlet weak var txtCVV: UITextField!
    @IBOutlet weak var ivArrowYear: UIImageView!
    @IBOutlet weak var txtYear: UITextField!
    @IBOutlet weak var ivArrowMonth: UIImageView!
    @IBOutlet weak var txtMonth: UITextField!
    @IBOutlet weak var btnSave: UIButton!
    @IBOutlet var views: [UIView]!
    @IBOutlet weak var ivArrowPayments: UIImageView!
    @IBOutlet weak var txtPayments: UITextField!
    
    @IBOutlet weak var viewPayments: UIView!
    @IBOutlet weak var lblPayments: UILabel!
    
    var viewModel: CreditCardDetailsViewModel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        [btnBack, btnMenu, btnSearch].forEach({ $0?.imageColor = AppData.shared.mainColor })
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] _ in
            if self?.txtYear.isFirstResponder == true {
                self?.rotateArrow(true, imageView: self?.ivArrowYear)
            }
            if self?.txtMonth.isFirstResponder == true {
                self?.rotateArrow(true, imageView: self?.ivArrowMonth)
            }
            if self?.txtPayments.isFirstResponder == true {
                self?.rotateArrow(true, imageView: self?.ivArrowPayments)
            }
        }
        
        let yearInputView = DWInputPicker.getFromNib()
        let monthInputView = DWInputPicker.getFromNib()
        let paymentsInputView = DWInputPicker.getFromNib()
        txtYear.inputView = yearInputView
        txtMonth.inputView = monthInputView
        txtPayments.inputView = paymentsInputView

        //MARK: - OUTPUTS
        txtFullname.rx.text.bind(to: viewModel.fullname).disposed(by: disposeBag)
        txtPassID.rx.text.bind(to: viewModel.passID).disposed(by: disposeBag)
        txtCreditCardNumber.rx.text.bind(to: viewModel.creditCardNumber).disposed(by: disposeBag)
        txtCVV.rx.text.bind(to: viewModel.cvv).disposed(by: disposeBag)
        btnSave.rx.tap.bind(to: viewModel.saveDidTap).disposed(by: disposeBag)
        
        btnSave.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.view.endEditing(true)
        }).disposed(by: disposeBag)
        
        txtFullname.rx.controlEvent([.editingDidEndOnExit]).subscribe(onNext: { [weak self] _ in
            self?.txtPassID.becomeFirstResponder()
        }).disposed(by: disposeBag)
        
        yearInputView.picker.rx.itemSelected.map({ $0.row }).bind(to: viewModel.yearDidSelect).disposed(by: disposeBag)
        monthInputView.picker.rx.itemSelected.map({ $0.row }).bind(to: viewModel.monthDidSelect).disposed(by: disposeBag)
        paymentsInputView.picker.rx.itemSelected.map({ $0.row }).bind(to: viewModel.paymentsDidSelect).disposed(by: disposeBag)
        
        yearInputView.btnChoose.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.view.endEditing(true)
            self?.rotateArrow(false, imageView: self?.ivArrowYear)
        }).disposed(by: disposeBag)
        
        monthInputView.btnChoose.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.view.endEditing(true)
            self?.rotateArrow(false, imageView: self?.ivArrowMonth)
        }).disposed(by: disposeBag)
        
        paymentsInputView.btnChoose.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.view.endEditing(true)
            self?.rotateArrow(false, imageView: self?.ivArrowPayments)
        }).disposed(by: disposeBag)
        
        
        //MARK: - INPUTS
        viewModel.isDataValid.bind(to: btnSave.rx.isEnabled).disposed(by: disposeBag)
        viewModel.isDataValid.map({ $0 ? AppData.shared.mainColor : .lightGray }).bind(to: btnSave.rx.animated.fade(duration: 0.5).backgroundColor).disposed(by: disposeBag)
        
        viewModel.pickerYearDatasource.bind(to: yearInputView.picker.rx.itemTitles){ _, year in
            return year
        }.disposed(by: disposeBag)
        
        viewModel.pickerMonthDatasource.bind(to: monthInputView.picker.rx.itemTitles){ _, month in
            return month
        }.disposed(by: disposeBag)
        
        viewModel.pickerPaymentsDataSource.bind(to: paymentsInputView.picker.rx.itemTitles){ _, payments in
            return payments
        }.disposed(by: disposeBag)
        
        viewModel.year.subscribe(txtYear.rx.text).disposed(by: disposeBag)
        viewModel.month.subscribe(txtMonth.rx.text).disposed(by: disposeBag)
        viewModel.payments.map({ $0?.toString }).subscribe(txtPayments.rx.text).disposed(by: disposeBag)
        
        viewModel.isPaymentsHidden.bind(to: viewPayments.rx.isHidden).disposed(by: disposeBag)
        viewModel.isPaymentsHidden.bind(to: lblPayments.rx.isHidden).disposed(by: disposeBag)
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
