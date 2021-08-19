//
//  UsedToppingsAlert.swift
//  Meiza
//
//  Created by Denis Windover on 14/09/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift


class UsedToppingAlertViewModel {
    
    let disposeBg = DisposeBag()
    var existsToppings = BehaviorRelay<(existToppings: [[UsedTopping]], orderProduct: OrderProduct?)>(value: (existToppings: [], orderProduct: nil))
    
    init(_ orderProduct: OrderProduct){
        
        existsToppings.accept((existToppings: [orderProduct.usedToppings], orderProduct: orderProduct))
        
    }
    
    
}


class UsedToppingsAlert: AlertVC {
    
    @IBOutlet weak var viewScrollView: UIView!
    @IBOutlet weak var btnClose: UIButton!
    
        var scrollView: UIScrollView!
        
        var viewModel: UsedToppingAlertViewModel!
        let toppingSizeG = CGSize(width: WIDTH - 32, height: (WIDTH - 32) / 0.686)

        override func viewDidLoad() {
            super.viewDidLoad()
            
            let toppingSize = toppingSizeG

            scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: toppingSize.width, height: toppingSize.height))
            scrollView.isPagingEnabled = true
            scrollView.showsHorizontalScrollIndicator = false
            viewScrollView.addSubview(scrollView)
            
            btnClose.rx.tap.subscribe(onNext: { [weak self] _ in
                self?.dismiss(completion: nil)
            }).disposed(by: disposeBag)
            
            viewModel.existsToppings.subscribe(onNext: { [weak self] _toppings in
                self?.scrollView?.subviews.forEach({ $0.removeFromSuperview() })
                guard _toppings.orderProduct != nil else{ return }
                let tag = 1
                let frame = CGRect(x: 0, y: 0, width: toppingSize.width, height: toppingSize.height)
                
                let toppingViewNew = OrderToppingView(frame: frame, orderProduct: _toppings.orderProduct!)
                self?.scrollView?.addSubview(toppingViewNew)
                
                
                self?.scrollView?.contentSize = CGSize(width: toppingSize.width * CGFloat(tag), height: toppingSize.height)
                self?.scrollView?.contentOffset = CGPoint.init(x: toppingSize.width * CGFloat(tag) - toppingSize.width, y: 0)
                
            }).disposed(by: disposeBag)
            
            
        }


    }

