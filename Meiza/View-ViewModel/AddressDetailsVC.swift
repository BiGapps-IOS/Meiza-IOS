//
//  AddressDetailsVC.swift
//  PizzaShop
//
//  Created by Denis Windover on 14/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift


//MARK: - VIEWMODEL
class AddressDetailsViewModel {
    
    let disposeBag          = DisposeBag()
    var user                = BehaviorRelay<User?>(value: User.currentUser)
    var isCreditAllow       = BehaviorRelay<Bool>(value: AppData.shared.shop.paymentTypes.contains("credit"))
    var isCashAllow         = BehaviorRelay<Bool>(value: AppData.shared.shop.paymentTypes.contains("cash"))
    var fullname            = BehaviorRelay<String?>(value: nil)
    var phone               = BehaviorRelay<String?>(value: nil)
    var email               = BehaviorRelay<String?>(value: nil)
    var street              = BehaviorRelay<String?>(value: nil)
    var streetNum           = BehaviorRelay<String?>(value: nil)
    var entranceCode        = BehaviorRelay<String?>(value: nil)
    var apartment           = BehaviorRelay<String?>(value: nil)
    var floor               = BehaviorRelay<String?>(value: nil)
    var city                = BehaviorRelay<String?>(value: nil)
    var isAgreePrivacy      = BehaviorRelay<Bool>(value: User.currentUser?.isAgreePrivacy ?? false)
    var agreePrivacyDidTap  = PublishSubject<Void>()
    var goTerms             = PublishSubject<Void>()
    var goPrivacy           = PublishSubject<Void>()
    var paymnentTypeDidTap  = PublishSubject<String>()
    private var paymentType = BehaviorRelay<String?>(value: nil)
    var invalidFields       = BehaviorRelay<[String]>(value: [])
    var isOrder             = BehaviorRelay<Bool>(value: true)
    var saveDataDidTap      = PublishSubject<Void>()
    var saveAlreadyDidTap   = BehaviorRelay<Bool>(value: false)
    var isAddressHidden     = BehaviorRelay<Bool>(value: false)
    var titleCashButton     = BehaviorRelay<String>(value: "")
    
