//
//  ToppingView.swift
//  Meiza
//
//  Created by Denis Windover on 11/11/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxAnimated


class ToppingViewModel {
    
    let disposeBag               = DisposeBag()
    var name                     = BehaviorRelay<String?>(value: nil)
    var chosenToppings           = BehaviorRelay<[Topping]>(value: [])
    var chosenPizzaToppings      = BehaviorRelay<[PizzaTopping]>(value: [])
    var toppings                 = BehaviorRelay<[Topping]>(value: [])
    var usedToppings             = BehaviorRelay<[UsedTopping]>(value: [])
    var toppingDidTap            = PublishSubject<IndexPath>()
    var addToCartDidTap          = PublishSubject<Void>()
    var deleteDidTap             = PublishSubject<Void>()
    var isDeleteHidden           = BehaviorRelay<Bool>(value: true)
    var addToCartButtonTitle     = BehaviorRelay<String>(value: "הוסף לסל".localized)
    var toppingPicture           = BehaviorRelay<UIImage?>(value: nil)
    
    var activeTopping            = BehaviorRelay<Topping?>(value: nil)
    var tmpPizzaTopping          = BehaviorRelay<PizzaTopping?>(value: nil)
    var pizzaPieceDidTap         = PublishSubject<[Int]>()
    var disactivateToppingDidTap = PublishSubject<Void>()
    var confirmToppingDidTap     = PublishSubject<Void>()
    var productOption            = BehaviorRelay<ProductOption?>(value: nil)
    var confirmedToppings        = BehaviorRelay<[Any]>(value: [])
    var removeToppingDidSelect   = PublishSubject<IndexPath>()
    var level: Level?
    var existLevelProduct: CartProduct?
    
    var product: Product
    private var isExist = false
    
    init(_ orderProduct: OrderProduct) {
        
        self.product = orderProduct.product
        
        Observable.just(orderProduct.product.name).bind(to: name).disposed(by: disposeBag)
        Observable.just(orderProduct.usedToppings).bind(to: usedToppings).disposed(by: disposeBag)
        
    }
    
    init(_ product: Product, tag: Int, level: Level? = nil, existLevelProduct: CartProduct? = nil, isProductForReplacing: Bool = false){
        
        self.product = product
        self.level = level
        self.existLevelProduct = existLevelProduct
    
        let index = tag - 1
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.init("productOptionsAlert"), object: nil, queue: .main) { [weak self] n in
            DispatchQueue.main.async {
                if (n.object as? Int) == tag { self?.confirmProductOption() }
            }
        }

        Observable.combineLatest(productOption, chosenPizzaToppings, chosenToppings){ _productOption, _chosenPizzaToppings, _chosenToppings in
            
            if product.type == .regular {
                return _productOption?.id != -1000 ? (_productOption != nil ? [_productOption!] + _chosenToppings : _chosenToppings) : _chosenToppings
            }else if product.type == .pizza {
                return _productOption?.id != -1000 ? (_productOption != nil ? [_productOption!] + _chosenPizzaToppings : _chosenPizzaToppings) : _chosenPizzaToppings
            }
            
            return []
            
        }.bind(to: confirmedToppings).disposed(by: disposeBag)

        removeToppingDidSelect.withLatestFrom(confirmedToppings) { [weak self] indexPath, _confirmedPizzaToppings -> Bool in
            
            if let _ = _confirmedPizzaToppings[indexPath.row] as? ProductOption {
                return true
            }else{
                
                var id: Int!
                if product.type == .pizza {
                    id = (_confirmedPizzaToppings[indexPath.row] as? PizzaTopping)?.id ?? 0
                }else{
                    id = (_confirmedPizzaToppings[indexPath.row] as? Topping)?.id ?? 0
                }
                
                if self?.isExist == true {
                    if product.type == .pizza {
                        AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.pizzaToppings[tag - 1] = self?.chosenPizzaToppings.value.filter({ $0.id != id }) ?? []
                    }else{
                        AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.toppings[tag - 1] = self?.chosenToppings.value.filter({ $0.id != id }) ?? []
                    }
                    
                    AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value)
                    CartProduct.saveCartProducts(AppData.shared.cartProducts.value)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        AlertCoordinator.shared.productWasAdded("update", imageUrl: product.image)
                    }
                }
                else if existLevelProduct != nil {
                    if product.type == .pizza {
                        if existLevelProduct?.pizzaToppings.index(0) != nil {
                            existLevelProduct?.pizzaToppings[0] = self?.chosenPizzaToppings.value.filter({ $0.id != id }) ?? []
                            AppData.shared.editingPack.accept(AppData.shared.editingPack.value)
                        }
                    }else{
                        if existLevelProduct?.toppings.index(0) != nil {
                            existLevelProduct?.toppings[0] = self?.chosenToppings.value.filter({ $0.id != id }) ?? []
                            AppData.shared.editingPack.accept(AppData.shared.editingPack.value)
                        }
                    }
                    
                }
                
