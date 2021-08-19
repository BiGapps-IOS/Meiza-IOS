//
//  SummaryVC.swift
//  Meiza
//
//  Created by Denis Windover on 13/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxAnimated


//MARK: - VIEWMODEL
class SummaryViewModel {
    
    let disposeBag         = DisposeBag()
    var summary            = BehaviorRelay<Double>(value: 0)
    var existComment       = BehaviorRelay<String?>(value: nil)
    var newComment         = BehaviorRelay<String?>(value: nil)
    var deliveryTime       = BehaviorRelay<Week.Time?>(value: nil)
    var deliveryType       = BehaviorRelay<String>(value: AppData.shared.shop.orderTypes.count == 1 ? AppData.shared.shop.orderTypes.first! : "delivery")
    var deliveryTypeTitle  = BehaviorRelay<String>(value: ":זמני משלוחים".localized)
    var callSupport        = PublishSubject<Void>()
    var callSupportTitle   = BehaviorRelay<String>(value: "לרשותכם תמיד: \(AppData.shared.shop.phone2 ?? "")")
    var deliveryTypeDidTap = PublishSubject<String>()
    var goNext             = PublishSubject<Void>()
    var pickerDatasource   = BehaviorRelay<[Any]>(value: [])
    var clearDeliveryTime  = PublishSubject<String?>()
    var timeDidChoose      = PublishSubject<Int>()
    var openDeliveryDate   = PublishSubject<Void>()
    var deliveryDate       = BehaviorRelay<String?>(value: nil)
    var comment2Height     = BehaviorRelay<CGFloat>(value: WIDTH / 7.5)
    var newComment2        = BehaviorRelay<String?>(value: nil)
    var existComment2      = BehaviorRelay<String?>(value: nil)
    var defaultDeliveryDateAndTime: (delivery:(date: String?, time: Week.Time?)?, pickup:(date: String?, time: Week.Time?)?)
    var isPickupHidden     = BehaviorRelay<Bool>(value: !AppData.shared.shop.orderTypes.contains(where: { $0 == "pickup" }))
    var isDeliveryHidden   = BehaviorRelay<Bool>(value: !AppData.shared.shop.orderTypes.contains(where: { $0 == "delivery" }))
    var deliveryCost       = BehaviorRelay<Double>(value: 0.0)
    var isDateAndTimeHidden: Observable<Bool>
    var isDeliveryCostWillUpdateHidden: Observable<Bool>
    var branch: Branch?
    
