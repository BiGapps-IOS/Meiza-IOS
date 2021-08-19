//
//  CartCell.swift
//  Meiza
//
//  Created by Denis Windover on 11/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxAnimated


class CartCellViewModel {
    
    let disposeBag                        = DisposeBag()
    var cartProduct:                        BehaviorRelay<CartProduct>
    var productPrice                      = BehaviorRelay<String?>(value: nil)
    var isChosenDidTap                    = PublishSubject<Void>()
    var clearActiveProduct                = PublishSubject<Void>()
    var activeProductChangeUnitTypeDidTap = PublishSubject<String>()
    var minusPlusDidTap                   = PublishSubject<Bool>()
    var addToCartFinal                    = PublishSubject<Void>()
    var deleteProduct                     = PublishSubject<Void>()
    var isActiveProductHidden             = BehaviorRelay<Bool>(value: true)
    var activeProductUnitType             = BehaviorRelay<String>(value: "")
    var activeProductAmount               = BehaviorRelay<Double>(value: 0.0)
    var isKgEnabled                       = BehaviorRelay<Bool>(value: false)
    var isUnitEnabled                     = BehaviorRelay<Bool>(value: false)
    
    deinit {
        print("-------DEINIT---------")
        print(self)
        print("-------DEINIT---------")
    }
    
    init(_ cartProduct: CartProduct){
        
        self.cartProduct = BehaviorRelay(value: cartProduct)
        
        self.cartProduct.map { _cartProduct -> String? in
            let price = _cartProduct.product?.unitTypes.first(where: { $0.type == _cartProduct.product?.defaultUnitType })?.price
            let unitType = _cartProduct.product?.defaultUnitType == "kg" ? "לק״ג".localized : "ליח׳".localized
            return "\((price ?? 0).clean) \(unitType)"
        }.bind(to: productPrice).disposed(by: disposeBag)

        self.cartProduct.map({ $0.product?.defaultUnitType ?? "" }).bind(to: activeProductUnitType).disposed(by: disposeBag)

        isChosenDidTap.subscribe(onNext: { [weak self] _ in
            CartProduct.updateIsChosen(for: self?.cartProduct.value)
        }).disposed(by: disposeBag)

        addToCartFinal.subscribe(onNext: { [weak self] _ in
            guard let `self` = self else{ return }

            CartProduct.addToCart(cartProduct.product, amount: self.activeProductAmount.value, unitType: self.activeProductUnitType.value)
            self.clearActiveProduct.onNext(())

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                AlertCoordinator.shared.productWasAdded("update", imageUrl: self.cartProduct.value.product?.image)
            }

        }).disposed(by: disposeBag)

        deleteProduct.subscribe(onNext: { [weak self] _ in
            AlertCoordinator.shared.removeProductFromCart { [weak self] in
                CartProduct.removeProductFromCart(self?.cartProduct.value.product, cartProduct: self?.cartProduct.value)
                self?.clearActiveProduct.onNext(())
            }
        }).disposed(by: disposeBag)

        clearActiveProduct.map({ _ in return nil }).bind(to: AppData.shared.currentActiveProduct).disposed(by: disposeBag)

        activeProductChangeUnitTypeDidTap.filter({ _ in return cartProduct.product?.unitTypes.count == 2 }).map({ newValue in return cartProduct.product?.unitTypes.first(where: { $0.type == newValue })?.type ?? "kg" }).bind(to: activeProductUnitType).disposed(by: disposeBag)

        minusPlusDidTap.subscribe(onNext: { [weak self] _isPlus in
            guard let `self` = self else{ return }
            if _isPlus {
                self.activeProductAmount.accept((self.activeProductAmount.value + (self.cartProduct.value.product?.unitTypes.first(where: { $0.type == self.activeProductUnitType.value })?.multiplier ?? 0)).rounded2fD )
            }else{
                if self.activeProductAmount.value > (self.cartProduct.value.product?.unitTypes.first(where: { $0.type == self.activeProductUnitType.value })?.multiplier ?? 0){
                    self.activeProductAmount.accept((self.activeProductAmount.value - (self.cartProduct.value.product?.unitTypes.first(where: { $0.type == self.activeProductUnitType.value })?.multiplier ?? 0)).rounded2fD )
                }
            }
        }).disposed(by: disposeBag)

