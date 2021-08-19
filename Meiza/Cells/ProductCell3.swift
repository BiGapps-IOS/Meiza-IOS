//
//  ProductCell3.swift
//  Meiza
//
//  Created by Denis Windover on 23/05/2021.
//  Copyright © 2021 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift


class ProductCell3ViewModel {
    
    let disposeBag = DisposeBag()
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
    var availableUnits                    = BehaviorRelay<[String]>(value: ["kg", "unit"])
    var minusPlusDidTap                   = PublishSubject<Bool>()
    var deleteProduct                     = PublishSubject<Void>()
    var productDescriptionDidTap          = PublishSubject<Void>()
    var isDescriptionBtnHidden:             Observable<Bool>
    var zoomImageDidTap                   = PublishSubject<Void>()
    var cartDidChange                     = PublishSubject<Bool>()
    var isInCart:                           Observable<Bool>
    
    
    deinit {
        print("-------DEINIT---------")
        print(self)
        print("-------DEINIT---------")
    }
    
    init(_ product: Product){
        
        self.product = BehaviorRelay(value: product)

        activeProductUnitType = BehaviorRelay(value: product.defaultUnitType)

        isDescriptionBtnHidden = self.product.map({ $0.description == nil })

        isInCart = AppData.shared.cartProducts.map({ $0.contains(where: { $0.productID == product.id }) })

//        AppData.shared.cartProducts.map({ $0.first(where: { $0.product?.id == product.id }) }).bind(to: cartProduct).disposed(by: disposeBag)

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
    
    private func binders(_ product: Product) {
        
        productStatus.subscribe(onNext: { [weak self] _status in
            switch _status{
            case .isNew: self?.imageProductStatus.accept(UIImage(named: "orange"))
            case .isSale: self?.imageProductStatus.accept(UIImage(named: "red"))
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
        
        addToCartDidTap.filter({ _ in product.toppings.count == 0 && product.type != .pack }).map({ _ in return product }).bind(to: AppData.shared.currentActiveProduct).disposed(by: disposeBag)
        
        addToCartDidTap.filter({ _ in product.toppings.count == 0 && product.type != .pack }).map({ _ in return product }).subscribe(onNext: { [unowned self] _ in
            
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
        
        addToCartDidTap.filter({ _ in product.toppings.count > 0 && product.type != .pack }).map({ _ in return product }).subscribe(onNext: { _product in
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
        
        
        
//        deleteProduct.subscribe(onNext: { [weak self] _ in
//            AlertCoordinator.shared.removeProductFromCart { [weak self] in
//                CartProduct.removeProductFromCart(product, cartProduct: self?.cartProduct.value)
//                self?.clearActiveProduct.onNext(())
//            }
//        }).disposed(by: disposeBag)
        
    }
    
    
}

extension ProductCell3ViewModel {
    
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


class ProductCell3: UITableViewCell {
    
    @IBOutlet weak var btnAddToCart: UIButton!
    @IBOutlet weak var ivPlus: UIImageView!
    @IBOutlet weak var viewAddToCart: UIView!{
        didSet{ viewAddToCart.backgroundColor = AppData.shared.mainColor }
    }
    
    @IBOutlet weak var viewActiveProduct: UIView!
    @IBOutlet weak var btnMinus: UIButton!
    @IBOutlet weak var btnPlus: UIButton!
    @IBOutlet weak var lblProductAmount: UILabel!
    @IBOutlet weak var btnUnitType: UIButton!

    @IBOutlet weak var ivProduct: UIImageView!
    @IBOutlet weak var ivProductStatus: UIImageView!
    @IBOutlet weak var ivProductAdded: UIImageView!{
        didSet{ ivProductAdded.imageColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var btnDescription: UIButton!{
        didSet{
            let attr = NSMutableAttributedString()
            attr
                .underlined("מידע נוסף", fontSize: 17, color: AppData.shared.mainColor, alignment: .center)
            btnDescription.setAttributedTitle(attr, for: .normal)
        }
    }
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var lblProductName: UILabel!
    @IBOutlet weak var lblOutOfStock: UILabel!
//    @IBOutlet weak var btnRemoveFromCart: UIButton!{
//        didSet{ btnRemoveFromCart.backgroundColor = AppData.shared.mainColor }
//    }
    
    @IBOutlet weak var btnZoomImage: UIButton! = nil
    
    @IBOutlet weak var constrLeadingMain: NSLayoutConstraint!
    @IBOutlet weak var constrLeadingActiveProduct: NSLayoutConstraint!
    
    @IBOutlet weak var viewOutOfStock: UIView!
    
    
    var viewModel: ProductCell3ViewModel! {
        didSet {
            self.configureCell()
        }
    }
    
    var disposeBag: DisposeBag! = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

    private func configureCell() {
        
        //MARK: - OUTPUTS
//        btnRemoveFromCart.rx.tap.bind(to: viewModel.deleteProduct).disposed(by: disposeBag)
        btnAddToCart.rx.tap.bind(to: viewModel.addToCartDidTap).disposed(by: disposeBag)
        btnPlus.rx.tap.map({ _ in return true }).bind(to: viewModel.minusPlusDidTap).disposed(by: disposeBag)
        btnMinus.rx.tap.map({ _ in return false }).bind(to: viewModel.minusPlusDidTap).disposed(by: disposeBag)
        btnUnitType.rx.tap.map({ return "unit" }).bind(to: viewModel.activeProductChangeUnitTypeDidTap).disposed(by: disposeBag)
        btnDescription.rx.tap.bind(to: viewModel.productDescriptionDidTap).disposed(by: disposeBag)
        btnZoomImage?.rx.tap.bind(to: viewModel.zoomImageDidTap).disposed(by: disposeBag)
        
        //MARK: - INPUTS
        viewModel.product
            .flatMap({ RequestManager.shared.rx_sd_image(imageUrl: $0.image) })
            .bind(to: ivProduct.rx.animated.fade(duration: 0.5).image)
            .disposed(by: disposeBag)

        viewModel.product.map({ $0.name }).bind(to: lblProductName.rx.text).disposed(by: disposeBag)

        viewModel.imageProductStatus.bind(to: ivProductStatus.rx.image).disposed(by: disposeBag)

        viewModel.isInCart.map({ !$0 }).bind(to: ivProductAdded.rx.isHidden).disposed(by: disposeBag)
        viewModel.isInCart.subscribe(onNext: { [weak self] _isInCart in

            UIView.animate(withDuration: 0.2) {
                self?.btnAddToCart.setTitle(_isInCart ? "עדכן סל" : "הוסף לסל", for: .normal)
                self?.ivPlus.image = _isInCart ? UIImage(named: "white_pen") : UIImage(named: "white_plus")
                self?.constrLeadingMain.priority = _isInCart ? UILayoutPriority(750) : UILayoutPriority(1000)
                self?.constrLeadingActiveProduct.priority = _isInCart ? UILayoutPriority(1000) : UILayoutPriority(750)
                self?.layoutIfNeeded()
            }

        }).disposed(by: disposeBag)

//        viewModel.isInCart.map({ !$0 }).bind(to: btnRemoveFromCart.rx.isHidden).disposed(by: disposeBag)

        viewModel.productStatus.map({ $0 == .outOfStock ? false : true }).bind(to: viewOutOfStock.rx.animated.fade(duration: 0.5).isHidden).disposed(by: disposeBag)

        viewModel.isActiveProductHidden.bind(to: viewActiveProduct.rx.animated.fade(duration: 0.1).isHidden).disposed(by: disposeBag)

        viewModel.activeProductAmount.map({ $0.clean2 }).bind(to: lblProductAmount.rx.animated.fade(duration: 0.2).text).disposed(by: disposeBag)

        viewModel.isDescriptionBtnHidden.bind(to: btnDescription.rx.isHidden).disposed(by: disposeBag)

        viewModel.availableUnits.subscribe(onNext: { [unowned self] types in
            if types.count == 1 {
                self.btnUnitType.setTitle(types[0] == "kg" ? "ק״ג".localized : "יח׳".localized, for: .normal)
                self.btnUnitType.isUserInteractionEnabled = false
            }
        }).disposed(by: disposeBag)

//        viewModel.cartProduct.map { cartProduct -> String? in
//            if cartProduct?.product?.type == .pack {
//                return "1"
//            }
//            return cartProduct?.unitType == "kg" ? cartProduct?.amount.clean : Int(cartProduct?.amount ?? 0).toString
//        }.map { [weak self] _amount -> String? in
//            var amount = _amount
//            if let level = self?.viewModel.level {
//                if let levelProductsAmount = AppData.shared.currentPack.value?.levels.first(where: { $0.id == level.id })?.selectedProducts.filter({ $0.productID == self?.viewModel.product.value.id }).count {
//                    amount = levelProductsAmount.toString
//                }
//            }
//            self?.lblAmount.isHidden = amount == "0"
//            return amount
//        }.bind(to: lblAmount.rx.text).disposed(by: disposeBag)

        viewModel.product.map({ $0.defaultUnitType == "kg" ? "ק״ג".localized : "יח׳".localized }).bind(to: btnUnitType.rx.title()).disposed(by: disposeBag)

        viewModel.product
        .map({ _prod in
            _prod.unitTypes.first(where: { $0.type == _prod.defaultUnitType })?.price
        })
        .map({ $0?.clean })
        .bind(to: lblPrice.rx.text)
        .disposed(by: disposeBag)
        
    }
    
}
