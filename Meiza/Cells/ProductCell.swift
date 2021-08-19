//
//  ProductCell.swift
//  Meiza
//
//  Created by Denis Windover on 07/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxAnimated
import SDWebImage

extension ProductCellViewModel {
    
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


enum ProductStatus {
    case isNew, isSale, outOfStock, none
}


class ProductCellViewModel {
    
    let disposeBag                        = DisposeBag()
    var product:                            BehaviorRelay<Product>
    var productStatus:                      Observable<ProductStatus>
    var imageProductStatus                = BehaviorRelay<UIImage?>(value: nil)
    var isActiveProductHidden             = BehaviorRelay<Bool>(value: true)
    var addToCartDidTap                   = PublishSubject<Void>()
    var activeProductAmount               = BehaviorRelay<Double>(value: 0.0)
    var activeProductUnitType:              BehaviorRelay<String>
    var minusPlusDidTap                   = PublishSubject<Bool>()
    var deleteProduct                     = PublishSubject<Void>()
    var productDescriptionDidTap          = PublishSubject<Void>()
    var isDescriptionBtnHidden:             Observable<Bool>
    var cartDidChange                     = PublishSubject<Bool>()
    var zoomImageDidTap                   = PublishSubject<Void>()
    var isInCart:                           Observable<Bool>
    var isCart:                             Bool = true
    var level:                              Level?
    var isLevelVC                         = BehaviorRelay<Bool>(value: false)
    
    deinit {
        print("-------DEINIT---------")
        print(self)
        print("-------DEINIT---------")
    }
    
    init(_ product: Product, isCart: Bool = true, level: Level? = nil, isProductForReplacing: Bool = false){
        
        self.isCart = isCart
        self.level = level
        self.product = BehaviorRelay(value: product)
        
        self.activeProductUnitType = BehaviorRelay(value: product.defaultUnitType)
        
        isDescriptionBtnHidden = self.product.map({ $0.description == nil })
        
        isInCart = Observable.combineLatest(AppData.shared.cartProducts, isLevelVC, AppData.shared.currentPack, AppData.shared.editingPack){ _cartProducts, _isLevelVC, _currentPack, _editingPack in
            
            if isProductForReplacing { return false }
            
            if _isLevelVC {
                if let _lvl = _currentPack?.levels.first(where: { $0.id == level?.id }), _lvl.selectedProducts.contains(where: { $0.productID == product.id }), _editingPack == nil {
                    return true
                }
                else if let _lvl2 = _editingPack?.levels.first(where: { $0.id == level?.id }), _lvl2.selectedProducts.contains(where: { $0.productID == product.id }), _currentPack == nil {
                    return true
                }
            }
            else if _cartProducts.contains(where: { $0.productID == product.id }) { return true }
            return false
        }
        
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
            
//            NotificationCenter.default.addObserver(forName: NSNotification.Name("refreshCartProduct"), object: nil, queue: .main) { [weak self] _ in
//                if AppData.shared.currentPack.value?.levels.contains(level) == true {
//                    self?.cartProduct.accept(self?.cartProduct.value)
//                }
//            }
            
//            AppData.shared.currentPack.withLatestFrom(cartProduct).bind(to: cartProduct).disposed(by: disposeBag)
            
        }else{
            productStatus = Observable.combineLatest(AppData.shared.cartProducts, self.product){ _cart, _product in
                if !_product.isStock{ return .outOfStock }
                else if _product.isNew { return .isNew }
                else if _product.isSale { return .isSale }
                else { return .none }
            }
            
            //MARK: - PACK -
            configurePack(product)
        }
        
        

        
        ////////////////////////////
        
//        addToCartDidTap.filter({ [weak self] _ in product.type == .pack && self?.isCart == true }).subscribe(onNext: { _ in
//            AppData.shared.currentActiveProduct.accept(nil)
////            Coordinator.shared.editPack(cartProduct)
//        }).disposed(by: disposeBag)
        
//        if !isCart {
//
//            addToCartDidTap.subscribe(onNext: { _ in
//                NotificationCenter.default.post(name: NSNotification.Name("deleteLevelProduct"), object: cartProduct)
//            }).disposed(by: disposeBag)
//
//        }
        