                if product.type == .pizza {
                    self?.chosenPizzaToppings.accept(self?.chosenPizzaToppings.value.filter({ $0.id != id }) ?? [])
                }else{
                    self?.chosenToppings.accept(self?.chosenToppings.value.filter({ $0.id != id }) ?? [])
                }
                
                return false
            }
            
        }.filter({ $0 == true })
        .subscribeOn(MainScheduler.instance)
        .flatMap({ _ in AlertCoordinator.shared.productOptions(product.productOptions, title: product.optionsDescription, level: level) }).subscribe(onNext: { [weak self] option in
            self?.productOption.accept(option)
            
            if self?.isExist == true {
                AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.productOptions[tag - 1] = option
                AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value)
                CartProduct.saveCartProducts(AppData.shared.cartProducts.value)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    AlertCoordinator.shared.productWasAdded("update", imageUrl: product.image)
                }
            }

            AppData.shared.playSound(isProduct: false)
            
        }).disposed(by: disposeBag)

        if product.type == .pizza {
            if let _ = level {
                if let existLevelProduct = existLevelProduct, existLevelProduct.pizzaToppings.count > 0 {
                    if let existPizzaTopping = existLevelProduct.pizzaToppings[safe: index] {
                        chosenPizzaToppings.accept(existPizzaTopping)
                    }
                }
            }else{
                if let existPizzaToppings = AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.pizzaToppings, existPizzaToppings.count > 0 {

                    if let existPizzaTopping = existPizzaToppings[safe: index] {
                        chosenPizzaToppings.accept(existPizzaTopping)
                        isExist = true
                        isDeleteHidden.accept(false)
                    }
                }
            }
            
        }else{
            if let _ = level {
                if let existLevelProduct = existLevelProduct, existLevelProduct.toppings.count > 0 {
                    if let existTopping = existLevelProduct.toppings[safe: index] {
                        chosenToppings.accept(existTopping)
                    }
                }
            }else{
                if let existToppings = AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.toppings, existToppings.count > 0 {
                    
                    if let existTopping = existToppings[safe: index] {
                        chosenToppings.accept(existTopping)
                        isExist = true
                        isDeleteHidden.accept(false)
                    }
                }
            }
            
        }
        
        
        if let _ = level {
            if let existLevelProduct = existLevelProduct, existLevelProduct.productOptions.count > 0 {
                if let existOption = existLevelProduct.productOptions[safe: 0] {
                    productOption.accept(existOption)
                }
            }
        }else{
            if let existPizzaOptions = AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.productOptions, existPizzaOptions.count > 0 {
                
                if let existPizzaOption = existPizzaOptions[safe: index] {
                    productOption.accept(existPizzaOption)
                }

            }
        }
        

        if isExist {
            if product.type == .pizza {
                addToCartButtonTitle.accept("הוסף עוד פיצה".localized)
            }else{
                addToCartButtonTitle.accept("הוסף עוד פריט מסוג זה".localized)
            }
            
        }

        Observable.just(product.toppingsDescription.isEmpty ? product.name : "\(product.name)\n\(product.toppingsDescription.trimmingCharacters(in: .whitespacesAndNewlines))").bind(to: name).disposed(by: disposeBag)
        Observable.just(product.toppings).bind(to: toppings).disposed(by: disposeBag)

        if product.type == .pizza {
            chosenPizzaToppings.subscribe(onNext: { [unowned self] _ in
                self.toppings.accept(self.toppings.value)
            }).disposed(by: disposeBag)
        }else{
            chosenToppings.subscribe(onNext: { [unowned self] _ in
                self.toppings.accept(self.toppings.value)
            }).disposed(by: disposeBag)
        }
        
        addToCartDidTap.map { [weak self] _ in
            
            if let level = level {
                
                if self?.isExist == false {
                    AppData.shared.playSound()
                    if product.type == .pizza {
                        
                        let levelProduct = CartProduct(productID: product.id, amount: 1, unitType: "unit")
                        levelProduct.pizzaToppings.append(self?.chosenPizzaToppings.value ?? [])
                        levelProduct.productOptions.append(self?.productOption.value ?? ProductOption.productOptionNil())
                        var set = AppData.shared.products.value
                        set.insert(product)
                        AppData.shared.products.accept(set)
                        
                        if isProductForReplacing {
                            NotificationCenter.default.post(name: NSNotification.Name("replaceLevelProduct"), object: levelProduct)
                        }else{
                            guard let pack = AppData.shared.currentPack.value else { return }

                            if let _level = pack.levels.first(where: { $0 == level }) {
                                _level.selectedProducts.append(levelProduct)
                                AppData.shared.currentPack.accept(pack)
                            }
                        }
                
                    }else{
                        
                        let levelProduct = CartProduct(productID: product.id, amount: 1, unitType: "unit")
                        levelProduct.toppings.append(self?.chosenToppings.value ?? [])
                        levelProduct.productOptions.append(self?.productOption.value ?? ProductOption.productOptionNil())
                        var set = AppData.shared.products.value
                        set.insert(product)
                        AppData.shared.products.accept(set)
                        
                        if isProductForReplacing {
                            NotificationCenter.default.post(name: NSNotification.Name("replaceLevelProduct"), object: levelProduct)
                        }else{
                            guard let pack = AppData.shared.currentPack.value else { return }

                            if let _level = pack.levels.first(where: { $0 == level }) {
                                _level.selectedProducts.append(levelProduct)
                                AppData.shared.currentPack.accept(pack)
                            }
                        }
                        
                    }
                    
                    NotificationCenter.default.post(name: NSNotification.Name("refreshCartProduct"), object: nil)
                    
                    (NAV.presentedViewController as? ToppingsAlert)?.dismiss(completion: {
                        
                        guard let pack = AppData.shared.currentPack.value else{ return }
                    
                        let isLastLevelProduct = (pack.levels.last?.id == level.id) &&
                            (pack.levels.first(where: { $0 == level })?.productsAmount ?? 0) == AppData.shared.currentPack.value?.levels.first(where: { $0 == level })?.selectedProducts.count ?? 0
                        
                        if (pack.levels.first(where: { $0 == level })?.productsAmount ?? 0) >= pack.levels.first(where: { $0 == level })?.selectedProducts.count ?? 0 {
                            
                            if !isLastLevelProduct {
                                let max = pack.levels.first(where: { $0 == level })?.productsAmount ?? 0
                                let current = pack.levels.first(where: { $0 == level })?.selectedProducts.count ?? 0
                                let next = current + 1
                                var message: String = ""
                                if current == max {
                                    message = "נבחר מוצר 111 מתוך 222".localized.replacingOccurrences(of: "111", with: current.toString).replacingOccurrences(of: "222", with: max.toString)
                                }else{
                                    message = "נבחר מוצר 111 מתוך 222 \nאנא בחר מוצר 333".localized.replacingOccurrences(of: "111", with: current.toString).replacingOccurrences(of: "222", with: max.toString).replacingOccurrences(of: "333", with: next.toString)
                                }
                                if !isProductForReplacing {
                                    AlertCoordinator.shared.toast(text: message)
                                }
                                
                            }
                        }
                        
                    })
                    
                }
                
            }else{
                if self?.isExist == false {
                    AppData.shared.playSound()
                    if product.type == .pizza {
                        CartProduct.addToCartWithPizzaToppings(product, pizzaToppings: self?.chosenPizzaToppings.value ?? [], option: self?.productOption.value ?? ProductOption.productOptionNil())
                    }else{
                        CartProduct.addToCartWithToppings(product, toppings: self?.chosenToppings.value ?? [], option: self?.productOption.value)
                    }
                }
            }
            
        }.filter({ _ in return level == nil }).flatMap({ AlertCoordinator.shared.addSameProduct(product.type == .pizza) }).subscribe(onNext: { [weak self] add in
            if add {
                (NAV.presentedViewController as? ToppingsAlert)?.viewModel.configure(true)
                (NAV.presentedViewController as? ToppingsAlert)?.viewDidAppear(false)
            }else{
                if self?.isExist == false {
                    (NAV.presentedViewController as? ToppingsAlert)?.dismiss(completion: nil)
                }
            }
        }).disposed(by: disposeBag)

        deleteDidTap.subscribe(onNext: { [weak self] _ in
            AlertCoordinator.shared.removeProductFromCart {
                if self?.isExist == true {
                    CartProduct.removeTopping(product, index: index)
                    (NAV.presentedViewController as? ToppingsAlert)?.viewModel.configure(dismiss: true)
                }
            }
        }).disposed(by: disposeBag)

        //////////////////////////////////////////
        
        if product.type == .pizza {
            toppingDidTap.map({ (product.toppings)[$0.row] }).bind(to: activeTopping).disposed(by: disposeBag)

            disactivateToppingDidTap.map({ _ in return nil }).bind(to: activeTopping).disposed(by: disposeBag)
            activeTopping.filter({ $0 == nil }).map({ _ in return nil }).bind(to: tmpPizzaTopping).disposed(by: disposeBag)

            activeTopping.filter({ $0 != nil }).map { [unowned self] topping -> PizzaTopping in
                if let pizzaTopping = self.chosenPizzaToppings.value.first(where: { $0.id == topping?.id }) {
                    return pizzaTopping
                }else{
                    return PizzaTopping(topping: topping!)
                }
            }.bind(to: tmpPizzaTopping).disposed(by: disposeBag)

            pizzaPieceDidTap.withLatestFrom(tmpPizzaTopping) { pieces, _tmpPizzaTopping -> PizzaTopping? in

                var tmp = _tmpPizzaTopping

                if _tmpPizzaTopping?.pieces.containsSameElements(as: pieces) == true {
                    tmp?.pieces.removeAll()
                }else{
                    if pieces.count == 4 {
                        tmp?.pieces = pieces
                    }else{
                        let arr = tmp?.pieces.contains(pieces[0]) == true ? (tmp?.pieces.filter({ $0 != pieces[0] }) ?? []) : (tmp?.pieces ?? []) + pieces
                        tmp?.pieces = arr
                    }
                }

                return tmp
            }.bind(to: tmpPizzaTopping).disposed(by: disposeBag)
            
            confirmToppingDidTap.throttle(.milliseconds(1000), latest: false, scheduler: MainScheduler.instance).map({ [weak self] _ in return self?.chosenPizzaToppings.value ?? [] }).withLatestFrom(tmpPizzaTopping) {  _chosenPizzaToppings, _tmpPizzaTopping -> PizzaTopping? in
                
                if (product.maxToppings == nil || product.maxToppings == 0) && level == nil { return _tmpPizzaTopping }
                
                let maxTopPieces = (product.maxToppings ?? 0) * 4
                let currentToppings = _chosenPizzaToppings.filter({ $0.id != _tmpPizzaTopping?.id })
                let piecesAmount = currentToppings.reduce(_tmpPizzaTopping?.pieces.count ?? 0) { (res, _pizzaTopping) -> Int in
                    return res + _pizzaTopping.pieces.count
                }
                
                if let level = level {
                    if level.toppingsAddPaid == false && piecesAmount > level.toppingsFree*4 {
                        SHOW_TOAST("כמות התוספות המקסימלית לפיצה זאת היא \(level.toppingsFree) וכרגע יש חריגה בכמות!")
                        return nil
                    }
                }
                else if piecesAmount > maxTopPieces {
                    SHOW_TOAST("כמות התוספות המקסימלית לפיצה זאת היא \(product.maxToppings ?? 0) וכרגע יש חריגה בכמות!")
                    return nil
                }
                
                return _tmpPizzaTopping
            }.filter({ $0 != nil }).subscribe(onNext: { [weak self] _tmpPizzaTopping in
                guard let `self` = self, let _tmpPizzaTopping = _tmpPizzaTopping else { return }

                if self.chosenPizzaToppings.value.contains(where: { $0.id == _tmpPizzaTopping.id }) {
                    if _tmpPizzaTopping.pieces.count == 0 {
                        self.chosenPizzaToppings.accept(self.chosenPizzaToppings.value.filter({ $0.id != _tmpPizzaTopping.id }))
                    }else{
                        self.chosenPizzaToppings.accept(self.chosenPizzaToppings.value.filter({ $0.id != _tmpPizzaTopping.id }) + [_tmpPizzaTopping])
                    }
                }else{
                    if _tmpPizzaTopping.pieces.count > 0 {
                        self.chosenPizzaToppings.accept(self.chosenPizzaToppings.value + [_tmpPizzaTopping])
                    }
                }

                if self.isExist == true {
                    AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.pizzaToppings[tag - 1] = self.chosenPizzaToppings.value
                    AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value)
                    CartProduct.saveCartProducts(AppData.shared.cartProducts.value)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        AlertCoordinator.shared.productWasAdded("update", imageUrl: product.image)
                    }
                }
                else if existLevelProduct != nil {
                    if existLevelProduct?.pizzaToppings.index(0) != nil {
                        existLevelProduct?.pizzaToppings[0] = self.chosenPizzaToppings.value
                        AppData.shared.editingPack.accept(AppData.shared.editingPack.value)
                    }
                }

                AppData.shared.playSound(isProduct: false)

                self.activeTopping.accept(nil)
                self.confirmedToppings.accept(self.confirmedToppings.value)
                CartProduct.saveCartProducts(AppData.shared.cartProducts.value)

            }).disposed(by: disposeBag)
            
        }else{
            
            RequestManager.shared.rx_sd_image(imageUrl: product.image).asObservable().bind(to: toppingPicture).disposed(by: disposeBag)
            
            toppingDidTap.map({ (product.toppings)[$0.row] }).subscribe(onNext: { [weak self] _topping in
                guard let `self` = self else { return }
                
                if self.chosenToppings.value.contains(_topping) == true {
                    self.chosenToppings.accept((self.chosenToppings.value).filter({ $0 != _topping }))
                }else{
                    
                    if let level = level {
                        if level.toppingsAddPaid == false && self.chosenToppings.value.count == level.toppingsFree {
                            SHOW_TOAST("כמות התוספות המקסימלית למוצר זה \(level.toppingsFree) וכרגע יש חריגה בכמות!")
                            return
                        }
                    }
                    else if self.chosenToppings.value.count == product.maxToppings {
                        SHOW_TOAST("כמות התוספות המקסימלית למוצר זה \(product.maxToppings ?? 1)")
                        return
                    }
                    
                    self.chosenToppings.accept((self.chosenToppings.value) + [_topping])
                    
                }
                
                if self.isExist == true {
                    AppData.shared.cartProducts.value.first(where: { $0.productID == product.id })?.toppings[tag - 1] = self.chosenToppings.value
                    AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value)
                    CartProduct.saveCartProducts(AppData.shared.cartProducts.value)
                }
                
                else if existLevelProduct != nil {
                    if existLevelProduct?.toppings.index(0) != nil {
                        existLevelProduct?.toppings[0] = self.chosenToppings.value
                        AppData.shared.editingPack.accept(AppData.shared.editingPack.value)
                        DispatchQueue.main.async {
                            AlertCoordinator.shared.productWasAdded("update", imageUrl: product.image)
                        }
                    }
                }
                
                self.activeTopping.accept(nil)
                self.confirmedToppings.accept(self.confirmedToppings.value)
                CartProduct.saveCartProducts(AppData.shared.cartProducts.value)
                
            }).disposed(by: disposeBag)
            
            toppingDidTap.debounce(.milliseconds(500), scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] _ in
                
                if self?.isExist == true{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        AlertCoordinator.shared.productWasAdded("update", imageUrl: product.image)
                    }
                }
                
            }).disposed(by: disposeBag)
            
            toppingDidTap.subscribe(onNext: { _ in
                AppData.shared.playSound(isProduct: false)
            }).disposed(by: disposeBag)
        }
        
    }
    
    private func confirmProductOption(){
        
        if product.productOptions.count > 0 && productOption.value == nil && !isExist{
            AlertCoordinator.shared.productOptions(product.productOptions, title: product.optionsDescription, level: level).bind(to: productOption).disposed(by: disposeBag)
        }
        
    }
    
    
}

