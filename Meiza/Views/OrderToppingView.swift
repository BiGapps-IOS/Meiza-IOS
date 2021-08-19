//
//  OrderToppingView.swift
//  Meiza
//
//  Created by Denis Windover on 27/08/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

class OrderToppingViewModel {
    
    let disposeBag = DisposeBag()
    var name = BehaviorRelay<String?>(value: nil)
    var chosenToppings = BehaviorRelay<[Topping]>(value: [])
    var toppings = BehaviorRelay<[Topping]>(value: [])
    var usedToppings = BehaviorRelay<[UsedTopping]>(value: [])
    var toppingDidTap = PublishSubject<IndexPath>()
    var addToCartDidTap = PublishSubject<Void>()
    var deleteDidTap = PublishSubject<Void>()
    var isDeleteHidden = BehaviorRelay<Bool>(value: true)
    var addToCartButtonTitle = BehaviorRelay<String>(value: "הוסף לסל".localized)
    var productOption        = BehaviorRelay<ProductOption?>(value: nil)
    private var product: Product
    private var isExist = false
    
    
    init(_ orderProduct: OrderProduct) {
        
        self.product = orderProduct.product
        
        Observable.just(orderProduct.product.name).bind(to: name).disposed(by: disposeBag)
        Observable.just(orderProduct.usedToppings).bind(to: usedToppings).disposed(by: disposeBag)
        
    }
    
//    init(_ product: Product, tag: Int){
//
//        self.product = product
//
//        let index = tag - 1
//
//        NotificationCenter.default.addObserver(forName: NSNotification.Name.init("productOptionsAlert"), object: nil, queue: .main) { [weak self] n in
//            DispatchQueue.main.async {
//                if (n.object as? Int) == tag { self?.confirmProductOption() }
//            }
//        }
//
//        if let existToppings = AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.toppings, existToppings.count > 0 {
//
//            if let existTopping = existToppings[safe: index] {
//                chosenToppings.accept(existTopping)
//                isExist = true
//                isDeleteHidden.accept(false)
//            }
//        }
//
//        if isExist {
//            addToCartButtonTitle.accept("הוסף עוד פריט מסוג זה")
//        }
//
//        Observable.just("\(product.name)\n\(product.toppingsDescription.trimmingCharacters(in: .whitespacesAndNewlines))").bind(to: name).disposed(by: disposeBag)
//        Observable.just(product.toppings).bind(to: toppings).disposed(by: disposeBag)
//
//        toppingDidTap.map({ (product.toppings)[$0.row] }).subscribe(onNext: { [weak self] _topping in
//
//            if self?.chosenToppings.value.contains(_topping) == true {
//                self?.chosenToppings.accept((self?.chosenToppings.value ?? []).filter({ $0 != _topping }))
//            }else{
//                if self?.chosenToppings.value.count == product.maxToppings {
//                    SHOW_TOAST("כמות התוספות המקסימלית למוצר זה \(product.maxToppings ?? 1)")
//                }else{
//                    self?.chosenToppings.accept((self?.chosenToppings.value ?? []) + [_topping])
//                }
//
//            }
//
//            if self?.isExist == true {
//                AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.toppings[tag - 1] = self?.chosenToppings.value ?? []
//                AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value)
//                CartProduct.saveCartProducts(AppData.shared.cartProducts.value)
//            }
//
//        }).disposed(by: disposeBag)
//
//        chosenToppings.subscribe(onNext: { [unowned self] _ in
//            self.toppings.accept(self.toppings.value)
//        }).disposed(by: disposeBag)
//
//        toppingDidTap.debounce(.milliseconds(500), scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] _ in
//
//            if self?.isExist == true {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    AlertCoordinator.shared.productWasAdded("update", imageUrl: product.image)
//                }
//            }
//
//        }).disposed(by: disposeBag)
//
//        toppingDidTap.subscribe(onNext: { _ in
//            AppData.shared.playSound(isProduct: false)
//        }).disposed(by: disposeBag)
//
//        addToCartDidTap.map { [weak self] _ in
//
//            if self?.isExist == false {
//                AppData.shared.playSound()
//                CartProduct.addToCartWithToppings(product, toppings: self?.chosenToppings.value ?? [], option: self?.productOption.value)
//            }
//
//        }.flatMap({ AlertCoordinator.shared.addSameProduct() }).subscribe(onNext: { [weak self] add in
//            if add {
//                (NAV.presentedViewController as? ToppingsAlert)?.viewModel.configure(true)
//                (NAV.presentedViewController as? ToppingsAlert)?.viewDidAppear(false)
//            }else{
//                if self?.isExist == false {
//                    (NAV.presentedViewController as? ToppingsAlert)?.dismiss(completion: nil)
//                }
//            }
//        }).disposed(by: disposeBag)
//
//        deleteDidTap.subscribe(onNext: { [weak self] _ in
//            AlertCoordinator.shared.removeProductFromCart { [weak self] in
//                if self?.isExist == true {
//                    CartProduct.removeTopping(product, index: index)
//                    (NAV.presentedViewController as? ToppingsAlert)?.viewModel.configure(dismiss: true)
//                }
//            }
//        }).disposed(by: disposeBag)
//
//    }
//
//    private func confirmProductOption(){
//
//        if product.productOptions.count > 0 && productOption.value == nil && !isExist{
//            AlertCoordinator.shared.productOptions(product.productOptions, title: product.optionsDescription).bind(to: productOption).disposed(by: disposeBag)
//        }
//
//    }
    
}