        ////////////////////////////
        
        productDescriptionDidTap.subscribe(onNext: { _ in
            AlertCoordinator.shared.productDescription(product)
        }).disposed(by: disposeBag)
        
        productStatus.subscribe(onNext: { [weak self] _status in
            switch _status{
            case .none: self?.imageProductStatus.accept(nil)
            case .isNew: self?.imageProductStatus.accept(UIImage(named: "orange"))
            case .outOfStock: self?.imageProductStatus.accept(nil)
            case .isSale: self?.imageProductStatus.accept(UIImage(named: "red"))
            }
        }).disposed(by: disposeBag)
        
        AppData.shared.currentActiveProduct.subscribe(onNext: { [weak self] _product in
            if let _prod = _product {
                if _prod.id == product.id {
                    self?.isActiveProductHidden.accept(false)
                    if let _existProd = AppData.shared.cartProducts.value.first(where: { $0.productID == product.id }) {
                        self?.activeProductAmount.accept(_existProd.amount)
                    }
                }else{
                    self?.isActiveProductHidden.accept(true)
                }
            }else{
                self?.isActiveProductHidden.accept(true)
            }
        }).disposed(by: disposeBag)

        addToCartDidTap.filter({ [weak self] _ in product.toppings.count == 0 && product.type != .pack && self?.isCart == true }).map({ _ in return product }).bind(to: AppData.shared.currentActiveProduct).disposed(by: disposeBag)
        
        addToCartDidTap.filter({ [weak self] _ in product.toppings.count > 0 && product.type != .pack && self?.isCart == true }).map({ _ in return product }).subscribe(onNext: { _product in
            AlertCoordinator.shared.toppings(_product)
        }).disposed(by: disposeBag)
        