        deleteProduct.subscribe(onNext: { [weak self] _ in
            AlertCoordinator.shared.removeProductFromCart { [weak self] in
                CartProduct.removeProductFromCart(cartProduct.product, cartProduct: self?.cartProduct.value)
                self?.clearActiveProduct.onNext(())
            }
        }).disposed(by: disposeBag)

        AppData.shared.currentActiveProduct.subscribe(onNext: { [weak self] _product in

            if let _prod = _product {
                if _prod.id == self?.cartProduct.value.product?.id {
                    self?.isActiveProductHidden.accept(false)
                    if let _existProd = AppData.shared.cartProducts.value.first(where: { $0.productID == self?.cartProduct.value.product?.id }) {
                        self?.activeProductUnitType.accept(_existProd.unitType)
                        self?.activeProductAmount.accept(_existProd.amount)
                    }
                }else{
                    self?.isActiveProductHidden.accept(true)
                }
            }else{
                self?.isActiveProductHidden.accept(true)
            }
        }).disposed(by: disposeBag)

        activeProductUnitType.map { [weak self] _type in
            if let _existProd = AppData.shared.cartProducts.value.first(where: { $0.productID == self?.cartProduct.value.product?.id }), _existProd.unitType == _type {
                return _existProd.amount
            }else{
                return self?.cartProduct.value.product?.unitTypes.first(where: { $0.type == _type })?.multiplier ?? 0.0
            }
        }.bind(to: activeProductAmount).disposed(by: disposeBag)

        activeProductUnitType.map({ [weak self] _type in self?.cartProduct.value.product?.unitTypes.count == 2 && _type == "kg" }).bind(to: isUnitEnabled).disposed(by: disposeBag)

        activeProductUnitType.map({ [weak self] _type in self?.cartProduct.value.product?.unitTypes.count == 2 && _type != "kg" }).bind(to: isKgEnabled).disposed(by: disposeBag)
        
    }
    
}


