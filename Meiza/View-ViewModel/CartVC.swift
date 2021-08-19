//
//  CartVC.swift
//  Meiza
//
//  Created by Denis Windover on 30/08/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxDataSources
import RxAnimated


class CartViewModel {
    
    let disposeBag = DisposeBag()
    var isChosenAll                 = BehaviorRelay<Bool>(value: false)
    var isChosenAllDidTap           = PublishSubject<Void>()
    var cart:                         SharedSequence<DriverSharingStrategy, [ProductSection]>
    var cartProductDidSelect        = PublishSubject<CartProduct>()
    var isCartEmptyHidden           = BehaviorRelay<Bool>(value: true)
    var cartProductAmout            = BehaviorRelay<Int>(value: 0)
    var overallPrice                = BehaviorRelay<Double>(value: 0)
    var deleteCartProductDidTap     = PublishSubject<CartProduct?>()
    var deliveryCost                = BehaviorRelay<Double>(value: 0.0)
    var coupon                      = BehaviorRelay<Double>(value: 0)
    var couponDidTap                = PublishSubject<Void>()
    var isDeliveryCostWillUpdateHidden: Observable<Bool>
    var branches                    = BehaviorRelay<[Any]>(value: ["מאיזה סניף תרצה להזמין".localized] + AppData.shared.shop.branches)
    var chosenBranch                = BehaviorRelay<Branch?>(value: nil)
    var branchDidSelect             = PublishSubject<Int>()
    var isBranchesOpen              = BehaviorRelay<Bool>(value: false)
    var branchDidChoose             = PublishSubject<Void>()
    var goNext                      = PublishSubject<Void>()
    
