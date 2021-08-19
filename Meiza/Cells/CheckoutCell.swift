//
//  CheckoutCell.swift
//  Meiza
//
//  Created by Denis Windover on 12/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CheckoutCellViewModel {
    
    let disposeBag             = DisposeBag()
    var cartProduct:             BehaviorRelay<CartProduct>
    var productPrice           = BehaviorRelay<String?>(value: nil)
    var isAddCommentHidden     = BehaviorRelay<Bool>(value: false)
    var isViewCommentHidden    = BehaviorRelay<Bool>(value: true)
    var isEditCommentHidden    = BehaviorRelay<Bool>(value: false)
    var addOrEditCommentDidTap = PublishSubject<Void>()
    var price                  = BehaviorRelay<Double>(value: 0.0)
    var isUsedToppingsHidden   = BehaviorRelay<Bool>(value: true)
    var openUsedToppings       = PublishSubject<Void>()
    
    deinit {
        print("-------DEINIT---------")
        print(self)
        print("-------DEINIT---------")
    }
    
    init(_ cartProduct: CartProduct){
        
        self.cartProduct = BehaviorRelay(value: cartProduct)
        
        self.cartProduct.map({ $0.price }).bind(to: price).disposed(by: disposeBag)
        
        self.cartProduct.map { _cartProduct -> String? in
            let price = _cartProduct.product?.unitTypes.first(where: { $0.type == _cartProduct.product?.defaultUnitType })?.price
            let unitType = _cartProduct.product?.defaultUnitType == "kg" ? "לק״ג".localized : "ליח׳".localized
            return "\((price ?? 0).clean) \(unitType)"
        }.bind(to: productPrice).disposed(by: disposeBag)
        
        self.cartProduct.map({ $0.comment == nil }).bind(to: isViewCommentHidden).disposed(by: disposeBag)
        
        addOrEditCommentDidTap.subscribe(onNext: { _ in
            AlertCoordinator.shared.productComment(cartProduct)
        }).disposed(by: disposeBag)
        
    }
    
    init(_ orderProduct: OrderProduct){
        
        let cartProduct = CartProduct(productID: orderProduct.product.id, amount: orderProduct.amount, unitType: orderProduct.unitType, comment: orderProduct.comment)
        cartProduct.setProduct(orderProduct.product)
        
        self.cartProduct = BehaviorRelay(value: cartProduct)
        
        Observable.just(orderProduct.price).bind(to: price).disposed(by: disposeBag)
        
        Observable.just(orderProduct.usedToppings.count == 0 && orderProduct.product?.type == .regular).bind(to: isUsedToppingsHidden).disposed(by: disposeBag)
        
        isAddCommentHidden.accept(true)
        isEditCommentHidden.accept(true)
        
        self.cartProduct.map({ $0.comment == nil }).bind(to: isViewCommentHidden).disposed(by: disposeBag)
        
        self.cartProduct.map { _cartProduct -> String? in
            let price = _cartProduct.product?.unitTypes.first(where: { $0.type == _cartProduct.product?.defaultUnitType })?.price
            let unitType = _cartProduct.product?.defaultUnitType == "kg" ? "לק״ג".localized : "ליח׳".localized
            return "\((price ?? 0).clean) \(unitType)"
        }.bind(to: productPrice).disposed(by: disposeBag)
        
        addOrEditCommentDidTap.subscribe(onNext: { _ in
            AlertCoordinator.shared.productDescription(nil, cartProduct: cartProduct)
        }).disposed(by: disposeBag)
        
        openUsedToppings.subscribe(onNext: { _ in
//            AlertCoordinator.shared.usedToppings(orderProduct)
            guard let link = orderProduct.billLink else{ return }
            Coordinator.shared.bill(link)
        }).disposed(by: disposeBag)
        
    }
    
}


class CheckoutCell: UITableViewCell {
    
    @IBOutlet weak var viewMain: UIView!
    @IBOutlet weak var ivProduct: UIImageView!
    @IBOutlet weak var lblOverallPrice: UILabel!
    @IBOutlet weak var lblUnitType: UILabel!
    @IBOutlet weak var lblAmount: UILabel!
    @IBOutlet weak var lblProductName: UILabel!{
        didSet{ lblProductName.textColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var lblPrice: UILabel!
    
    @IBOutlet weak var btnAddComment: UIButton!{
        didSet{ btnAddComment.setTitleColor(AppData.shared.mainColor, for: .normal) }
    }
    @IBOutlet weak var viewComment: UIView!
    @IBOutlet weak var lblComment: UILabel!{
        didSet{ lblComment.textColor = AppData.shared.mainColor }
    }
  
    @IBOutlet weak var btnEditComment: UIButton!
    @IBOutlet weak var lblCommentTitle: UILabel!{
        didSet{ lblCommentTitle.textColor = AppData.shared.mainColor }
    }
    
    @IBOutlet weak var btnOpenToppings: UIButton! = nil {
        didSet{ btnOpenToppings.backgroundColor = AppData.shared.mainColor }
    }
    
    var viewModel: CheckoutCellViewModel! {
        didSet {
            self.configureCell()
        }
    }
    
    var disposeBag: DisposeBag! = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    private func configureCell(){
        
        //MARK: - OUTPUTS
        btnAddComment.rx.tap.bind(to: viewModel.addOrEditCommentDidTap).disposed(by: disposeBag)
        btnEditComment.rx.tap.bind(to: viewModel.addOrEditCommentDidTap).disposed(by: disposeBag)
        btnOpenToppings?.rx.tap.bind(to: viewModel.openUsedToppings).disposed(by: disposeBag)
        
        //MARK: - INPUTS
        viewModel.cartProduct
            .flatMap({ RequestManager.shared.rx_sd_image(imageUrl: $0.product?.image) })
            .bind(to: ivProduct.rx.animated.fade(duration: 0.5).image)
            .disposed(by: disposeBag)
        
        viewModel.cartProduct.map({ $0.product?.name }).bind(to: lblProductName.rx.text).disposed(by: disposeBag)
        
        viewModel.productPrice.bind(to: lblPrice.rx.text).disposed(by: disposeBag)
        
        viewModel.cartProduct.map { cartProduct -> String? in
            return cartProduct.unitType == "kg" ? cartProduct.amount.clean : Int(cartProduct.amount).toString
        }.bind(to: lblAmount.rx.text).disposed(by: disposeBag)
        
        viewModel.cartProduct.map({ $0.unitType == "kg" ? "ק״ג".localized : "יח׳".localized }).bind(to: lblUnitType.rx.text).disposed(by: disposeBag)
        
        viewModel.price.map({ $0.clean }).bind(to: lblOverallPrice.rx.text).disposed(by: disposeBag)
        
        viewModel.cartProduct.map({ $0.comment }).bind(to: lblComment.rx.text).disposed(by: disposeBag)
        
        viewModel.isViewCommentHidden.bind(to: viewComment.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.isAddCommentHidden.bind(to: btnAddComment.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.isUsedToppingsHidden.bind(to: (btnOpenToppings ?? UIButton()).rx.isHidden).disposed(by: disposeBag)
        
        
    }
    
}