class CartCell: UITableViewCell {
    
    
    @IBOutlet weak var viewMain: UIView!
    @IBOutlet weak var btnCheckbox: UIButton!
    @IBOutlet weak var ivProduct: UIImageView!
    @IBOutlet weak var lblOverallPrice: UILabel!
    @IBOutlet weak var lblUnitType: UILabel!
    @IBOutlet weak var lblAmount: UILabel!
    @IBOutlet weak var lblProductName: UILabel!{
        didSet{ lblProductName.textColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var lblPrice: UILabel!
    
    @IBOutlet weak var viewActiveProduct: UIView!
    @IBOutlet weak var btnCloseActiveProduct: UIButton!
    @IBOutlet weak var btnDelete: UIButton!
    @IBOutlet weak var btnToCartFinal: UIButton!
    @IBOutlet weak var btnMinus: UIButton!
    @IBOutlet weak var lblProductAmount: UILabel!{
        didSet{ lblProductAmount.textColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var btnPlus: UIButton!
    
    @IBOutlet weak var btnUnitsUnitType: UIButton!
    @IBOutlet weak var btnKgUnitType: UIButton!
    @IBOutlet weak var viewUnits: UIView!{
        didSet{ viewUnits.borderColor = AppData.shared.mainColor }
    }
    
    @IBOutlet weak var lblUpdate: UILabel!{
        didSet{ lblUpdate.textColor = AppData.shared.mainColor }
    }
    
    
    
    var viewModel: CartCellViewModel! {
        didSet {
            self.configureCell()
        }
    }
    
    var disposeBag: DisposeBag! = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        viewMain.dropShadow()
    }
    
    private func configureCell(){
        
        //MARK: - OUTPUTS
        btnCheckbox.rx.tap.bind(to: viewModel.isChosenDidTap).disposed(by: disposeBag)
        btnCloseActiveProduct.rx.tap.bind(to: viewModel.clearActiveProduct).disposed(by: disposeBag)
        btnPlus.rx.tap.map({ _ in return true }).bind(to: viewModel.minusPlusDidTap).disposed(by: disposeBag)
        btnMinus.rx.tap.map({ _ in return false }).bind(to: viewModel.minusPlusDidTap).disposed(by: disposeBag)
        btnToCartFinal.rx.tap.bind(to: viewModel.addToCartFinal).disposed(by: disposeBag)
        btnDelete.rx.tap.bind(to: viewModel.deleteProduct).disposed(by: disposeBag)
        btnUnitsUnitType.rx.tap.map({ return "unit" }).bind(to: viewModel.activeProductChangeUnitTypeDidTap).disposed(by: disposeBag)
        btnKgUnitType.rx.tap.map({ return "kg" }).bind(to: viewModel.activeProductChangeUnitTypeDidTap).disposed(by: disposeBag)
        
        //MARK: - INPUTS
        viewModel.cartProduct
            .flatMap({ RequestManager.shared.rx_sd_image(imageUrl: $0.product?.image) })
            .bind(to: ivProduct.rx.animated.fade(duration: 0.5).image)
            .disposed(by: disposeBag)
        
        viewModel.cartProduct.map({ $0.product?.name }).bind(to: lblProductName.rx.text).disposed(by: disposeBag)
        
        viewModel.productPrice.bind(to: lblPrice.rx.text).disposed(by: disposeBag)
        
        viewModel.cartProduct.map({ $0.amount.clean }).bind(to: lblAmount.rx.text).disposed(by: disposeBag)
        
        viewModel.cartProduct.map({ $0.unitType == "kg" ? "ק״ג".localized : "יח׳".localized }).bind(to: lblUnitType.rx.text).disposed(by: disposeBag)
        
        viewModel.cartProduct.map({ $0.price.clean }).bind(to: lblOverallPrice.rx.text).disposed(by: disposeBag)
        
        viewModel.cartProduct.map({ $0.isChosen == true ? UIImage(named: "blue_chekbox")?.imageWithColor(color1: AppData.shared.mainColor) : nil }).bind(to: btnCheckbox.rx.animated.fade(duration: 0.5).image).disposed(by: disposeBag)
        
        viewModel.isActiveProductHidden.bind(to: viewActiveProduct.rx.animated.fade(duration: 0.1).isHidden).disposed(by: disposeBag)
        
        viewModel.activeProductUnitType.subscribe(onNext: { [weak self] unitType in
            guard let `self` = self else{ return }
            if unitType == "kg" {
                self.btnKgUnitType.backgroundColor = AppData.shared.mainColor
                self.btnKgUnitType.setAttributedTitle(NSMutableAttributedString().normal("ק״ג".localized, fontSize: 19, color: .white), for: .normal)
                self.btnUnitsUnitType.backgroundColor = .clear
                let title = NSMutableAttributedString().strikethrough("יח׳".localized, isStrike: self.viewModel.cartProduct.value.product?.unitTypes.count != 2, fontSize: 19, color: .black)
                self.btnUnitsUnitType.setAttributedTitle(title, for: .normal)
            }else{
                self.btnUnitsUnitType.backgroundColor = AppData.shared.mainColor
                self.btnUnitsUnitType.setAttributedTitle(NSMutableAttributedString().normal("יח׳".localized, fontSize: 19, color: .white), for: .normal)
                self.btnKgUnitType.backgroundColor = .clear
                let title = NSMutableAttributedString().strikethrough("ק״ג".localized, isStrike: self.viewModel.cartProduct.value.product?.unitTypes.count != 2, fontSize: 19, color: .black)
                self.btnKgUnitType.setAttributedTitle(title, for: .normal)
            }
        }).disposed(by: disposeBag)
        
        viewModel.activeProductAmount.map({ $0.clean2 }).bind(to: lblProductAmount.rx.animated.fade(duration: 0.2).text).disposed(by: disposeBag)
        
        viewModel.isKgEnabled.bind(to: btnKgUnitType.rx.isEnabled).disposed(by: disposeBag)
        viewModel.isUnitEnabled.bind(to: btnUnitsUnitType.rx.isEnabled).disposed(by: disposeBag)
        
        viewModel.isKgEnabled.bind(to: btnKgUnitType.rx.isEnabled).disposed(by: disposeBag)
        viewModel.isUnitEnabled.bind(to: btnUnitsUnitType.rx.isEnabled).disposed(by: disposeBag)
        
    }
    
}


