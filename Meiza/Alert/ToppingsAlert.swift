//
//  ToppingsAlert.swift
//  Meiza
//
//  Created by Denis Windover on 27/08/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift


class ToppingAlertViewModel {
    
    let disposeBg          = DisposeBag()
    let product:             Product
    var existsToppings      = BehaviorRelay<(existToppings: [[Topping]], product: Product?, withNewItem: Bool)>(value: (existToppings: [], product: nil, withNewItem: false))
    var dismissAlert       = PublishSubject<Void>()
    var existsPizzaToppings = BehaviorRelay<(existPizzaToppings: [[PizzaTopping]], product: Product?, withNewItem: Bool)>(value: (existPizzaToppings: [], product: nil, withNewItem: false))
    var level: Level?
    var existLevelProduct: CartProduct?
    var isProductForReplacing = false
    
    init(_ product: Product, level: Level? = nil, existLevelProduct: CartProduct? = nil, isProductForReplacing: Bool = false){
        
        self.isProductForReplacing = isProductForReplacing
        self.product = product
        self.level = level
        self.existLevelProduct = existLevelProduct
        
        configure()
        
    }
    
    func configure(_ withNewItem: Bool = false, dismiss: Bool = false){
        product.type == .regular ? configureToppings(withNewItem, dismiss: dismiss) : configurePizza(withNewItem, dismiss: dismiss)
    }
    
    private func configureToppings(_ withNewItem: Bool, dismiss: Bool){
        
        if let _ = level {
            
            if let levelProduct = existLevelProduct {
                existsToppings.accept((existToppings: levelProduct.toppings, product: product, withNewItem: withNewItem))
            }else{
                if dismiss{
                    dismissAlert.onNext(())
                }else{
                    existsToppings.accept((existToppings: [], product: product, withNewItem: withNewItem))
                }
            }
            
        }else{
            
            if let cartProduct = AppData.shared.cartProducts.value.first(where: { $0.productID == product.id }) {
                existsToppings.accept((existToppings: cartProduct.toppings, product: product, withNewItem: withNewItem))
            }else{
                if dismiss{
                    dismissAlert.onNext(())
                }else{
                    existsToppings.accept((existToppings: [], product: product, withNewItem: withNewItem))
                }
            }
            
        }
        
    }
    
    private func configurePizza(_ withNewItem: Bool, dismiss: Bool){
            
        if let _ = level {
            
            if let levelProduct = existLevelProduct {
                existsPizzaToppings.accept((existPizzaToppings: levelProduct.pizzaToppings, product: product, withNewItem: withNewItem))
            }else{
                if dismiss{
                    dismissAlert.onNext(())
                }else{
                    existsPizzaToppings.accept((existPizzaToppings: [], product: product, withNewItem: withNewItem))
                }
            }
            
        }else{
            if let cartProduct = AppData.shared.cartProducts.value.first(where: { $0.productID == product.id }) {
                existsPizzaToppings.accept((existPizzaToppings: cartProduct.pizzaToppings, product: product, withNewItem: withNewItem))
            }else{
                if dismiss {
                    dismissAlert.onNext(())
                }else{
                    existsPizzaToppings.accept((existPizzaToppings: [], product: product, withNewItem: withNewItem))
                }
            }
        }
        
    }
    
    
}


class ToppingsAlert: AlertVC {
    
    
    @IBOutlet weak var viewScrollView: UIView!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    
    
    var scrollView: UIScrollView!
    
    var viewModel: ToppingAlertViewModel!
    let toppingSizeG = CGSize(width: WIDTH - 32, height: (WIDTH - 32) / 0.686)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let toppingSize = toppingSizeG

        scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: toppingSize.width, height: toppingSize.height))
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        viewScrollView.addSubview(scrollView)
        
        btnClose.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: nil)
        }).disposed(by: disposeBag)
        
        Observable.combineLatest(viewModel.existsToppings, viewModel.existsPizzaToppings){ [weak self] _toppings, _pizzaToppings -> Any in
            return self?.viewModel.product.type == .pizza ? _pizzaToppings : _toppings
        }.subscribe(onNext: { [weak self] data in
            
            var existToppings = [Any]()
            var product: Product!
            var withNewItem: Bool!
            
            if let regularToppings = data as? (existToppings: [[Topping]], product: Product?, withNewItem: Bool) {
                existToppings = regularToppings.existToppings
                product = regularToppings.product
                withNewItem = regularToppings.withNewItem
            }
            else if let pizzaToppings = data as? (existPizzaToppings: [[PizzaTopping]], product: Product?, withNewItem: Bool) {
                existToppings = pizzaToppings.existPizzaToppings
                product = pizzaToppings.product
                withNewItem = pizzaToppings.withNewItem
            }
            
            self?.scrollView?.subviews.forEach({ $0.removeFromSuperview() })

            var tag = 1
            self?.pageControl.currentPage = 0

            var frame = CGRect(x: 0, y: 0, width: toppingSize.width, height: toppingSize.height)

            if existToppings.count > 0 {

                existToppings.forEach { _ in
                    let pizzaToppingView = ToppingView(frame: frame, product: product, tag: tag, level: self?.viewModel.level, existLevelProduct: self?.viewModel.existLevelProduct, isProductForReplacing: self?.viewModel.isProductForReplacing == true)
                    self?.scrollView?.addSubview(pizzaToppingView)
                    frame = CGRect(x: toppingSize.width * CGFloat(tag), y: 0, width: toppingSize.width, height: toppingSize.height)
                    tag += 1

                }

                if withNewItem {
                    let pizzaToppingView = ToppingView(frame: frame, product: product, tag: tag, level: self?.viewModel.level, existLevelProduct: self?.viewModel.existLevelProduct, isProductForReplacing: self?.viewModel.isProductForReplacing == true)
                    self?.scrollView?.addSubview(pizzaToppingView)
                }else{
                    tag -= 1
                }

            }else{
                let pizzaToppingViewNew = ToppingView(frame: frame, product: product, tag: tag, level: self?.viewModel.level, existLevelProduct: self?.viewModel.existLevelProduct, isProductForReplacing: self?.viewModel.isProductForReplacing == true)
                self?.scrollView?.addSubview(pizzaToppingViewNew)
            }

            self?.scrollView?.contentSize = CGSize(width: toppingSize.width * CGFloat(tag), height: toppingSize.height)
            self?.scrollView?.contentOffset = CGPoint.init(x: toppingSize.width * CGFloat(tag) - toppingSize.width, y: 0)

            self?.configurePageControl()
            
        }).disposed(by: disposeBag)
        
        viewModel.dismissAlert.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: nil)
        }).disposed(by: disposeBag)
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let tag = round(scrollView.contentOffset.x) / toppingSizeG.width < 1 ? 1 : Int(round(scrollView.contentOffset.x) / toppingSizeG.width) + 1
        NotificationCenter.default.post(name: NSNotification.Name.init("productOptionsAlert"), object: tag)
    }
    
    private func configurePageControl(){
        
        pageControl.currentPageIndicatorTintColor = AppData.shared.mainColor
        pageControl.numberOfPages = Int(scrollView.contentSize.width / toppingSizeG.width)
        
    }


}

extension ToppingsAlert: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print(scrollView.contentOffset.x)
        print(scrollView.frame.size.width)
        let pageNumber = round(scrollView.contentSize.width - scrollView.contentOffset.x) / toppingSizeG.width
        pageControl.currentPage = Int(pageNumber) - 1
        let tag = round(scrollView.contentOffset.x) / toppingSizeG.width < 1 ? 1 : Int(round(scrollView.contentOffset.x) / toppingSizeG.width) + 1
        NotificationCenter.default.post(name: NSNotification.Name.init("productOptionsAlert"), object: tag)
    }
    
}
