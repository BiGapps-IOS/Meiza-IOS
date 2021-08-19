//
//  ProductCell2.swift
//  Meiza
//
//  Created by Denis Windover on 07/09/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxAnimated
import SDWebImage

extension ProductCell2ViewModel {
    
    func configurePack(_ product: Product){
        
        addToCartDidTap.filter({ _ in product.type == .pack }).subscribe { _ in
            if AppData.shared.cartProducts.value.first(where: { $0.product?.id == product.id }) != nil {
                AlertCoordinator.shared.pack {
                    Coordinator.shared.level(product, cartProduct: nil)
                }
                return
            }
            Coordinator.shared.level(product, cartProduct: nil)
            
        }.disposed(by: disposeBag)
        
    }
    
}

class ProductCell2ViewModel {
    
    let disposeBag                        = DisposeBag()
    var product:                            BehaviorRelay<Product>
    var productStatus:                      Observable<ProductStatus>
    var imageProductStatus                = BehaviorRelay<UIImage?>(value: nil)
    var isActiveProductHidden             = BehaviorRelay<Bool>(value: true)
    var isInactiveHidden                  = BehaviorRelay<Bool>(value: true)
    var addToCartDidTap                   = PublishSubject<Void>()
    var clearActiveProduct                = PublishSubject<Void>()
    var activeProductAmount               = BehaviorRelay<Double>(value: 0.0)
    var activeProductUnitType:              BehaviorRelay<String>
    var activeProductChangeUnitTypeDidTap = PublishSubject<String>()
    var isKgEnabled                       = BehaviorRelay<Bool>(value: false)
    var isUnitEnabled                     = BehaviorRelay<Bool>(value: false)
    var availableUnits                    = BehaviorRelay<[String]>(value: ["kg", "unit"])
    var minusPlusDidTap                   = PublishSubject<Bool>()
    var addToCartFinal                    = PublishSubject<Void>()
    var deleteProduct                     = PublishSubject<Void>()
    var productDescriptionDidTap          = PublishSubject<Void>()
    var isDescriptionBtnHidden:             Observable<Bool>
    // cart cell
    var cartProduct                       = BehaviorRelay<CartProduct?>(value: nil)
    var isChosenDidTap                    = PublishSubject<Void>()
    var cartDidChange                     = PublishSubject<Bool>()
    var zoomImageDidTap                   = PublishSubject<Void>()
    var isInCart:                           Observable<Bool>
    var level:                              Level?
    var isCart: Bool = true
    
    var isPackVC                          = BehaviorRelay<Bool>(value: false)
    
    var addOrEditCommentDidTap = PublishSubject<Void>()
    var isViewCommentHidden    = BehaviorRelay<Bool>(value: true)
    var isEditCommentHidden    = BehaviorRelay<Bool>(value: false)
    var isAddCommentHidden     = BehaviorRelay<Bool>(value: false)
    