    init(){
        
        isDeliveryCostWillUpdateHidden = Observable.just(AppData.shared.shop.deliveryZones.count == 0)
        
        AppData.shared.cartProducts.map({ $0.filter({ $0.product != nil }) }).map({ !$0.contains(where: { $0.isChosen == false }) }).bind(to: isChosenAll).disposed(by: disposeBag)
        
        AppData.shared.cartProducts.map({ $0.filter({ $0.product != nil }) }).map({ !$0.isEmpty }).bind(to: isCartEmptyHidden).disposed(by: disposeBag)
        
        AppData.shared.cartProducts.map({ $0.filter({ $0.product != nil }) }).map({ $0.filter({ $0.amount > 0 && $0.isChosen }).count }).bind(to: cartProductAmout).disposed(by: disposeBag)
        
        AppData.shared.overallPrice.map({ $0.withCoupon }).bind(to: overallPrice).disposed(by: disposeBag)
        
        AppData.shared._coupon.bind(to: coupon).disposed(by: disposeBag)
        
        cart = AppData.shared.cartProducts.map({ $0.filter({ $0.product != nil }) }).asObservable().map { _cartProducts -> [ProductSection] in
            var sections = [ProductSection]()
            
            _cartProducts.forEach { _cartProduct in
                let header = AppData.shared.shop.categories.first(where: { $0.codename == _cartProduct.product?.category})?.name ?? ""
                if let index = sections.firstIndex(where: { $0.header == header }) {
                    sections[index].items.append(_cartProduct)
                }else{
                    let section = ProductSection(header: header, items: [_cartProduct])
                    sections.append(section)
                }
            }
            
            let sortedSections = sections.sorted { (section1, section2) -> Bool in
                return (section1.items.first?.product?.categoryID ?? 1) < (section2.items.first?.product?.categoryID ?? 1)
            }
            return sortedSections
        }.asDriver(onErrorJustReturn: [])
        
        isChosenAllDidTap.map({ [unowned self] _ in self.isChosenAll.value }).subscribe(onNext: { lastValue in
            CartProduct.updateIsChosenAllObjects(!lastValue)
        }).disposed(by: disposeBag)
        
        cartProductDidSelect.filter({ $0.productID != AppData.shared.currentActiveProduct.value?.id && $0.product?.type != .pack }).map({ $0.product }).filter({ $0?.toppings.count == 0 }).bind(to: AppData.shared.currentActiveProduct).disposed(by: disposeBag)
        
        cartProductDidSelect.filter({ $0.productID != AppData.shared.currentActiveProduct.value?.id && $0.product?.type != .pack }).map({ $0.product }).filter({ ($0?.toppings.count ?? 0) > 0 }).subscribe(onNext: { _prod in
            guard let _prod = _prod else{ return }
            AlertCoordinator.shared.toppings(_prod)
        }).disposed(by: disposeBag)
        
        cartProductDidSelect.filter({ $0.product?.type == .pack }).subscribe(onNext: { _pack in
            Coordinator.shared.editPack(_pack)
        }).disposed(by: disposeBag)
        
        deleteCartProductDidTap.subscribe(onNext: { _cartProduct in
            guard let cartProduct = _cartProduct else{ return }
            AlertCoordinator.shared.removeProductFromCart {
                CartProduct.removeProductFromCart(cartProduct.product, cartProduct: cartProduct)
            }
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
        
    }
    
    func deliveryCostCheck(){
        Observable.just(Double(AppData.shared.deliveryCost)).bind(to: deliveryCost).disposed(by: disposeBag)
        
    }
    
}


class CartVC: BaseVC {
    
    
    @IBOutlet weak var btnCheckbox: UIButton!{
        didSet{ btnCheckbox.imageColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var tblViewCart: UITableView!
    @IBOutlet weak var viewCartEmpty: UIView!
    @IBOutlet weak var btnGoBack: UIButton!
    @IBOutlet weak var lblCartProductsAmount: UILabel!{
        didSet{ lblCartProductsAmount.backgroundColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var lblOverallPrice: UILabel!
    @IBOutlet weak var viewCart: UIView!{
        didSet{ viewCart.backgroundColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var btnPayment: UIButton!
    @IBOutlet weak var lblDeliveryCost: UILabel!
    @IBOutlet weak var viewDeliveryCost: UIView!{
        didSet{ viewDeliveryCost.alpha = AppData.shared.shop.isAreaDelivery ? 0 : 1 }
    }
    @IBOutlet weak var lblDeliveryCostWillUpdate: UILabel!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var constrBottomViewBranches: NSLayoutConstraint!
    @IBOutlet weak var btnChoose: UIButton!{
        didSet{ btnChoose.backgroundColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var pickerBranch: UIPickerView!
    @IBOutlet weak var btnCoupon: UIButton!
    
    
    
    var viewModel = CartViewModel()
    
    lazy var dataSource: RxTableViewSectionedReloadDataSource<ProductSection> = {
        let dataSource = RxTableViewSectionedReloadDataSource<ProductSection>(configureCell: { (_, tableView, indexPath, cartProduct) -> ProductCell2 in
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell2", for: indexPath) as! ProductCell2
            cell.viewModel = ProductCell2ViewModel(cartProduct, product: cartProduct.product!, isCart: true)
            return cell
        })
        
        return dataSource
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCoupon()
        
        dataSource.canEditRowAtIndexPath = { _, _ in
            return true
        }
        tblViewCart.rx.setDelegate(self).disposed(by: disposeBag)
        
        //MARK: - OUTPUTS
        btnPayment.rx.tap.bind(to: viewModel.goNext).disposed(by: disposeBag)
        btnChoose.rx.tap.bind(to: viewModel.branchDidChoose).disposed(by: disposeBag)
        btnCoupon.rx.tap.bind(to: viewModel.couponDidTap).disposed(by: disposeBag)
        
        btnGoBack.rx.tap.subscribe(onNext: { _ in
            Coordinator.shared.popMain()
        }).disposed(by: disposeBag)
        btnCheckbox.rx.tap.bind(to: viewModel.isChosenAllDidTap).disposed(by: disposeBag)
        
        tblViewCart.rx.itemSelected.map({ [unowned self] indexPath in self.dataSource.sectionModels[indexPath.section].items[indexPath.row] }).bind(to: viewModel.cartProductDidSelect).disposed(by: disposeBag)
        
        viewModel.cart.drive(tblViewCart.rx.items(dataSource: dataSource)).disposed(by: disposeBag)
        
        viewModel.isCartEmptyHidden.bind(to: viewCartEmpty.rx.animated.fade(duration: 0.5).isHidden).disposed(by: disposeBag)
        
        pickerBranch.rx.itemSelected.map({ $0.row }).bind(to: viewModel.branchDidSelect).disposed(by: disposeBag)
        
        //MARK: - INPUTS
        viewModel.cartProductAmout.map({ $0.toString }).bind(to: lblCartProductsAmount.rx.animated.fade(duration: 0.5).text).disposed(by: disposeBag)
        
        viewModel.isChosenAll.map({ $0 ? UIImage(named: "blue_chekbox")?.imageWithColor(color1: AppData.shared.mainColor) : nil }).bind(to: btnCheckbox.rx.animated.fade(duration: 0.5).image).disposed(by: disposeBag)
        
        viewModel.overallPrice.map({ $0.clean }).bind(to: lblOverallPrice.rx.animated.fade(duration: 0.5).text).disposed(by: disposeBag)
        
        viewModel.overallPrice.map({ $0 == 0}).bind(to: btnPayment.rx.animated.fade(duration: 0.5).isHidden).disposed(by: disposeBag)
        
        viewModel.deliveryCost.map({ $0.clean }).bind(to: lblDeliveryCost.rx.text).disposed(by: disposeBag)
        
        viewModel.isDeliveryCostWillUpdateHidden.bind(to: lblDeliveryCostWillUpdate.rx.isHidden).disposed(by: disposeBag)
        viewModel.isDeliveryCostWillUpdateHidden.map({ !$0 }).bind(to: viewDeliveryCost.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.branches.bind(to: pickerBranch.rx.itemTitles){ _, branch in
            return (branch as? Branch)?.name ?? branch as? String
        }
        .disposed(by: disposeBag)
        
        viewModel.isBranchesOpen.skip(1).map({ $0 ? 0 : -220 }).bind(to: constrBottomViewBranches.rx.animated.layout(duration: 0.3).constant).disposed(by: disposeBag)
        
        viewModel.coupon.map({ $0 == 0 }).bind(to: btnCoupon.rx.isUserInteractionEnabled).disposed(by: disposeBag)
        viewModel.coupon.map({ $0 == 0 ? .clear : UIColor.myBlackOp50 }).bind(to: btnCoupon.rx.backgroundColor).disposed(by: disposeBag)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.deliveryCostCheck()
    }

}

//MARK: - HELPERS
extension CartVC {

    fileprivate func configureCoupon(){

        if !AppData.shared.shop.withCoupons {
            guard let couponView = stackView.subviews.first(where: { $0.tag == 1000 }) else{ return }
            couponView.isHidden = true
            stackView.removeArrangedSubview(couponView)
        }

    }

}


//MARK: - TABLEVIEW DELEGATE
extension CartVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] (_, _, completionHandler) in
            let cartProductToDelete = self?.dataSource.sectionModels[indexPath.section].items[indexPath.row]
            self?.viewModel.deleteCartProductDidTap.onNext(cartProductToDelete)
            completionHandler(true)
        }
        deleteAction.image = UIImage(named: "trash")
        deleteAction.backgroundColor = .white
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
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
        return dataSource.sectionModels[section].header.height(withConstrainedWidth: WIDTH-32, font: UIFont(name: "Heebo-Bold", size: 20)!)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as? ProductCell2)?.ivProduct.image = nil
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }

}
