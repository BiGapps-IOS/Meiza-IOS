//
//  ShopAlert.swift
//  Meiza
//
//  Created by Denis Windover on 12/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import SDWebImage

class ShopAlert: AlertVC {
    
    @IBOutlet weak var ivShop: UIImageView!
    @IBOutlet weak var lblDescription: UILabel!{
        didSet{
            lblDescription.text = shop.description
        }
    }
    
    var shop: Shop!
    var enter: ()->() = {}

    override func viewDidLoad() {
        super.viewDidLoad()
        ivShop.sd_setImage(with: URL(string: shop.image ?? ""), completed: nil)
    }

    @IBAction func btnEnterTapped(_ sender: UIButton) {
        self.dismiss { [weak self] in
            self?.enter()
        }
    }
    
    @IBAction func btnTryAgain(_ sender: UIButton) {
        User.logout()
        dismiss(completion: nil)
    }
}
