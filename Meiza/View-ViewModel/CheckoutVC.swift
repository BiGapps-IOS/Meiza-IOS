//
//  CheckoutVC.swift
//  Meiza
//
//  Created by Denis Windover on 12/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxDataSources
import RxAnimated

//MARK: - VIEWMODEL
class CheckoutViewModel {

    let disposeBag       = DisposeBag()
    var cart:              SharedSequence<DriverSharingStrategy, [ProductSection]>
    var overallPrice     = BehaviorRelay<Double>(value: 0)
    var goNext           = PublishSubject<Void>()
    var deliveryCost     = BehaviorRelay<Double>(value: 0.0)
    var cartProductAmout = BehaviorRelay<Int>(value: 0)
    var couponDidTap     = PublishSubject<Void>()
    var coupon           = BehaviorRelay<Double>(value: 0)
    var isDeliveryCostWillUpdateHidden: Observable<Bool>
    var branches         = BehaviorRelay<[Any]>(value: ["מאיזה סניף תרצה להזמין".localized] + AppData.shared.shop.branches)
    var chosenBranch     = BehaviorRelay<Branch?>(value: nil)
    var branchDidSelect  = PublishSubject<Int>()
    var isBranchesOpen   = BehaviorRelay<Bool>(value: false)
    var branchDidChoose  = PublishSubject<Void>()

    init(){

        isDeliveryCostWillUpdateHidden = Observable.just(AppData.shared.shop.deliveryZones.count == 0)

        cart = AppData.shared.cartProducts.asObservable().map({ $0.filter({ $0.product != nil }) }).map { _cartProducts -> [ProductSection] in
            var sections = [ProductSection]()

            _cartProducts.forEach { _cartProduct in
                if _cartProduct.isChosen {
                    let header = AppData.shared.shop.categories.first(where: { $0.codename == _cartProduct.product?.category})?.name ?? ""
                    if let index = sections.firstIndex(where: { $0.header == header }) {
                        sections[index].items.append(_cartProduct)
                    }else{
                        let section = ProductSection(header: header, items: [_cartProduct])
                        sections.append(section)
                    }
                }
            }
            let sortedSections = sections.sorted { (section1, section2) -> Bool in
                return (section1.items.first?.product?.categoryID ?? 1) < (section2.items.first?.product?.categoryID ?? 1)
            }
            return sortedSections
        }.asDriver(onErrorJustReturn: [])

        AppData.shared._coupon.bind(to: coupon).disposed(by: disposeBag)

        AppData.shared.overallPrice.map({ $0.withCoupon }).bind(to: overallPrice).disposed(by: disposeBag)

        AppData.shared.cartProducts.map({ $0.filter({ $0.product != nil }) }).map({ $0.filter({ $0.amount > 0 && $0.isChosen }).count }).bind(to: cartProductAmout).disposed(by: disposeBag)

        goNext.subscribe(onNext: { [weak self] _ in
            if AppData.shared.shop.branches.count > 1 {
                self?.isBranchesOpen.accept(true)
            }else{
                Coordinator.shared.pushSummary(nil)
            }
        }).disposed(by: disposeBag)

        couponDidTap.subscribe(onNext: { _ in
            AlertCoordinator.shared.coupon()
        }).disposed(by: disposeBag)

        branchDidSelect.withLatestFrom(self.branches) { _row, _branches -> Branch? in
            return _branches[_row] as? Branch
        }.bind(to: chosenBranch).disposed(by: disposeBag)

        branchDidChoose.map({ [unowned self] _ in self.isBranchesOpen.accept(false); return })
            .withLatestFrom(chosenBranch)
            .subscribe(onNext: { _branch in
                if _branch != nil {
                    Coordinator.shared.pushSummary(_branch)
                }
            }).disposed(by: disposeBag)

    }

    func deliveryCostCheck(){
//        Observable.just(Double(AppData.shared.deliveryCost)).bind(to: deliveryCost).disposed(by: disposeBag)
    }

}

//MARK: - VIEWMODEL
class CheckoutVC: BaseVC {


    @IBOutlet weak var tblViewCart: UITableView!
    @IBOutlet weak var btnPayment: UIButton!
    @IBOutlet weak var lblOverallPrice: UILabel!
    @IBOutlet weak var viewCart: UIView!{
        didSet{ viewCart.backgroundColor = AppData.shared.mainColor }
    }

    @IBOutlet weak var lblCartProductsAmount: UILabel!{
        didSet{ lblCartProductsAmount.backgroundColor = AppData.shared.mainColor }
    }