    deinit {
        print("-------DEINIT---------")
        print(self)
        print("-------DEINIT---------")
    }
    

    
    private func binders(_ product: Product) {
        
        Observable.just(product.unitTypes.compactMap({ $0.type })).bind(to: availableUnits).disposed(by: disposeBag)
        
//        productDescriptionDidTap.subscribe(onNext: { _ in
//            AlertCoordinator.shared.productDescription(product)
//        }).disposed(by: disposeBag)
        
        productStatus.subscribe(onNext: { [weak self] _status in
            switch _status{
            case .isNew: self?.imageProductStatus.accept(UIImage(named: "new"))
            case .isSale: self?.imageProductStatus.accept(UIImage(named: "sale"))
            case .none: self?.imageProductStatus.accept(nil)
            case .outOfStock: self?.imageProductStatus.accept(nil)
            }
        }).disposed(by: disposeBag)
        
        AppData.shared.currentActiveProduct.subscribe(onNext: { [weak self] _product in
            if let _prod = _product {
                if _prod.id == product.id {
                    self?.isActiveProductHidden.accept(false)
                    if product.type == .pack {
                        let amount = AppData.shared.cartProducts.value.filter({ $0.productID == product.id }).count
                        if amount > 0 {
                            self?.activeProductUnitType.accept(product.defaultUnitType)
                            self?.activeProductAmount.accept(Double(amount))
                        }
                    }else{
                        if let _existProd = AppData.shared.cartProducts.value.first(where: { $0.productID == product.id }) {
                            self?.activeProductUnitType.accept(_existProd.unitType)
                            self?.activeProductAmount.accept(_existProd.amount)
                        }
                    }
                }else{
                    self?.isActiveProductHidden.accept(true)
                }
            }else{
                self?.isInactiveHidden.accept(true)
                self?.isActiveProductHidden.accept(true)
            }
        }).disposed(by: disposeBag)
        
        addToCartDidTap.filter({ [weak self] _ in product.toppings.count == 0 && product.type != .pack && self?.isPackVC.value == false }).map({ _ in return product }).bind(to: AppData.shared.currentActiveProduct).disposed(by: disposeBag)
        
        addToCartDidTap.filter({ [weak self] _ in product.toppings.count == 0 && product.type != .pack && self?.isPackVC.value == false }).map({ _ in return product }).subscribe(onNext: { [unowned self] _ in
            
            if AppData.shared.editingPack.value != nil { return }
            if AppData.shared.inProccess { return }
            AppData.shared.inProccess = true
            
            if !AppData.shared.cartProducts.value.contains(where: { $0.productID == product.id }) {
                
                
                CartProduct.addToCart(product, amount: self.activeProductAmount.value, unitType: self.activeProductUnitType.value)

                AppData.shared.playSound()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    AppData.shared.inProccess = false
                    AlertCoordinator.shared.productWasAdded("add", imageUrl: product.image)
                }
            }else{
                AppData.shared.inProccess = false
            }
            
        }).disposed(by: disposeBag)
        
        addToCartDidTap.filter({ [weak self] _ in product.toppings.count > 0 && product.type != .pack }).map({ _ in return product }).subscribe(onNext: { _product in
            if AppData.shared.editingPack.value != nil { return }
            AlertCoordinator.shared.toppings(_product)
        }).disposed(by: disposeBag)

        clearActiveProduct.map({ _ in return nil }).bind(to: AppData.shared.currentActiveProduct).disposed(by: disposeBag)
        
        activeProductChangeUnitTypeDidTap.filter({ _ in return product.unitTypes.count == 2 }).map({ newValue in return product.unitTypes.first(where: { $0.type == newValue })?.type ?? "kg" }).bind(to: activeProductUnitType).disposed(by: disposeBag)

        activeProductUnitType.map { _type in
            if let _existProd = AppData.shared.cartProducts.value.first(where: { $0.productID == product.id }), _existProd.unitType == _type {
                return _existProd.amount
            }else{
                return product.unitTypes.first(where: { $0.type == _type })?.multiplier ?? 0.0
            }
        }.bind(to: activeProductAmount).disposed(by: disposeBag)
        