    init(_ branch: Branch?){
        
        self.branch = branch
        
        isDeliveryCostWillUpdateHidden = Observable.just(AppData.shared.shop.deliveryZones.count == 0)
        
        isDateAndTimeHidden = deliveryType.map({ _deliveryType -> Bool in
            return _deliveryType == "delivery" && AppData.shared.shop.withoutFutureDelivery || _deliveryType == "pickup" && AppData.shared.shop.withoutFuturePickup
        })
        
        defaultDeliveryDateAndTime = getDefaultValuesForDeliveryAndPickupDates()
        
        deliveryType.map({ $0 == "delivery" ? WIDTH / 7.5 : 0 }).bind(to: comment2Height).disposed(by: disposeBag)
        
        openDeliveryDate
            .map({ [unowned self] _ in self.deliveryType.value })
            .flatMap({ AlertCoordinator.shared.calendar($0) })
            .map({ [weak self] _date -> String? in
                if self?.deliveryDate.value != _date {
                    self?.deliveryTime.accept(nil)
                }
                return _date
            }).bind(to: deliveryDate).disposed(by: disposeBag)
        
        Observable.combineLatest(deliveryType, deliveryDate){ _deliveryType, _deliveryDate in
            
            var arr:[Any] = [Any]()
            arr.append("בחר".localized)
            
            if _deliveryType == "pickup" {
                AppData.shared.shop.pickupTimes.forEach { _time in
                    if Date(timeIntervalSince1970: _time.date).formattedFullDateString == _deliveryDate {
                        arr.append(_time)
                    }
                }
            }else{
                AppData.shared.shop.deliveryTimes.forEach { _time in
                    if Date(timeIntervalSince1970: _time.date).formattedFullDateString == _deliveryDate {
                        arr.append(_time)
                    }
                }
            }
            
            return arr
        }.filter({ [unowned self] _ in self.deliveryDate.value != nil }).bind(to: pickerDatasource).disposed(by: disposeBag)
        
        deliveryType.map({ _ in return nil }).bind(to: clearDeliveryTime).disposed(by: disposeBag)
        deliveryType.map({ _ in return nil }).bind(to: deliveryDate).disposed(by: disposeBag)
        
        deliveryType.subscribe(onNext: { [unowned self] type in
            if type == "delivery" {
                if let defaultDelivery = self.defaultDeliveryDateAndTime.delivery {
                    self.deliveryDate.accept(defaultDelivery.date)
                    self.deliveryTime.accept(defaultDelivery.time)
                }
            }else{
                if let defaultPickup = self.defaultDeliveryDateAndTime.pickup {
                    self.deliveryDate.accept(defaultPickup.date)
                    self.deliveryTime.accept(defaultPickup.time)
                }
            }
        }).disposed(by: disposeBag)
        
        deliveryType.map({ $0 == "delivery" ? "זמני משלוחים:" .localized: "זמני איסוף:".localized }).bind(to: deliveryTypeTitle).disposed(by: disposeBag)
        
        clearDeliveryTime.map({ _ in return nil }).bind(to: deliveryTime).disposed(by: disposeBag)
        
        deliveryType.map({ $0 == "delivery" ? (AppData.shared.overallPrice.value.withCoupon + (AppData.shared.shop.deliveryZones.count == 0 ? AppData.shared.deliveryCost : 0.0)) : AppData.shared.overallPrice.value.withCoupon }).bind(to: summary).disposed(by: disposeBag)
        
        existComment.accept(User.currentUser?.comment ?? "הוספת הערה להזמנה".localized)
        
        existComment2.accept(User.currentUser?.comment2 ?? "הוספת הערה לשליח".localized)
        
        deliveryTypeDidTap.bind(to: deliveryType).disposed(by: disposeBag)
        
        callSupport.subscribe(onNext: { _ in
            guard let phone = AppData.shared.shop.phone2, let url = URL(string: "tel:\(phone)") else{ return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }).disposed(by: disposeBag)
        
        timeDidChoose.map({ [weak self] row in self?.pickerDatasource.value[row] }).map({ $0 as? Week.Time }).bind(to: deliveryTime).disposed(by: disposeBag)
        
        goNext
            .filter({ AppData.shared.shop.orderTypes.count > 0 })
            .subscribe(onNext: { [unowned self] _ in
                
                var deliveryTime: Week.Time?
                
                switch self.isFutureOrdersAvailable() {
                case true:
                    guard let _deliveryTime = self.deliveryTime.value else{
                        let toast = "נא לבחור זמן משלוח/איסוף!".localized
                        toast.toast()
                        return
                    }
                    
                    deliveryTime = _deliveryTime
                    
                case false:
                    deliveryTime = nil
                }
                
                if self.deliveryType.value == "delivery" && AppData.shared.overallPrice.value.withoutCoupon < Double(AppData.shared.shop.minimalOrder) {
                    AlertCoordinator.shared.minimumErrorOrder()
                    return
                }
                
                User.currentUser?.comment = self.newComment.value != "הוספת הערה להזמנה".localized ? self.newComment.value : nil
                User.currentUser?.comment2 = self.newComment2.value != "הוספת הערה לשליח".localized ? self.newComment2.value : nil
                Coordinator.shared.pushAddressDetails(NewOrder(orderType: self.deliveryType.value, deliveryTime: deliveryTime, branch: branch))
                
                
            }).disposed(by: disposeBag)
        
    }
    
    func deliveryCostCheck(){
        if !AppData.shared.shop.isAreaDelivery {
            Observable.just(Double(AppData.shared.deliveryCost)).bind(to: deliveryCost).disposed(by: disposeBag)
        }    }
    
    private func isFutureOrdersAvailable() -> Bool {
        return self.deliveryType.value == "delivery" && !AppData.shared.shop.withoutFutureDelivery || self.deliveryType.value == "pickup" && !AppData.shared.shop.withoutFuturePickup
    }
    
    func getDefaultValuesForDeliveryAndPickupDates() -> (delivery:(date: String?, time: Week.Time?)?, pickup:(date: String?, time: Week.Time?)?) {
        
        let deliveryDates = AppData.shared.shop.deliveryTimes.sorted(by: { $0.date < $1.date })
        let pickupDates = AppData.shared.shop.pickupTimes.sorted(by: { $0.date < $1.date })
        
        var delivery: (date: String?, time: Week.Time?)?
        var pickup: (date: String?, time: Week.Time?)?
        
        if let deliveryDate = deliveryDates.first {
            delivery = (date: Date(timeIntervalSince1970: deliveryDate.date).formattedFullDateString, time: deliveryDate)
        }
        if let pickupDate = pickupDates.first {
            pickup = (date: Date(timeIntervalSince1970: pickupDate.date).formattedFullDateString, time: pickupDate)
        }
        
        return (delivery: delivery, pickup: pickup)
        
    }
    
}

//MARK: - VIEW
class SummaryVC: BaseVC {
    
    
    @IBOutlet var views: [UIView]!
    @IBOutlet weak var lblSummary: UILabel!
    @IBOutlet weak var txtViewComment: UITextView!
    @IBOutlet weak var txtViewComment2: UITextView!
    @IBOutlet weak var constrHeightComment2: NSLayoutConstraint!
    