    init(_ order: NewOrder?){
        
        Observable<[String]>.combineLatest(saveAlreadyDidTap, fullname, phone, street, streetNum, city, isAddressHidden, email){ _saveAlreadyDidTap, _fullname, _phone, _street, _streetNum, _city, _isAddressHidden, _email in
            
            if !_saveAlreadyDidTap { return [] }
            
            var invalidFields = [String]()
            
            if !_isAddressHidden {
                if _street == nil || _street!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { invalidFields.append("street") }
                if _streetNum == nil || _streetNum!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { invalidFields.append("streetNum") }
                if _city == nil || _city!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { invalidFields.append("city") }
            }
            
            if _fullname == nil || _fullname!.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 { invalidFields.append("fullname") }
            if _phone == nil || _phone!.trimmingCharacters(in: .whitespacesAndNewlines).count != 10 { invalidFields.append("phone") }
            if _email == nil || !_email!.trimmingCharacters(in: .whitespacesAndNewlines).isEmailValid() { invalidFields.append("email") }
            
            return invalidFields
            
            }.bind(to: invalidFields).disposed(by: disposeBag)
        
        isOrder.accept(order != nil)
        
        Observable.just((order?.orderType == "delivery" ? "תשלום לשליח" : "תשלום בחנות").localized).bind(to: titleCashButton).disposed(by: disposeBag)
        
        Observable.just(order?.orderType == "pickup").bind(to: isAddressHidden).disposed(by: disposeBag)
        
        goTerms.subscribe(onNext: { _ in
            Coordinator.shared.pushInfo(.terms)
        }).disposed(by: disposeBag)
        
        goPrivacy.subscribe(onNext: { _ in
            Coordinator.shared.pushInfo(.privacy)
        }).disposed(by: disposeBag)
        
        paymnentTypeDidTap.bind(to: paymentType).disposed(by: disposeBag)
        
        paymnentTypeDidTap.map {  [weak self] _ -> Bool in
            guard let `self` = self else{ return false }
            
            self.saveAlreadyDidTap.accept(true)
            
            guard self.isAgreePrivacy.value else { "נא לאשר את התקנון".toast(); return false }
            
            if self.fullname.value == nil || self.fullname.value!.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 { return false }
            if self.phone.value == nil || self.phone.value!.trimmingCharacters(in: .whitespacesAndNewlines).count != 10 { return false }
            
            if self.email.value == nil || !self.email.value!.trimmingCharacters(in: .whitespacesAndNewlines).isEmailValid() { return false }
            
            if order?.orderType == "delivery" {
                if self.street.value == nil || self.street.value!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
                if self.streetNum.value == nil || self.streetNum.value!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
                if self.city.value == nil || self.city.value!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
            }
            
            User.currentUser?.fullName = self.fullname.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            User.currentUser?.phone = self.phone.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            User.currentUser?.email = self.email.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            User.currentUser?.city = self.city.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            User.currentUser?.street = self.street.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            User.currentUser?.streetNum = self.streetNum.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            User.currentUser?.entranceCode = self.entranceCode.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            User.currentUser?.apartment = self.apartment.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            User.currentUser?.floor = self.floor.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            User.currentUser?.isAgreePrivacy = true
            
            return true
        }.filter({ $0 }).throttle(.milliseconds(1000), latest: false, scheduler: MainScheduler.instance)
            .flatMap({ [unowned self] _ in order?.orderType == "delivery" ? self.coordinatesFromAddress() : Observable.just(nil) })
            .map({ _location -> CLLocation? in
                if order?.orderType == "delivery" {
                    if _location == nil {
                        User.currentUser?.lat = nil
                        User.currentUser?.lon = nil
                        return nil
                    }else{
                        User.currentUser?.lat = _location?.coordinate.latitude
                        User.currentUser?.lon = _location?.coordinate.longitude
                    }
                }
                
                return _location
            })
            .flatMap({ _ in return RequestManager.shared.upsertUser() }).subscribe(onNext: { [weak self] _result in
                
                if let userID = _result.userID {
                    if userID == 0 { // not verified user
                        AlertCoordinator.shared.verifyCode(self?.phone.value ?? "") { _userID in
                            User.currentUser?.id = _userID
                            self?.checkIfNeedDeliveryCostAlert(order)
                        }
                    }else{
                        User.currentUser?.id = userID
                        self?.checkIfNeedDeliveryCostAlert(order)
                    }
                    
                }else if let error = _result.error {
                    error.toast()
                }
                
            }).disposed(by: disposeBag)
        
        agreePrivacyDidTap.map({ [weak self] _ in self?.isAgreePrivacy.value == true ? false : true  }).bind(to: isAgreePrivacy).disposed(by: disposeBag)
        
        
        saveDataDidTap.throttle(.milliseconds(1000), latest: false, scheduler: MainScheduler.instance)
            .map {  [weak self] _ -> Bool in
                guard let `self` = self else{ return false }

                self.saveAlreadyDidTap.accept(true)
                
                if self.invalidFields.value.count > 0 { return false }

            User.currentUser?.fullName = self.fullname.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            User.currentUser?.phone = self.phone.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            User.currentUser?.email = self.email.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            User.currentUser?.city = self.city.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            User.currentUser?.street = self.street.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            User.currentUser?.streetNum = self.streetNum.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            User.currentUser?.entranceCode = self.entranceCode.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            User.currentUser?.apartment = self.apartment.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            User.currentUser?.floor = self.floor.value?.trimmingCharacters(in: .whitespacesAndNewlines)

            return true
            }.filter({ $0 })
            .flatMap({ [unowned self] _ in self.coordinatesFromAddress() })
            .map({ loc -> CLLocation? in
                    if loc == nil{
                        let message = "כתובת לא תקינה".localized;
                        message.toast() };
                    return loc })
            .filter({ $0 != nil })
            .map({ _location -> CLLocation? in
                User.currentUser?.lat = _location?.coordinate.latitude
                User.currentUser?.lon = _location?.coordinate.longitude
                return _location
            })
            .flatMap({ _ in return RequestManager.shared.upsertUser() }).subscribe(onNext: { [weak self] _result in
                
                if let userID = _result.userID {
                let dataSaved = "פרטים עודכנו בהצלחה!".localized
                if userID == 0 { // not verified user
                    AlertCoordinator.shared.verifyCode(self?.phone.value ?? "") { _userID in
                        User.currentUser?.id = _userID
                        dataSaved.toast()
                        Coordinator.shared.goBack()
                    }
                }else{
                    User.currentUser?.id = userID
                    dataSaved.toast()
                    Coordinator.shared.goBack()
                }

            }else if let error = _result.error {
                error.toast()
            }

        }).disposed(by: disposeBag)
        
    }
    