    @IBOutlet weak var lblDeliveryCost: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var btnCoupon: UIButton!
    @IBOutlet weak var viewDeliveryCost: UIView!{
        didSet{ viewDeliveryCost.alpha = AppData.shared.shop.isAreaDelivery ? 0 : 1 }
    }
    @IBOutlet weak var lblDeliveryCostWillUpdate: UILabel!
    @IBOutlet weak var btnChoose: UIButton!{
        didSet{ btnChoose.backgroundColor = AppData.shared.mainColor }
    }

    @IBOutlet weak var pickerBranch: UIPickerView!
    @IBOutlet weak var constrBottomViewBranches: NSLayoutConstraint!


    var viewModel = CheckoutViewModel()

    lazy var dataSource: RxTableViewSectionedReloadDataSource<ProductSection> = {
        let dataSource = RxTableViewSectionedReloadDataSource<ProductSection>(configureCell: { (_, tableView, indexPath, cartProduct) -> CheckoutCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: "CheckoutCell", for: indexPath) as! CheckoutCell
            cell.viewModel = CheckoutCellViewModel(cartProduct)
            return cell
        })

        return dataSource
    }()


    override func viewDidLoad() {
        super.viewDidLoad()

//        configureCoupon()
//
//        tblViewCart.rx.setDelegate(self).disposed(by: disposeBag)
//
//        //MARK: - OUTPUTS
//        btnPayment.rx.tap.bind(to: viewModel.goNext).disposed(by: disposeBag)
//        btnCoupon.rx.tap.bind(to: viewModel.couponDidTap).disposed(by: disposeBag)
//        btnChoose.rx.tap.bind(to: viewModel.branchDidChoose).disposed(by: disposeBag)
//        pickerBranch.rx.itemSelected.map({ $0.row }).bind(to: viewModel.branchDidSelect).disposed(by: disposeBag)
//
//        //MARK: - INPUTS
//        viewModel.cart.drive(tblViewCart.rx.items(dataSource: dataSource)).disposed(by: disposeBag)
//
//        viewModel.overallPrice.map({ $0.clean }).bind(to: lblOverallPrice.rx.animated.fade(duration: 0.5).text).disposed(by: disposeBag)
//
//        viewModel.deliveryCost.map({ $0.clean }).bind(to: lblDeliveryCost.rx.text).disposed(by: disposeBag)
//
//        viewModel.cartProductAmout.map({ $0.toString }).bind(to: lblCartProductsAmount.rx.animated.fade(duration: 0.5).text).disposed(by: disposeBag)
//
//        viewModel.coupon.map({ $0 == 0 }).bind(to: btnCoupon.rx.isUserInteractionEnabled).disposed(by: disposeBag)
//        viewModel.coupon.map({ $0 == 0 ? .clear : UIColor.myBlackOp50 }).bind(to: btnCoupon.rx.backgroundColor).disposed(by: disposeBag)
//
//        viewModel.isDeliveryCostWillUpdateHidden.bind(to: lblDeliveryCostWillUpdate.rx.isHidden).disposed(by: disposeBag)
//        viewModel.isDeliveryCostWillUpdateHidden.map({ !$0 }).bind(to: viewDeliveryCost.rx.isHidden).disposed(by: disposeBag)
//
//        viewModel.branches.bind(to: pickerBranch.rx.itemTitles){ _, branch in
//            return (branch as? Branch)?.name ?? branch as? String
//        }
//        .disposed(by: disposeBag)
//
//        viewModel.isBranchesOpen.skip(1).map({ $0 ? 0 : -220 }).bind(to: constrBottomViewBranches.rx.animated.layout(duration: 0.3).constant).disposed(by: disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.deliveryCostCheck()
    }

}

//MARK: - HELPERS
extension CheckoutVC {

    fileprivate func configureCoupon(){

        if !AppData.shared.shop.withCoupons {
            guard let couponView = stackView.subviews.first(where: { $0.tag == 1000 }) else{ return }
            couponView.isHidden = true
            stackView.removeArrangedSubview(couponView)
        }

    }

}

//MARK: - TABLEVIEW DELEGATE
extension CheckoutVC: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let height = dataSource.sectionModels[section].header.height(withConstrainedWidth: WIDTH-32, font: UIFont(name: "Heebo-Bold", size: 20)!)
        let lbl = UILabel(frame: CGRect(x: 0, y: 0, width: WIDTH-32, height: height))
        lbl.text = dataSource.sectionModels[section].header
        lbl.textAlignment = .right
        lbl.font = UIFont(name: "Heebo-Bold", size: 20)
        lbl.textColor = .white
        return lbl
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

}