    @IBOutlet weak var txtDeliveryTime: UITextField!
    @IBOutlet weak var lblPickup: UILabel!
    @IBOutlet weak var ivPickup: UIImageView!
    @IBOutlet weak var btnPickup: UIButton!
    @IBOutlet weak var lblDelivery: UILabel!
    @IBOutlet weak var ivDelivery: UIImageView!
    @IBOutlet weak var btnDelivery: UIButton!
    @IBOutlet weak var btnNext: UIButton!{
        didSet{
            btnNext.setTitleColor(AppData.shared.mainColor, for: .normal)
            btnNext.borderColor = AppData.shared.mainColor
        }
    }
    @IBOutlet weak var lblDeliveryTimeTitle: UILabel!
    @IBOutlet weak var btnOpenDeliveryTime: UIButton!
    
    @IBOutlet weak var btnOpenDeliveryDate: UIButton!
    @IBOutlet weak var txtDeliveryDate: UITextField!
    @IBOutlet weak var viewPrice: UIView!{
        didSet{ viewPrice.backgroundColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var lblOrderSummaryTitle: UILabel!{
        didSet{ lblOrderSummaryTitle.text = AppData.shared.paymentDescription }
    }
    
    
    @IBOutlet weak var viewPickup: UIView!
    @IBOutlet weak var lblDeliveryCost: UILabel!
    
    @IBOutlet weak var viewDate: UIView!
    @IBOutlet weak var viewTime: UIView!
    @IBOutlet weak var constrTopDeliveryCheckbox: NSLayoutConstraint!
    @IBOutlet weak var constrTopPickupCheckbox: NSLayoutConstraint!
    @IBOutlet weak var lblDeliveryCostWillUpdate: UILabel!
    @IBOutlet weak var viewDeliveryCost: UIView!{
        didSet{ viewDeliveryCost.alpha = AppData.shared.shop.isAreaDelivery ? 0 : 1 }
    }
    @IBOutlet weak var viewDelivery: UIView!
    
    
    
    var viewModel: SummaryViewModel!
    
    var didLoad = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !didLoad{
            didLoad = true
            views.forEach({ $0.dropShadow() })
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] _ in
            guard let `self` = self else { return }
            if self.txtViewComment.isFirstResponder && self.txtViewComment.text == "הוספת הערה להזמנה".localized {
                Observable<String?>.just("").asObservable().subscribe(self.txtViewComment.rx.text).disposed(by: self.disposeBag)
            }
            if self.txtViewComment2.isFirstResponder && self.txtViewComment2.text == "הוספת הערה לשליח".localized {
                Observable<String?>.just("").asObservable().subscribe(self.txtViewComment2.rx.text).disposed(by: self.disposeBag)
            }
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            guard let `self` = self else { return }
            if self.txtViewComment.text.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                Observable<String?>.just("הוספת הערה להזמנה".localized).asObservable().subscribe(self.txtViewComment.rx.text).disposed(by: self.disposeBag)
            }
            if self.txtViewComment2.text.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                Observable<String?>.just("הוספת הערה לשליח".localized).asObservable().subscribe(self.txtViewComment2.rx.text).disposed(by: self.disposeBag)
            }
        }
        