    private func checkIfNeedDeliveryCostAlert(_ order: NewOrder?){
        
        if order?.orderType == "delivery" { // && (User.currentUser?.lat == nil || User.currentUser?.lon == nil)
            guard var _order = order, let paymentType = self.paymentType.value else{ return }
            _order.paymentType = paymentType
            let address = "\(User.currentUser?.street ?? "") \(User.currentUser?.streetNum ?? ""), \(User.currentUser?.city ?? "")"
            RequestManager.shared.fetchAddress(with: address) { _location in
                Coordinator.shared.map(_order)
            }
            return
        }
        
        if order?.orderType == "delivery" && !AppData.shared.shop.isDistanceOk {
            AlertCoordinator.shared.radiusErrorOrder()
            return
        }
        
        if AppData.shared.shop.deliveryZones.count > 0 && order?.orderType == "delivery" {
            AlertCoordinator.shared.deliveryCost { [weak self] in
                self?.goNext(order)
            }
        }else{
            goNext(order)
        }
    }
    
    private func goNext(_ order: NewOrder?){
        guard var _order = order else{ return }
        
        if let paymentType = self.paymentType.value {
            _order.paymentType = paymentType
            if paymentType == "credit" {
                if User.currentUser?.creditCartLast4Digits == nil {
                    Coordinator.shared.pushCreditCardDetails(_order)
                }else{
                    Coordinator.shared.pushCVVConfirmation(_order)
                }
            }else if paymentType == "cash" {
                
                RequestManager.shared.makeOrder(_order).subscribe(onNext: { response in
                    if let error = response.error {
                        if let type = (error as? RequestManager.APIError.General)?.type {
                            if type == .dateError {
                                AlertCoordinator.shared.dateError(_order.orderType) {
                                    if !((order?.orderType == "delivery" && AppData.shared.shop.withoutFutureDelivery) || (_order.orderType == "pickup" && AppData.shared.shop.withoutFuturePickup)) {
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
                        AlertCoordinator.shared.orderSuccess(_order.paymentType ?? "", orderID: id)
                    }
                }).disposed(by: disposeBag)
            }
        }
    }
    
}




//MARK: - VIEW
class AddressDetailsVC: BaseVC {
    
    
    @IBOutlet var views: [UIView]!
    @IBOutlet weak var txtFullname: UITextField!
    @IBOutlet weak var txtPhone: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtStreet: UITextField!
    @IBOutlet weak var txtStreetNum: UITextField!
    @IBOutlet weak var txtFloor: UITextField!
    @IBOutlet weak var txtApartment: UITextField!
    @IBOutlet weak var txtEntranceCode: UITextField!
    @IBOutlet weak var txtCity: UITextField!
    @IBOutlet weak var btnCredit: UIButton!
    @IBOutlet weak var btnAgreePrivacy: UIButton!
    @IBOutlet weak var lblPrivacy: UILabel!{
        didSet{
            let attrStr = NSMutableAttributedString()
            attrStr
                .normal("אני מאשר שקראתי את".localized, fontSize: 11, color: .myLightGray)
                .normal(" התקנון ".localized, fontSize: 11, color: .black)
                .normal("ואת".localized, fontSize: 11, color: .myLightGray)
                .normal(" מדיניות הפרטיות ".localized, fontSize: 11, color: .black)
                .normal("ואני מסכים לתנאים".localized, fontSize: 11, color: .myLightGray)
            lblPrivacy.attributedText = attrStr
        }
    }
    @IBOutlet weak var buttonCash:UIButton!
    @IBOutlet weak var btnSaveData: UIButton!
    @IBOutlet weak var viewCheckbox: UIView!
    
    @IBOutlet var viewsAddress: [UIView]!
    @IBOutlet weak var constrTopLblPrivacyNoAddress: NSLayoutConstraint!
    @IBOutlet weak var constrTopLblPrivacyWithAddress: NSLayoutConstraint!
    @IBOutlet weak var constrTopBtnPrivacyNoAddress: NSLayoutConstraint!
    @IBOutlet weak var constrTopBtnPrivacyWithAddress: NSLayoutConstraint!
    
    
    
    var viewModel: AddressDetailsViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer()
        lblPrivacy.addGestureRecognizer(tap)
        lblPrivacy.isUserInteractionEnabled = true
        
        tap.rx.event
            .map({ [weak self] in $0.didTap(text: " התקנון ".localized, inLabel: self?.lblPrivacy) })
            .filter({ $0 == true })
            .map({ _ in return Void() })
            .bind(to: viewModel.goTerms)
            .disposed(by: disposeBag)
        
        tap.rx.event
            .map({ [weak self] in $0.didTap(text: " מדיניות הפרטיות ".localized, inLabel: self?.lblPrivacy) })
            .filter({ $0 == true })
            .map({ _ in return Void() })
            .bind(to: viewModel.goPrivacy)
            .disposed(by: disposeBag)
        
        viewModel.user.map({ $0?.fullName }).take(1).subscribe(txtFullname.rx.text).disposed(by: disposeBag)
        viewModel.user.map({ $0?.phone }).take(1).subscribe(txtPhone.rx.text).disposed(by: disposeBag)
        viewModel.user.map({ $0?.street }).take(1).subscribe(txtStreet.rx.text).disposed(by: disposeBag)
        viewModel.user.map({ $0?.streetNum }).take(1).subscribe(txtStreetNum.rx.text).disposed(by: disposeBag)
        viewModel.user.map({ $0?.entranceCode }).take(1).subscribe(txtEntranceCode.rx.text).disposed(by: disposeBag)
        viewModel.user.map({ $0?.apartment }).take(1).subscribe(txtApartment.rx.text).disposed(by: disposeBag)
        viewModel.user.map({ $0?.floor }).take(1).subscribe(txtFloor.rx.text).disposed(by: disposeBag)
        viewModel.user.map({ $0?.city }).take(1).subscribe(txtCity.rx.text).disposed(by: disposeBag)
        viewModel.user.map({ $0?.email }).take(1).subscribe(txtEmail.rx.text).disposed(by: disposeBag)
        
        disablingEmoji()
        
        //MARK: - OUTPUTS
        txtFullname.rx.text.bind(to: viewModel.fullname).disposed(by: disposeBag)
        txtPhone.rx.text.bind(to: viewModel.phone).disposed(by: disposeBag)
        txtEmail.rx.text.bind(to: viewModel.email).disposed(by: disposeBag)
        txtStreet.rx.text.bind(to: viewModel.street).disposed(by: disposeBag)
        txtStreetNum.rx.text.bind(to: viewModel.streetNum).disposed(by: disposeBag)
        txtEntranceCode.rx.text.bind(to: viewModel.entranceCode).disposed(by: disposeBag)
        txtApartment.rx.text.bind(to: viewModel.apartment).disposed(by: disposeBag)
        txtFloor.rx.text.bind(to: viewModel.floor).disposed(by: disposeBag)
        txtCity.rx.text.bind(to: viewModel.city).disposed(by: disposeBag)
        
  
        btnAgreePrivacy.rx.tap.bind(to: viewModel.agreePrivacyDidTap).disposed(by: disposeBag)
        btnCredit.rx.tap.map({ _ in return "credit" }).bind(to: viewModel.paymnentTypeDidTap).disposed(by: disposeBag)
        buttonCash.rx.tap.map({ _ in return "cash" }).bind(to: viewModel.paymnentTypeDidTap).disposed(by: disposeBag)
        btnSaveData.rx.tap.bind(to: viewModel.saveDataDidTap).disposed(by: disposeBag)
        
        
        //MARK: - INPUTS
        viewModel.isAgreePrivacy.map({ $0 ? UIImage(named: "blue_v")?.imageWithColor(color1: AppData.shared.mainColor) : nil }).bind(to: btnAgreePrivacy.rx.animated.fade(duration: 0.5).image).disposed(by: disposeBag)
        viewModel.isCreditAllow.map({ $0 ? AppData.shared.mainColor : .clear }).bind(to: btnCredit.rx.backgroundColor).disposed(by: disposeBag)
        viewModel.isCreditAllow.map({ !$0 }).bind(to: btnCredit.rx.isHidden).disposed(by: disposeBag)
        viewModel.isCashAllow.map({ $0 ? AppData.shared.mainColor : .clear }).bind(to: buttonCash.rx.backgroundColor).disposed(by: disposeBag)
        viewModel.isCashAllow.map({ !$0 }).bind(to: buttonCash.rx.isHidden).disposed(by: disposeBag)
        viewModel.isCashAllow.bind(to: buttonCash.rx.isEnabled).disposed(by: disposeBag)
        viewModel.isCreditAllow.bind(to: btnCredit.rx.isEnabled).disposed(by: disposeBag)
        
        viewModel.invalidFields.subscribe(onNext: { [weak self] _fields in
            var fields = [UITextField]()
            
            _fields.forEach { _field in
                switch _field{
                case "fullname": fields.append(self?.txtFullname ?? UITextField())
                case "phone": fields.append(self?.txtPhone ?? UITextField())
                case "street": fields.append(self?.txtStreet ?? UITextField())
                case "streetNum": fields.append(self?.txtStreetNum ?? UITextField())
                case "city": fields.append(self?.txtCity ?? UITextField())
                case "email": fields.append(self?.txtEmail ?? UITextField())
                default: break
                }
            }
            
            self?.setBorderForInvalidFields(fields)
        }).disposed(by: disposeBag)
        
        viewModel.isOrder.bind(to: btnSaveData.rx.isHidden).disposed(by: disposeBag)
        viewModel.isOrder.map({ !$0 }).bind(to: btnCredit.rx.isHidden).disposed(by: disposeBag)
        viewModel.isOrder.map({ !$0 }).bind(to: btnAgreePrivacy.rx.isHidden).disposed(by: disposeBag)
        viewModel.isOrder.map({ !$0 }).bind(to: lblPrivacy.rx.isHidden).disposed(by: disposeBag)
        viewModel.isOrder.map({ !$0 }).bind(to: buttonCash.rx.isHidden).disposed(by: disposeBag)
        viewModel.isOrder.map({ !$0 }).bind(to: viewCheckbox.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.isAddressHidden.subscribe(onNext: { [weak self] isHidden in
            self?.viewsAddress.forEach({ $0.isHidden = isHidden })
            if isHidden {
                self?.constrTopLblPrivacyNoAddress.priority = UILayoutPriority(rawValue: 999)
                self?.constrTopBtnPrivacyNoAddress.priority = UILayoutPriority(rawValue: 999)
                self?.constrTopLblPrivacyWithAddress.priority = UILayoutPriority(rawValue: 250)
                self?.constrTopBtnPrivacyWithAddress.priority = UILayoutPriority(rawValue: 250)
                self?.view.layoutIfNeeded()
            }
        }).disposed(by: disposeBag)
        
        viewModel.titleCashButton.bind(to: buttonCash.rx.title()).disposed(by: disposeBag)
        
    }
    
    var didLoad = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !didLoad{
            didLoad = true
            views.forEach({ $0.dropShadow() })
        }
        
    }
    
    private func disablingEmoji(){
        
        txtFullname.rx.controlEvent([.editingDidEndOnExit]).subscribe(onNext: { [weak self] _ in
            self?.txtPhone.becomeFirstResponder()
        }).disposed(by: disposeBag)
        
        txtPhone.rx.controlEvent([.editingDidEndOnExit]).subscribe(onNext: { [weak self] _ in
            self?.txtEmail.becomeFirstResponder()
        }).disposed(by: disposeBag)
        
        txtStreet.rx.controlEvent([.editingDidEndOnExit]).subscribe(onNext: { [weak self] _ in
            self?.txtStreetNum.becomeFirstResponder()
        }).disposed(by: disposeBag)
        
        txtEntranceCode.rx.controlEvent([.editingDidEndOnExit]).subscribe(onNext: { [weak self] _ in
            self?.txtApartment.becomeFirstResponder()
        }).disposed(by: disposeBag)
        
        txtStreetNum.rx.controlEvent([.editingDidEndOnExit]).subscribe(onNext: { [weak self] _ in
            self?.txtEntranceCode.becomeFirstResponder()
        }).disposed(by: disposeBag)
        
        txtFullname.rx.text.orEmpty
        .scan("") { prev, new -> String in
            if new.containsEmoji{
                return prev ?? ""
            }else{
                return new
            }
        }.subscribe(txtFullname.rx.text).disposed(by: disposeBag)
        
        txtEmail.rx.text.orEmpty
        .scan("") { prev, new -> String in
            if new.containsEmoji{
                return prev ?? ""
            }else{
                return new
            }
        }.subscribe(txtEmail.rx.text).disposed(by: disposeBag)
        
        txtPhone.rx.text.orEmpty
            .scan("") { prev, new -> String in
                if !new.isEmpty && Int(new) == nil {
                    return prev ?? ""
                }else{
                    return new
                }
            }.subscribe(txtPhone.rx.text).disposed(by: disposeBag)
        
        txtCity.rx.text.orEmpty
        .scan("") { prev, new -> String in
            if new.containsEmoji{
                return prev ?? ""
            }else{
                return new
            }
        }.subscribe(txtCity.rx.text).disposed(by: disposeBag)
        
        txtStreet.rx.text.orEmpty
        .scan("") { prev, new -> String in
            if new.containsEmoji{
                return prev ?? ""
            }else{
                return new
            }
        }.subscribe(txtStreet.rx.text).disposed(by: disposeBag)
        
        txtEntranceCode.rx.text.orEmpty
        .scan("") { prev, new -> String in
            if new.containsEmoji{
                return prev ?? ""
            }else{
                return new
            }
        }.subscribe(txtEntranceCode.rx.text).disposed(by: disposeBag)
        
        txtStreetNum.rx.text.orEmpty
        .scan("") { prev, new -> String in
            if new.containsEmoji{
                return prev ?? ""
            }else{
                return new
            }
        }.subscribe(txtStreetNum.rx.text).disposed(by: disposeBag)
        
    }
    
    private func setBorderForInvalidFields(_ fields: [UITextField]){
        
        [txtCity, txtPhone, txtEmail, txtStreet, txtFullname, txtStreetNum].forEach { txt in
            UIView.animate(withDuration: 0.2, animations: {
                txt?.superview?.borderColor = fields.contains(txt ?? UITextField()) ? .red : .clear
                txt?.superview?.borderWidth = fields.contains(txt ?? UITextField()) ? 1 : 0
            })
        }
        
    }
    
}

import CoreLocation
extension AddressDetailsViewModel {
    func coordinatesFromAddress() -> Observable<CLLocation?> {
        
        Loader.show()
        
        return Observable.create { observer in
            
            let address = "\(User.currentUser?.city ?? ""), \(User.currentUser?.street ?? ""), \(User.currentUser?.streetNum ?? "")"
            
            let geo = CLGeocoder()
            geo.geocodeAddressString(address) { placemarks, error in
                
                Loader.dismiss()
                
                if placemarks == nil || placemarks?.count == 0 || error != nil {
                    observer.onNext(nil)
                    return
                }
                
                observer.onNext(placemarks?[0].location)
                
            }
            
            return Disposables.create()
        }
    }
}
