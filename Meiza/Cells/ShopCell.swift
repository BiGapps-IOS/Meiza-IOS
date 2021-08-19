//
//  ShopCell.swift
//  Meiza
//
//  Created by Denis Windover on 22/11/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift

class ShopCell: UICollectionViewCell {
    
    @IBOutlet weak var ivLogo: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblAddress: UILabel!
    @IBOutlet weak var ivIsMakingDelivery: UIImageView!
    @IBOutlet weak var lblDeliveryTime: UILabel!
    @IBOutlet weak var ivDeliveryIcon: UIImageView!
    
    var disposeBag: DisposeBag! = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        ivLogo.image = nil
        disposeBag = DisposeBag()
    }
    
}