        let inputPickerView = DWInputPicker.getFromNib()
        txtDeliveryTime.inputView = inputPickerView
        
        //MARK: - OUTPUTS
        btnOpenDeliveryDate.rx.tap.bind(to: viewModel.openDeliveryDate).disposed(by: disposeBag)
        txtViewComment.rx.text.bind(to: viewModel.newComment).disposed(by: disposeBag)
        txtViewComment2.rx.text.bind(to: viewModel.newComment2).disposed(by: disposeBag)
        btnPickup.rx.tap.map({ "pickup" }).bind(to: viewModel.deliveryType).disposed(by: disposeBag)
        btnDelivery.rx.tap.map({ "delivery" }).bind(to: viewModel.deliveryType).disposed(by: disposeBag)
        btnNext.rx.tap.bind(to: viewModel.goNext).disposed(by: disposeBag)
        inputPickerView.picker.rx.itemSelected.map({ $0.row }).bind(to: viewModel.timeDidChoose).disposed(by: disposeBag)
        inputPickerView.btnChoose.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.view.endEditing(true)
        }).disposed(by: disposeBag)
        
        btnOpenDeliveryTime.rx.tap.subscribe(onNext: { [weak self] _ in
            let message = "נא לבחור תאריך!".localized
            if self?.viewModel.deliveryDate.value == nil {
                message.toast()
                return
            }
            inputPickerView.picker.selectRow(0, inComponent: 0, animated: false)
            self?.txtDeliveryTime.becomeFirstResponder()
        }).disposed(by: disposeBag)
        
        txtViewComment.rx.text.orEmpty
            .scan("") { prev, new -> String in
                if new.containsEmoji || new.count > 255{
                    return prev ?? ""
                }else{
                    return new
                }
            }.subscribe(txtViewComment.rx.text).disposed(by: disposeBag)
        
        txtViewComment2.rx.text.orEmpty
            .scan("") { prev, new -> String in
                if new.containsEmoji || new.count > 255{
                    return prev ?? ""
                }else{
                    return new
                }
            }.subscribe(txtViewComment2.rx.text).disposed(by: disposeBag)
        
        //MARK: - INPUTS
        viewModel.summary.map({ $0.clean }).bind(to: lblSummary.rx.text).disposed(by: disposeBag)
        viewModel.existComment.subscribe(txtViewComment.rx.text).disposed(by: disposeBag)
        viewModel.existComment2.subscribe(txtViewComment2.rx.text).disposed(by: disposeBag)
        viewModel.deliveryType.subscribe(onNext: { [weak self] _type in
            self?.ivPickup.image = _type == "pickup" ? UIImage(named: "blue_chekbox")?.imageWithColor(color1: AppData.shared.mainColor) : nil
            self?.ivDelivery.image = _type == "pickup" ? nil : UIImage(named: "blue_chekbox")?.imageWithColor(color1: AppData.shared.mainColor)
            self?.lblPickup.backgroundColor = _type == "pickup" ? AppData.shared.mainColor : .clear
            self?.lblDelivery.backgroundColor = _type == "pickup" ? .clear : AppData.shared.mainColor
            self?.lblPickup.textColor = _type == "pickup" ? .white : .black
            self?.lblDelivery.textColor = _type == "pickup" ? .black : .white
        }).disposed(by: disposeBag)
        
        viewModel.clearDeliveryTime.subscribe(txtDeliveryTime.rx.text).disposed(by: disposeBag)
        
        viewModel.deliveryTime.map { [unowned self] _time in
            if let time = _time {
                if self.isDateForNow(time) {
                    return "עכשיו".localized
                }
            }
            return _time?.from_to
        }.subscribe(txtDeliveryTime.rx.text).disposed(by: disposeBag)
        
        viewModel.deliveryTime.map { [unowned self] _time in
            if let time = _time {
                if self.isDateForNow(time) {
                    return "עכשיו".localized
                }
            }
            return nil
        }.filter({ $0 != nil }).subscribe(txtDeliveryDate.rx.text).disposed(by: disposeBag)
        
        viewModel.pickerDatasource.bind(to: inputPickerView.picker.rx.itemTitles) { _, weekday in
            return weekday is Week.Time ? (weekday as? Week.Time)?._from_to : weekday as? String
        }
        .disposed(by: disposeBag)
        
        viewModel.deliveryTypeTitle.bind(to: lblDeliveryTimeTitle.rx.animated.fade(duration: 0.5).text).disposed(by: disposeBag)
        
        viewModel.deliveryDate.bind(to: txtDeliveryDate.rx.text).disposed(by: disposeBag)
        
        viewModel.comment2Height.bind(to: constrHeightComment2.rx.animated.layout(duration: 0.5).constant).disposed(by: disposeBag)
        
        viewModel.isPickupHidden.bind(to: viewPickup.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.isDeliveryHidden.bind(to: viewDelivery.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.deliveryCost.map({ $0.clean }).bind(to: lblDeliveryCost.rx.text).disposed(by: disposeBag)
        
        viewModel.isDateAndTimeHidden.subscribe(onNext: { [weak self] _isHidden in
            self?.viewDate.isHidden = _isHidden
            self?.viewTime.isHidden = _isHidden
            self?.constrTopPickupCheckbox.priority = _isHidden ? UILayoutPriority(1000) : UILayoutPriority(750)
            self?.constrTopDeliveryCheckbox.priority = _isHidden ? UILayoutPriority(1000) : UILayoutPriority(750)
        }).disposed(by: disposeBag)
        
        viewModel.isDeliveryCostWillUpdateHidden.bind(to: lblDeliveryCostWillUpdate.rx.isHidden).disposed(by: disposeBag)
        viewModel.isDeliveryCostWillUpdateHidden.map({ !$0 }).bind(to: viewDeliveryCost.rx.isHidden).disposed(by: disposeBag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.deliveryCostCheck()
    }
    
    private func isDateForNow(_ date: Week.Time) -> Bool {
        
        let dateStr = Date(timeIntervalSince1970: date.date).formattedFullDateString
        let timeFromStr = date.from
        let timeToStr = date.to
        let fullDateFromStr = "\(timeFromStr) \(dateStr)"
        let fullDateToStr = "\(timeToStr) \(dateStr)"
        
        guard let _dateFrom = fullDateFromStr.toDate, let _dateTo = fullDateToStr.toDate else{ return false }
        
        if Date().timeIntervalSince1970 < _dateTo.timeIntervalSince1970 && Date().timeIntervalSince1970 > _dateFrom.timeIntervalSince1970 {
            return true
        }
        
        return false
    }
    
}

extension String {
    
    var toDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm dd.MM.yy"
        return formatter.date(from: self)
    }
    
}