class OrderToppingView: UIView {

    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var lblTitle: UILabel!{
        didSet{ lblTitle.textColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var tblToppings: UITableView!
    
    @IBOutlet weak var btnAddToCart: UIButton!{
        didSet{ btnAddToCart.backgroundColor = AppData.shared.mainColor }
    }
    
    @IBOutlet weak var btnDelete: UIButton!
    
    
    var disposeBag = DisposeBag()
    var viewModel: OrderToppingViewModel!
    
    deinit {
        print("-------DEINIT---------")
        print(self)
        print("-------DEINIT---------")
    }
    
//    init(frame:CGRect, product: Product, tag: Int) {
//        super.init(frame: frame)
//        self.tag = tag
//        viewModel = OrderToppingViewModel(product, tag: tag)
//        commonInit()
//        configureProduct()
//    }
    
    init(frame:CGRect, orderProduct: OrderProduct) {
        super.init(frame: frame)
        self.tag = 1000
        viewModel = OrderToppingViewModel(orderProduct)
        commonInit()
        configureOrderProduct()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func configureOrderProduct(){
        
        tblToppings.register(UINib(nibName: "ToppingCell", bundle: nil), forCellReuseIdentifier: "ToppingCell")
        
        viewModel.usedToppings.bind(to: tblToppings.rx.items(cellIdentifier: "ToppingCell", cellType: ToppingCell.self)){ row, usedTopping, cell in
            cell.lblName.text = usedTopping.name
            cell.lblPrice.text = usedTopping.total == 0 ? "ללא עלות".localized : "₪\(usedTopping.total.clean)"
            cell.viewCheckbox.isHidden = true
        }.disposed(by: disposeBag)
        
        viewModel.name.map { name in
            return "\(name ?? "")\n"
        }.bind(to: lblTitle.rx.text).disposed(by: disposeBag)

        
    }
    
//    private func configureProduct(){
//
//        tblToppings.register(UINib(nibName: "ToppingCell", bundle: nil), forCellReuseIdentifier: "ToppingCell")
//
//        tblToppings.rx.itemSelected.bind(to: viewModel.toppingDidTap).disposed(by: disposeBag)
//        btnAddToCart.rx.tap.bind(to: viewModel.addToCartDidTap).disposed(by: disposeBag)
//        btnDelete.rx.tap.bind(to: viewModel.deleteDidTap).disposed(by: disposeBag)
//
//        viewModel.toppings.bind(to: tblToppings.rx.items(cellIdentifier: "ToppingCell", cellType: ToppingCell.self)){ [unowned self] row, topping, cell in
//            cell.lblName.text = topping.name
//            cell.lblPrice.text = topping.price == 0 ? "ללא עלות" : "₪\(topping.price.clean)"
//
//            cell.viewCheckbox.borderColor = self.viewModel.chosenToppings.value.contains(topping) ? .clear : .black
//            cell.viewCheckbox.backgroundColor = self.viewModel.chosenToppings.value.contains(topping) ? AppData.shared.mainColor : .clear
//
//        }.disposed(by: disposeBag)
//
//        viewModel.name.map { [weak self] name in
//            return "\(name ?? "")\nמס׳ \(self?.tag ?? 0)"
//        }.bind(to: lblTitle.rx.text).disposed(by: disposeBag)
//
//        viewModel.isDeleteHidden.bind(to: btnDelete.rx.isHidden).disposed(by: disposeBag)
//
//        viewModel.addToCartButtonTitle.bind(to: btnAddToCart.rx.title()).disposed(by: disposeBag)
//
//    }
    
    
    
    private func commonInit(){
        Bundle.main.loadNibNamed("OrderToppingView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
    }

}