        cartDidChange.debounce(.milliseconds(500), scheduler: MainScheduler.instance).subscribe(onNext: { isPlus in
            
            if AppData.shared.inProccess { return }
            AppData.shared.inProccess = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                AppData.shared.inProccess = false
            }
            
            if isPlus{
                AppData.shared.playSound()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                AlertCoordinator.shared.productWasAdded("update", imageUrl: product.image)
            }
            
            CartProduct.addToCart(product, amount: self.activeProductAmount.value, unitType: self.activeProductUnitType.value)
            
        }).disposed(by: disposeBag)

        minusPlusDidTap.subscribe(onNext: { [unowned self] _isPlus in
            var isCartChanged = false
            var isPlus = false
            if _isPlus {
                self.activeProductAmount.accept((self.activeProductAmount.value + (product.unitTypes.first(where: { $0.type == self.activeProductUnitType.value })?.multiplier ?? 0)).rounded2fD )
                isCartChanged = true
                isPlus = true
            }else{
                if self.activeProductAmount.value > (product.unitTypes.first(where: { $0.type == self.activeProductUnitType.value })?.multiplier ?? 0){
                    self.activeProductAmount.accept((self.activeProductAmount.value - (product.unitTypes.first(where: { $0.type == self.activeProductUnitType.value })?.multiplier ?? 0)).rounded2fD )
                    isCartChanged = true
                }
            }
            
            if isCartChanged{
                self.cartDidChange.onNext(isPlus)
            }
            
            
        }).disposed(by: disposeBag)
        
        
        
        deleteProduct.subscribe(onNext: { [weak self] _ in
            AlertCoordinator.shared.removeProductFromCart { [weak self] in
                CartProduct.removeProductFromCart(product, cartProduct: self?.cartProduct.value)
                self?.clearActiveProduct.onNext(())
            }
        }).disposed(by: disposeBag)
        
    }
    
    
    
    init(_ cartProduct: CartProduct, product: Product, isCart: Bool = true){
        
        self.isCart = isCart
        self.cartProduct.accept(cartProduct)
        
        self.product = BehaviorRelay(value: product)
        
        activeProductUnitType = BehaviorRelay(value: product.defaultUnitType)
        
        productStatus = Observable.combineLatest(AppData.shared.cartProducts, self.product){ _cart, _product in
            if !_product.isStock{ return .outOfStock }
            else if _product.isNew { return .isNew }
            else if _product.isSale { return .isSale }
            else { return .none }
        }
        
        isDescriptionBtnHidden = self.product.map({ $0.description == nil })
        
        isInCart = AppData.shared.cartProducts.map({ $0.contains(where: { $0.productID == product.id }) })
        
        self.cartProduct.map({ $0?.comment == nil }).bind(to: isViewCommentHidden).disposed(by: disposeBag)
        
        addOrEditCommentDidTap.subscribe(onNext: { _ in
            AlertCoordinator.shared.productComment(cartProduct)
        }).disposed(by: disposeBag)
        
        zoomImageDidTap.flatMap({ _ -> Driver<UIImage?> in Loader.show(); return RequestManager.shared.rx_sd_image(imageUrl: product.image) }).subscribe(onNext: { img in
            Loader.dismiss()
            guard let img = img else {
                let m = "שגיאת שרת!"
                m.toast()
                return
            }
            Coordinator.shared.image(img)
        }).disposed(by: disposeBag)
        
        binders(product)
        
        isChosenDidTap.subscribe(onNext: { [weak self] _ in
            CartProduct.updateIsChosen(for: self?.cartProduct.value)
        }).disposed(by: disposeBag)
        
        addToCartDidTap.filter({ [weak self] _ in product.type == .pack && self?.isCart == true }).subscribe(onNext: { _ in
            AppData.shared.currentActiveProduct.accept(nil)
            Coordinator.shared.editPack(cartProduct)
        }).disposed(by: disposeBag)
        
        productDescriptionDidTap.subscribe(onNext: { _ in
            AlertCoordinator.shared.productDescription(product)
        }).disposed(by: disposeBag)
        
        if !isCart {
            addToCartDidTap.subscribe(onNext: { _ in
                NotificationCenter.default.post(name: NSNotification.Name("deleteLevelProduct"), object: cartProduct)
            }).disposed(by: disposeBag)
            
        }
        
    }
    
    private func levelProductBinders(_ level: Level, product: Product){
        
        addToCartDidTap.map({ _ in return product }).subscribe(onNext: { [weak self] _product in
            
            if product.toppings.count == 0 && product.type != .pack {
                
                let levelProduct = CartProduct(productID: product.id, amount: product.unitTypes.first(where: { $0.type == product.defaultUnitType })?.multiplier ?? 1, unitType: product.defaultUnitType)
                
                guard let pack = AppData.shared.currentPack.value else { return }
                
                if let _level = pack.levels.first(where: { $0 == level }) {
                    _level.selectedProducts.append(levelProduct)
                    AppData.shared.currentPack.accept(pack)
                    
                    self?.cartProduct.accept(self?.cartProduct.value)
                    
                    let isLastLevelProduct = (AppData.shared.currentPack.value?.levels.last?.id == _level.id) &&
                        (AppData.shared.currentPack.value?.levels.first(where: { $0 == level })?.productsAmount ?? 0) == AppData.shared.currentPack.value?.levels.first(where: { $0 == level })?.selectedProducts.count ?? 0
                    
                    if (AppData.shared.currentPack.value?.levels.first(where: { $0 == level })?.productsAmount ?? 0) >= AppData.shared.currentPack.value?.levels.first(where: { $0 == level })?.selectedProducts.count ?? 0 {
                        
                        if !isLastLevelProduct {
                            let max = AppData.shared.currentPack.value?.levels.first(where: { $0 == level })?.productsAmount ?? 0
                            let current = AppData.shared.currentPack.value?.levels.first(where: { $0 == level })?.selectedProducts.count ?? 0
                            let next = current + 1
                            var message: String = ""
                            
                            if current == max {
                                message = "נבחר מוצר 111 מתוך 222".localized.replacingOccurrences(of: "111", with: current.toString).replacingOccurrences(of: "222", with: max.toString)
                            }else{
                                message = "נבחר מוצר 111 מתוך 222 \nאנא בחר מוצר 333".localized.replacingOccurrences(of: "111", with: current.toString).replacingOccurrences(of: "222", with: max.toString).replacingOccurrences(of: "333", with: next.toString)
                            }
                            
                            AlertCoordinator.shared.toast(text: message)
                        }
                    }
                }
                
            }
            else if product.toppings.count > 0 && product.type != .pack {
                AlertCoordinator.shared.toppings(_product, level: level)
            }
            
        }).disposed(by: disposeBag)
        
    }
    
    init(_ product: Product, level: Level? = nil, isProductForReplacing: Bool = false){
        
        self.isCart = false
        self.product = BehaviorRelay(value: product)
        self.level = level
        
        activeProductUnitType = BehaviorRelay(value: product.defaultUnitType)
        
        isDescriptionBtnHidden = self.product.map({ $0.description == nil })
        
        isInCart = AppData.shared.cartProducts.map({ $0.contains(where: { $0.productID == product.id }) && isProductForReplacing == false })
        
        AppData.shared.cartProducts.map({ $0.first(where: { $0.product?.id == product.id }) }).bind(to: cartProduct).disposed(by: disposeBag)
        
        productDescriptionDidTap.subscribe(onNext: { _ in
            AlertCoordinator.shared.productDescription(product)
        }).disposed(by: disposeBag)
        
        zoomImageDidTap.flatMap({ _ -> Driver<UIImage?> in Loader.show(); return RequestManager.shared.rx_sd_image(imageUrl: product.image) }).subscribe(onNext: { img in
            Loader.dismiss()
            guard let img = img else {
                let m = "שגיאת שרת!"
                m.toast()
                return
            }
            Coordinator.shared.image(img)
        }).disposed(by: disposeBag)
        
        if let level = level {
            productStatus = Observable.combineLatest(AppData.shared.cartProducts, self.product){ _cart, _product in
                return .none
            }
            
            if isProductForReplacing {
                
                addToCartDidTap.map({ _ in return product }).subscribe(onNext: { _product in
                        
                    if product.toppings.count == 0 && product.type != .pack {
                        
                        let levelProduct = CartProduct(productID: product.id, amount: product.unitTypes.first(where: { $0.type == product.defaultUnitType })?.multiplier ?? 1, unitType: product.defaultUnitType)
                        
                        NotificationCenter.default.post(name: NSNotification.Name("replaceLevelProduct"), object: levelProduct)
                        
                    }
                    else if product.toppings.count > 0 && product.type != .pack {
                        AlertCoordinator.shared.toppings(_product, level: level, isProductForReplacing: isProductForReplacing)
                    }
                    
                }).disposed(by: disposeBag)
                
            }else{
                levelProductBinders(level, product: product)
            }
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name("refreshCartProduct"), object: nil, queue: .main) { [weak self] _ in
                if AppData.shared.currentPack.value?.levels.contains(level) == true {
                    self?.cartProduct.accept(self?.cartProduct.value)
                }
            }
            
            AppData.shared.currentPack.withLatestFrom(cartProduct).bind(to: cartProduct).disposed(by: disposeBag)
            
        }else{
            productStatus = Observable.combineLatest(AppData.shared.cartProducts, self.product){ _cart, _product in
                if !_product.isStock{ return .outOfStock }
                else if _product.isNew { return .isNew }
                else if _product.isSale { return .isSale }
                else { return .none }
            }
            
            binders(product)
            
            //MARK: - PACK -
            configurePack(product)
        }
        
    }
    
}


