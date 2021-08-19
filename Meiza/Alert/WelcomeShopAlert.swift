//
//  WelcomeShopAlert.swift
//  Meiza
//
//  Created by Denis Windover on 24/11/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift

class WelcomeShopAlert: AlertVC {
    
    
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var ivLogo: UIImageView!
    @IBOutlet weak var btnStart: UIButton!
    @IBOutlet weak var lblDeliveryTime: UILabel!
    @IBOutlet weak var ivDeliveryIcon: UIImageView!
    @IBOutlet weak var ivIsMakingDelivery: UIImageView!
    
    var shop: ShopBasic!
    var actionStart: ()->() = {}

    override func viewDidLoad() {
        super.viewDidLoad()

        btnClose.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: nil)
        }).disposed(by: disposeBag)
        
        btnStart.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: {
                self?.actionStart()
            })
        }).disposed(by: disposeBag)
        
        RequestManager.shared.rx_sd_image(imageUrl: shop.image).asObservable().bind(to: ivLogo.rx.image).disposed(by: disposeBag)
     
        Observable.just(shop.address).bind(to: lblAddress.rx.text).disposed(by: disposeBag)
        
        Observable.just(shop.name).map({ return "\("היי! הגעת ל-".localized)\($0)" }).bind(to: lblName.rx.text).disposed(by: disposeBag)
        
        Observable.just(shop.deliveryTime).bind(to: lblDeliveryTime.rx.text).disposed(by: disposeBag)
        Observable.just(shop.deliveryTime == nil).bind(to: ivDeliveryIcon.rx.isHidden).disposed(by: disposeBag)
        Observable.just(shop.isMakingDelivery ? UIImage(named: "green_circle") : UIImage(named: "red_circle")).bind(to: ivIsMakingDelivery.rx.image).disposed(by: disposeBag)
    }

}