        addToCartDidTap.filter({ [weak self] _ in product.toppings.count == 0 && product.type != .pack && self?.isCart == true }).map({ _ in return product }).subscribe(onNext: { [unowned self] _ in
            
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

        activeProductUnitType.map { _type in
            if let _existProd = AppData.shared.cartProducts.value.first(where: { $0.productID == product.id }), _existProd.unitType == _type {
                return _existProd.amount
            }else{
                return product.unitTypes.first(where: { $0.type == _type })?.multiplier ?? 0.0
            }
        }.bind(to: activeProductAmount).disposed(by: disposeBag)

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
        
        zoomImageDidTap.flatMap({ _ -> Driver<UIImage?> in Loader.show(); return RequestManager.shared.rx_sd_image(imageUrl: product.image) }).subscribe(onNext: { img in
            Loader.dismiss()
            guard let img = img else {
                let m = "שגיאת שרת!".localized
                m.toast()
                return
            }
            Coordinator.shared.image(img)
        }).disposed(by: disposeBag)
        
    }
    
    private func levelProductBinders(_ level: Level, product: Product){
        
        addToCartDidTap.map({ _ in return product }).subscribe(onNext: { _product in
            
            if product.toppings.count == 0 && product.type != .pack {
                
                let levelProduct = CartProduct(productID: product.id, amount: product.unitTypes.first(where: { $0.type == product.defaultUnitType })?.multiplier ?? 1, unitType: product.defaultUnitType)
                
                guard let pack = AppData.shared.currentPack.value else { return }
                
                if let _level = pack.levels.first(where: { $0 == level }) {
                    _level.selectedProducts.append(levelProduct)
                    AppData.shared.currentPack.accept(pack)
                    
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
    
}


class ProductCell: UICollectionViewCell {
    
    @IBOutlet weak var viewMain: UIView!
    @IBOutlet weak var ivProduct: UIImageView!
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var btnAddToCart: UIButton!
    @IBOutlet weak var ivProductStatus: UIImageView!
    @IBOutlet weak var viewOutOfStock: UIView!
    @IBOutlet weak var viewActiveProduct: UIView!
    @IBOutlet weak var btnMinus: UIButton!
    @IBOutlet weak var btnPlus: UIButton!
    @IBOutlet weak var lblProductAmount: UILabel!
    @IBOutlet weak var lblProductName: UILabel!{
        didSet{ lblProductName.textColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var btnDescription: UIButton!
    @IBOutlet weak var lblDescriptionBtnTitle: UILabel!{
        didSet{ lblDescriptionBtnTitle.attributedText = attrUnderline("מידע נוסף".localized, fontSize: 11) }
    }
    @IBOutlet weak var ivProductAdded: UIImageView!{
        didSet{ ivProductAdded.imageColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var lblUnitType: UILabel!
    @IBOutlet weak var viewAddToCart: UIView!{
        didSet{ viewAddToCart.backgroundColor = AppData.shared.mainColor }
    }
    
    @IBOutlet weak var btnZoomImage: UIButton!
    @IBOutlet weak var viewDescription: UIView!
    @IBOutlet weak var lblAddToCart: UILabel!
    @IBOutlet weak var ivPlus: UIImageView!
    
    
    var viewModel: ProductCellViewModel! {
        didSet {
            self.configureCell()
        }
    }
    
    var disposeBag: DisposeBag! = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        ivProduct.image = nil
        disposeBag = DisposeBag()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    private func configureCell() {
        
        //MARK: - OUTPUTS
        btnAddToCart.rx.tap.bind(to: viewModel.addToCartDidTap).disposed(by: disposeBag)
        btnPlus.rx.tap.map({ _ in return true }).bind(to: viewModel.minusPlusDidTap).disposed(by: disposeBag)
        btnMinus.rx.tap.map({ _ in return false }).bind(to: viewModel.minusPlusDidTap).disposed(by: disposeBag)
        btnDescription.rx.tap.bind(to: viewModel.productDescriptionDidTap).disposed(by: disposeBag)
        btnZoomImage.rx.tap.bind(to: viewModel.zoomImageDidTap).disposed(by: disposeBag)
        
        //MARK: - INPUTS
        viewModel.product
            .flatMap({ RequestManager.shared.rx_sd_image(imageUrl: $0.image) })
            .bind(to: ivProduct.rx.animated.fade(duration: 0.5).image)
            .disposed(by: disposeBag)
        
        viewModel.product
            .map({ _prod in
                _prod.unitTypes.first(where: { $0.type == _prod.defaultUnitType })?.price
            })
            .map({ "₪\($0?.clean ?? "")" })
            .map({ [weak self] in self?.viewModel.level == nil ? $0 : "" })
            .bind(to: lblPrice.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.imageProductStatus.bind(to: ivProductStatus.rx.image).disposed(by: disposeBag)
        
        viewModel.productStatus.map({ $0 == .outOfStock ? false : true }).bind(to: viewOutOfStock.rx.animated.fade(duration: 0.5).isHidden).disposed(by: disposeBag)
        
        viewModel.isActiveProductHidden.bind(to: viewActiveProduct.rx.animated.fade(duration: 0.1).isHidden).disposed(by: disposeBag)
        
        viewModel.activeProductUnitType.map({ $0 == "kg" ? "ק״ג".localized : "יח׳".localized }).bind(to: lblUnitType.rx.text).disposed(by: disposeBag)
        
        viewModel.activeProductAmount.map({ $0.clean2 }).bind(to: lblProductAmount.rx.animated.fade(duration: 0.2).text).disposed(by: disposeBag)
        
        viewModel.product.map({ $0.name }).bind(to: lblProductName.rx.text).disposed(by: disposeBag)
        
        viewModel.isDescriptionBtnHidden.bind(to: viewDescription.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.isInCart.map({ !$0 }).bind(to: ivProductAdded.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.isInCart.map({ $0 ? "עדכן סל".localized : "הוסף לסל".localized }).bind(to: lblAddToCart.rx.text).disposed(by: disposeBag)
        
        viewModel.isInCart.map({ $0 ? UIImage(named: "white_pen") : UIImage(named: "white_plus") }).bind(to: ivPlus.rx.image).disposed(by: disposeBag)
        
    }
    
}