class ProductCell2: UITableViewCell {
    
    
    @IBOutlet weak var btnAddToCart: UIButton!
    @IBOutlet weak var viewUpdateCart: UIView!{
        didSet{ viewUpdateCart.backgroundColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var viewAddToCart: UIView!{
        didSet{ viewAddToCart.backgroundColor = AppData.shared.mainColor }
    }
    
    @IBOutlet weak var viewActiveProduct: UIView!
    @IBOutlet var views: [UIView]!
    @IBOutlet weak var btnMinus: UIButton!
    @IBOutlet weak var btnPlus: UIButton!
    @IBOutlet weak var lblProductAmount: UILabel!
    @IBOutlet weak var btnUnitsUnitType: UIButton!
    @IBOutlet weak var btnKgUnitType: UIButton!
    @IBOutlet weak var viewOneUnit: UIView!
    @IBOutlet weak var lblOneUnit: UILabel!{
        didSet{ lblOneUnit.backgroundColor = AppData.shared.mainColor
            lblOneUnit.textColor = .white
        }
    }
    @IBOutlet weak var ivProduct: UIImageView!
    @IBOutlet weak var ivProductStatus: UIImageView!
    @IBOutlet weak var ivProductAdded: UIImageView!{
        didSet{ ivProductAdded.imageColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var btnDescription: UIButton!
    @IBOutlet weak var lblDescriptionBtnTitle: UILabel!{
        didSet{ lblDescriptionBtnTitle.attributedText = attrUnderline("מידע נוסף".localized) }
    }
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var lblProductName: UILabel!{
        didSet{ lblProductName.textColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var viewOutOfStock: UIView!
    @IBOutlet weak var btnRemoveFromCart: UIButton!{
        didSet{ btnRemoveFromCart.backgroundColor = AppData.shared.mainColor }
    }
    
    @IBOutlet weak var btnZoomImage: UIButton! = nil
    
    @IBOutlet weak var viewCheckbox: UIView! = nil // cart cell
    @IBOutlet weak var ivCheckbox: UIImageView! = nil { // cart cell
        didSet{ ivCheckbox.imageColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var btnCheckbox: UIButton! = nil // cart cell
    @IBOutlet weak var lblUnitType: UILabel! = nil // cart cell
    @IBOutlet weak var lblAmount: UILabel! = nil // cart cell
    
    
    @IBOutlet weak var viewMain: UIView! = nil // search vc
    
    @IBOutlet weak var btnAddComment: UIButton! = nil {
        didSet{ btnAddComment.setTitleColor(AppData.shared.mainColor, for: .normal) }
    }
    @IBOutlet weak var viewComment: UIView! = nil
    @IBOutlet weak var lblComment: UILabel! = nil {
        didSet{ lblComment.textColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var btnEditComment: UIButton! = nil
    
    
    var viewModel: ProductCell2ViewModel! {
        didSet {
            self.configureCell()
        }
    }
    
    var disposeBag: DisposeBag! = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        views.forEach({ $0.dropShadow() })
    }
    
    private func configureCell() {
        //PACK CART_PRODUCT
        if (viewModel.level != nil || !viewModel.isCart) && !(NAV.viewControllers.last is MainVC) && !(NAV.viewControllers.last is SearchVC) {
            viewCheckbox?.alpha = 0
            lblPrice?.alpha = 0
            ivProductAdded?.alpha = 0
            ivProductStatus?.alpha = 0
            btnRemoveFromCart?.alpha = 0
            if self.parentViewController is PackProductsVC {
                btnAddToCart.setTitle("החלף מוצר".localized, for: .normal)
                btnAddToCart.titleLabel?.font = UIFont(name: "Heebo-Regular", size: 12)
                btnAddToCart.cornerRadius = 13
                btnAddToCart.backgroundColor = AppData.shared.mainColor
                btnAddToCart.setTitleColor(.white, for: .normal)
                viewModel.isPackVC.accept(true)
            }
        }
        
        //MARK: - OUTPUTS
        btnAddComment?.rx.tap.bind(to: viewModel.addOrEditCommentDidTap).disposed(by: disposeBag)
        btnEditComment?.rx.tap.bind(to: viewModel.addOrEditCommentDidTap).disposed(by: disposeBag)

        btnRemoveFromCart.rx.tap.bind(to: viewModel.deleteProduct).disposed(by: disposeBag)
        btnAddToCart.rx.tap.bind(to: viewModel.addToCartDidTap).disposed(by: disposeBag)
        btnPlus.rx.tap.map({ _ in return true }).bind(to: viewModel.minusPlusDidTap).disposed(by: disposeBag)
        btnMinus.rx.tap.map({ _ in return false }).bind(to: viewModel.minusPlusDidTap).disposed(by: disposeBag)
        btnUnitsUnitType.rx.tap.map({ return "unit" }).bind(to: viewModel.activeProductChangeUnitTypeDidTap).disposed(by: disposeBag)
        btnKgUnitType.rx.tap.map({ return "kg" }).bind(to: viewModel.activeProductChangeUnitTypeDidTap).disposed(by: disposeBag)
        btnDescription.rx.tap.bind(to: viewModel.productDescriptionDidTap).disposed(by: disposeBag)
        
        btnZoomImage?.rx.tap.bind(to: viewModel.zoomImageDidTap).disposed(by: disposeBag)
        
        // cart cell
        btnCheckbox?.rx.tap.bind(to: viewModel.isChosenDidTap).disposed(by: disposeBag)
        
        //MARK: - INPUTS
        
        if lblComment != nil {
            viewModel.cartProduct.map({ $0?.comment != nil ? "\("הערה:".localized) \($0?.comment ?? "")" : nil }).bind(to: lblComment.rx.text).disposed(by: disposeBag)
            
            viewModel.isViewCommentHidden.bind(to: viewComment.rx.isHidden).disposed(by: disposeBag)
            
            viewModel.isAddCommentHidden.bind(to: btnAddComment.rx.isHidden).disposed(by: disposeBag)
        }
        
        
        
        viewModel.product
            .flatMap({ RequestManager.shared.rx_sd_image(imageUrl: $0.image) })
            .bind(to: ivProduct.rx.animated.fade(duration: 0.5).image)
            .disposed(by: disposeBag)
        
        viewModel.product.map({ $0.name }).bind(to: lblProductName.rx.text).disposed(by: disposeBag)
        
        viewModel.imageProductStatus.bind(to: ivProductStatus.rx.image).disposed(by: disposeBag)
        
        viewModel.isInCart.map({ !$0 }).bind(to: ivProductAdded.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.isInCart.map({ !$0 }).bind(to: btnRemoveFromCart.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.isInCart.map({ !$0 }).bind(to: viewUpdateCart.rx.animated.fade(duration: 0.5).isHidden).disposed(by: disposeBag)
        
        viewModel.productStatus.map({ $0 == .outOfStock ? false : true }).bind(to: viewOutOfStock.rx.animated.fade(duration: 0.5).isHidden).disposed(by: disposeBag)
        
        viewModel.isActiveProductHidden.bind(to: viewActiveProduct.rx.animated.fade(duration: 0.1).isHidden).disposed(by: disposeBag)
        
        viewModel.activeProductUnitType.subscribe(onNext: { [weak self] unitType in
            guard let `self` = self else{ return }
            if unitType == "kg" {
                self.btnKgUnitType.backgroundColor = AppData.shared.mainColor
                self.btnKgUnitType.setAttributedTitle(NSMutableAttributedString().normal("ק״ג".localized, fontSize: 19, color: .white), for: .normal)
                self.btnUnitsUnitType.backgroundColor = .clear
                let title = NSMutableAttributedString().strikethrough("יח׳".localized, isStrike: self.viewModel.product.value.unitTypes.count != 2, fontSize: 19, color: AppData.shared.mainColor)
                self.btnUnitsUnitType.setAttributedTitle(title, for: .normal)
            }else{
                self.btnUnitsUnitType.backgroundColor = AppData.shared.mainColor
                self.btnUnitsUnitType.setAttributedTitle(NSMutableAttributedString().normal("יח׳".localized, fontSize: 19, color: .white), for: .normal)
                self.btnKgUnitType.backgroundColor = .clear
                let title = NSMutableAttributedString().strikethrough("ק״ג".localized, isStrike: self.viewModel.product.value.unitTypes.count != 2, fontSize: 19, color: AppData.shared.mainColor)
                self.btnKgUnitType.setAttributedTitle(title, for: .normal)
            }
        }).disposed(by: disposeBag)
        
        viewModel.activeProductAmount.map({ $0.clean2 }).bind(to: lblProductAmount.rx.animated.fade(duration: 0.2).text).disposed(by: disposeBag)
        
        viewModel.isKgEnabled.bind(to: btnKgUnitType.rx.isEnabled).disposed(by: disposeBag)
        viewModel.isUnitEnabled.bind(to: btnUnitsUnitType.rx.isEnabled).disposed(by: disposeBag)
        
        viewModel.product.map({ $0.name }).bind(to: lblProductName.rx.text).disposed(by: disposeBag)
        
        viewModel.isDescriptionBtnHidden.bind(to: btnDescription.rx.isHidden).disposed(by: disposeBag)
        viewModel.isDescriptionBtnHidden.bind(to: lblDescriptionBtnTitle.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.availableUnits.subscribe(onNext: { [unowned self] types in
            if types.count == 1 {
                self.viewOneUnit.isHidden = false
                self.lblOneUnit.text = types[0] == "kg" ? "ק״ג".localized : "יח׳".localized
            }else{
                self.viewOneUnit.isHidden = true
            }
        }).disposed(by: disposeBag)
        
        viewModel.cartProduct.map { cartProduct -> String? in
            if cartProduct?.product?.type == .pack {
                return "1"
            }
            return cartProduct?.unitType == "kg" ? cartProduct?.amount.clean : Int(cartProduct?.amount ?? 0).toString
        }.map { [weak self] _amount -> String? in
            var amount = _amount
            if let level = self?.viewModel.level {
                if let levelProductsAmount = AppData.shared.currentPack.value?.levels.first(where: { $0.id == level.id })?.selectedProducts.filter({ $0.productID == self?.viewModel.product.value.id }).count {
                    amount = levelProductsAmount.toString
                }
            }
            self?.lblAmount.isHidden = amount == "0"
            return amount
        }.bind(to: lblAmount.rx.text).disposed(by: disposeBag)
        
        viewModel.product.map({ $0.defaultUnitType == "kg" ? "ק״ג".localized : "יח׳".localized }).bind(to: lblUnitType.rx.text).disposed(by: disposeBag)
        
        // cart cell
        if ivCheckbox != nil {
            viewModel.cartProduct.map({ $0?.isChosen == true ? UIImage(named: "blue_chekbox")?.imageWithColor(color1: AppData.shared.mainColor) : nil }).bind(to: ivCheckbox.rx.animated.fade(duration: 0.5).image).disposed(by: disposeBag)
            
            viewModel.cartProduct.map({ $0?.price }).map({ "₪\($0?.clean ?? "")" }).bind(to: lblPrice.rx.text).disposed(by: disposeBag)
            
        }else{
            
            viewModel.product
            .map({ _prod in
                _prod.unitTypes.first(where: { $0.type == _prod.defaultUnitType })?.price
            })
            .map({ "₪\($0?.clean ?? "")" })
            .bind(to: lblPrice.rx.text)
            .disposed(by: disposeBag)
            
        }
        
        
    }
    
}
