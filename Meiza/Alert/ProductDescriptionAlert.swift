//
//  ProductDescriptionAlert.swift
//  Meiza
//
//  Created by Denis Windover on 03/08/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ProductDescriptionAlert: AlertVC {
    
    @IBOutlet weak var ivProduct: UIImageView!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var btnClose: UIButton!
    
    var product: Product!
    var cartProduct: CartProduct!

    override func viewDidLoad() {
        super.viewDidLoad()

        btnClose.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: nil)
        }).disposed(by: disposeBag)
        
        if product != nil {
            Observable.just(product)
                .flatMap({ RequestManager.shared.rx_sd_image(imageUrl: $0.image) })
                .bind(to: ivProduct.rx.animated.fade(duration: 0.5).image)
                .disposed(by: disposeBag)
            
            Observable.just(product).map({ $0?.description }).bind(to: lblDescription.rx.text).disposed(by: disposeBag)
        }else{
            Observable.just(cartProduct)
                .flatMap({ RequestManager.shared.rx_sd_image(imageUrl: $0.product?.image) })
                .bind(to: ivProduct.rx.animated.fade(duration: 0.5).image)
                .disposed(by: disposeBag)
            
            Observable.just(cartProduct).map({ $0?.comment }).bind(to: lblDescription.rx.text).disposed(by: disposeBag)
        }
        
        
        
        
    }

}