class ToppingView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var btnDelete: UIButton!
    @IBOutlet weak var lblTitle: UILabel!{
        didSet{ lblTitle.textColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var tblPizzaToppings: UITableView!
    @IBOutlet weak var btnAddToCart: UIButton!{
        didSet{ btnAddToCart.backgroundColor = AppData.shared.mainColor }
    }
    
    //pizza pieces view
    
    @IBOutlet weak var ivPizzaPic: UIImageView!
    @IBOutlet weak var viewPizzaPieces: UIView!
    @IBOutlet var ivPizzaPieces: [UIImageView]!
    @IBOutlet var btnPizzaPieces: [UIButton]!
    @IBOutlet weak var btnWholePizza: UIButton!
    @IBOutlet weak var btnCancelPizzaPieces: UIButton!
    @IBOutlet weak var btnConfirmPizzaPieces: UIButton!{
        didSet{
            btnConfirmPizzaPieces.borderColor = AppData.shared.mainColor
            btnConfirmPizzaPieces.setTitleColor(AppData.shared.mainColor, for: .normal)
        }
    }
    
    @IBOutlet var ivMainPizzaPieces: [UIImageView]!
    @IBOutlet weak var tblConfirmedPizzaToppings: UITableView!
    @IBOutlet weak var lblHint: UILabel!{
        didSet{ lblHint.textColor = AppData.shared.mainColor }
    }
    
    @IBOutlet weak var ivToppingPicture: UIImageView!
    
    
    var disposeBag = DisposeBag()
    var viewModel: ToppingViewModel!
    
    deinit {
        print("-------DEINIT---------")
        print(self)
        print("-------DEINIT---------")
    }
    
    
    init(frame:CGRect, product: Product, tag: Int, level: Level? = nil, existLevelProduct: CartProduct? = nil, isProductForReplacing: Bool = false) {
        super.init(frame: frame)
        self.tag = tag
        viewModel = ToppingViewModel(product, tag: tag, level: level, existLevelProduct: existLevelProduct, isProductForReplacing: isProductForReplacing)
        commonInit()
        configureProduct()
    }
    
    init(frame:CGRect, orderProduct: OrderProduct) {
        super.init(frame: frame)
        self.tag = 1000
        viewModel = ToppingViewModel(orderProduct)
        commonInit()
        configureOrderProduct()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func configureOrderProduct(){
        
        tblPizzaToppings.register(UINib(nibName: "ToppingCell", bundle: nil), forCellReuseIdentifier: "ToppingCell")
        
        viewModel.usedToppings.bind(to: tblPizzaToppings.rx.items(cellIdentifier: "ToppingCell", cellType: ToppingCell.self)){ row, usedTopping, cell in
            cell.lblName.text = usedTopping.name
            cell.lblPrice.text = usedTopping.price == 0 ? "ללא עלות".localized : "₪\(usedTopping.price.clean)"
            cell.viewCheckbox.isHidden = true
        }.disposed(by: disposeBag)
        
        viewModel.name.map { name in
            return "\(name ?? "")\n"
        }.bind(to: lblTitle.rx.text).disposed(by: disposeBag)

        
    }
    
    
    
    private func configureProduct(){
        
        if viewModel.level != nil {
            btnDelete.alpha = 0
            if viewModel.existLevelProduct != nil {
                btnAddToCart.alpha = 0
            }
        }
        
        ivPizzaPic.isHidden = viewModel.product.type != .pizza
        
        tblPizzaToppings.register(UINib(nibName: "ToppingCell", bundle: nil), forCellReuseIdentifier: "ToppingCell")
        tblConfirmedPizzaToppings.register(UINib(nibName: "ConfirmedPizzaToppingsCell", bundle: nil), forCellReuseIdentifier: "ConfirmedPizzaToppingsCell")

        tblConfirmedPizzaToppings.rx.itemSelected.bind(to: viewModel.removeToppingDidSelect).disposed(by: disposeBag)
        tblPizzaToppings.rx.itemSelected.bind(to: viewModel.toppingDidTap).disposed(by: disposeBag)
        btnAddToCart.rx.tap.bind(to: viewModel.addToCartDidTap).disposed(by: disposeBag)
        btnDelete.rx.tap.bind(to: viewModel.deleteDidTap).disposed(by: disposeBag)

        viewModel.toppings.bind(to: tblPizzaToppings.rx.items(cellIdentifier: "ToppingCell", cellType: ToppingCell.self)){ [unowned self] row, topping, cell in
            cell.lblName.text = topping.name
            var price = topping.price == 0 ? "ללא עלות".localized : "₪\(topping.price.clean)"
            
            if self.viewModel.product.type == .pizza {
                cell.viewCheckbox.borderColor = self.viewModel.chosenPizzaToppings.value.contains(where: { $0.id == topping.id }) ? .clear : .black
                cell.viewCheckbox.backgroundColor = self.viewModel.chosenPizzaToppings.value.contains(where: { $0.id == topping.id }) ? AppData.shared.mainColor : .clear
                if let _ = self.viewModel.level?.pizzaToppingPriceOutsideCart(self.viewModel.confirmedToppings.value) {
                    price = "ללא עלות".localized
                }
            }else{
                cell.viewCheckbox.borderColor = self.viewModel.chosenToppings.value.contains(topping) ? .clear : .black
                cell.viewCheckbox.backgroundColor = self.viewModel.chosenToppings.value.contains(topping) ? AppData.shared.mainColor : .clear
                if (self.viewModel.level?.toppingsFree ?? 0) - self.viewModel.confirmedToppings.value.filter({ !($0 is ProductOption) }).count > 0 {
                    price = "ללא עלות".localized
                }
            }

            cell.lblPrice.text = price

        }.disposed(by: disposeBag)

        viewModel.confirmedToppings.bind(to: tblConfirmedPizzaToppings.rx.items(cellIdentifier: "ConfirmedPizzaToppingsCell", cellType: ConfirmedPizzaToppingsCell.self)){ [weak self] row, item, cell in

            if let pizzaTopping = item as? PizzaTopping {
                let quarterPrice: Double = pizzaTopping.topping.price / 4
                var price = Double(pizzaTopping.pieces.count) * quarterPrice
                if let _price = self?.viewModel.level?.pizzaToppingPriceInCart(pizzaTopping, confirmedPizzaToppings: self?.viewModel.confirmedToppings.value ?? []) {
                    price = _price
                }
                cell.lblName.text = "\(pizzaTopping.topping.name) \(price == 0 ? "ללא עלות".localized : "₪\(price.clean)")"
            }else if let topping = item as? Topping {
                var price = topping.price
                if let _price = self?.viewModel.level?.toppingPriceInCart(topping, confirmedToppings: self?.viewModel.confirmedToppings.value ?? []) {
                    price = _price
                }
                
                cell.lblName.text = "\(topping.name) \(price == 0 ? "ללא עלות".localized : "₪\(topping.price.clean)")"
            }
            else if let option = item as? ProductOption {
                cell.lblName.text = "\(option.name) \(option.price == 0 || self?.viewModel.level?.optionsPaid == false ? "ללא עלות".localized : "₪\(option.price.clean)")"
            }

            cell.ivDeleteIcon.isHidden = item is ProductOption

        }.disposed(by: disposeBag)

        viewModel.name.map { [weak self] name in
            return "\(name ?? "")\n\("מס׳".localized)\(self?.tag ?? 0)"
        }.bind(to: lblTitle.rx.text).disposed(by: disposeBag)

        viewModel.isDeleteHidden.bind(to: btnDelete.rx.isHidden).disposed(by: disposeBag)

        viewModel.addToCartButtonTitle.bind(to: btnAddToCart.rx.title()).disposed(by: disposeBag)
        
        viewModel.toppingPicture.bind(to: ivToppingPicture.rx.image).disposed(by: disposeBag)
        
        /////////////////////////////////////////////////////////
        
        btnPizzaPieces.forEach { btn in
            let tag = btn.tag
            btn.rx.tap.map({ _ in return [tag] }).bind(to: viewModel.pizzaPieceDidTap).disposed(by: disposeBag)
        }
        btnWholePizza.rx.tap.map({ _ in return [1,2,3,4] }).bind(to: viewModel.pizzaPieceDidTap).disposed(by: disposeBag)
        btnCancelPizzaPieces.rx.tap.bind(to: viewModel.disactivateToppingDidTap).disposed(by: disposeBag)
        btnConfirmPizzaPieces.rx.tap.bind(to: viewModel.confirmToppingDidTap).disposed(by: disposeBag)

        viewModel.activeTopping.map({ $0 == nil }).bind(to: viewPizzaPieces.rx.animated.fade(duration: 0.5).isHidden).disposed(by: disposeBag)

        viewModel.tmpPizzaTopping.subscribe(onNext: { [unowned self] pizzaTopping in

            self.ivPizzaPieces.forEach { imgView in
                let basicPic = pizzaTopping?.picture ?? UIImage(named: "pizza_placeholder")!

                var pic: UIImage? = nil

                if pizzaTopping?.pieces.contains(imgView.tag) == true {
                    switch imgView.tag {
                        case 1: pic = UIImage(cgImage: basicPic.cgImage!, scale: 1, orientation: .left)
                        case 2: pic = UIImage(cgImage: basicPic.cgImage!, scale: 1, orientation: .leftMirrored)
                        case 3: pic = basicPic
                        case 4: pic = UIImage(cgImage: basicPic.cgImage!, scale: 1, orientation: .downMirrored)
                    default: break
                    }
                }

                imgView.image = pic

            }

        }).disposed(by: disposeBag)

        viewModel.chosenPizzaToppings.subscribe(onNext: { [weak self] pizzaToppings in
            self?.mergePizzaToppingsPicture(pizzaToppings)
        }).disposed(by: disposeBag)

    }
    
    
    
    private func commonInit(){
        Bundle.main.loadNibNamed("ToppingView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
    }


}

extension Array where Element: Comparable {
    func containsSameElements(as other: [Element]) -> Bool {
        return self.count == other.count && self.sorted() == other.sorted()
    }
}

extension ToppingView {
    
    func mergePizzaToppingsPicture(_ pizzaToppings: [PizzaTopping]){
        
        ivMainPizzaPieces.forEach({ $0.image = nil })
        
        var first: [UIImage] = []
        var second: [UIImage] = []
        var third: [UIImage] = []
        var fourth: [UIImage] = []
        
        pizzaToppings.forEach { pizzaTopping in
            if pizzaTopping.pieces.contains(1) {
                first.append(pizzaTopping.picture ?? UIImage())
            }
            if pizzaTopping.pieces.contains(2) {
                second.append(pizzaTopping.picture ?? UIImage())
            }
            if pizzaTopping.pieces.contains(3) {
                third.append(pizzaTopping.picture ?? UIImage())
            }
            if pizzaTopping.pieces.contains(4) {
                fourth.append(pizzaTopping.picture ?? UIImage())
            }
        }
        
        [ivMainPizzaPieces.first(where: { $0.tag == 1 }): first,
         ivMainPizzaPieces.first(where: { $0.tag == 2 }): second,
         ivMainPizzaPieces.first(where: { $0.tag == 3 }): third,
         ivMainPizzaPieces.first(where: { $0.tag == 4 }): fourth].forEach { item in
            guard let iv = item.key else { return }
            
            let size = CGSize(width: iv.frame.size.width, height: iv.frame.size.height)
            let areaSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            UIGraphicsBeginImageContext(size)
            
            item.value.forEach({ $0.draw(in: areaSize) })
            
            let newImg: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            var pic: UIImage? = nil
            
            switch iv.tag {
            case 1: pic = UIImage(cgImage: newImg.cgImage!, scale: 1, orientation: .left)
            case 2: pic = UIImage(cgImage: newImg.cgImage!, scale: 1, orientation: .leftMirrored)
            case 3: pic = newImg
            case 4: pic = UIImage(cgImage: newImg.cgImage!, scale: 1, orientation: .downMirrored)
            default: break
            }
            
            iv.image = pic
        }
        
    }
    
}
