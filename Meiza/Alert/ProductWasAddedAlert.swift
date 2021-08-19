//
//  ProductWasAddedAlert.swift
//  Meiza
//
//  Created by Denis Windover on 11/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import SDWebImage

class ProductWasAddedAlert: AlertVC {
    
    @IBOutlet weak var ivProduct: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!{
        didSet{
            lblTitle.text = message
        }
    }
    
    var imageUrl: String?
    var message: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ivProduct.sd_setImage(with: URL(string: imageUrl ?? ""), completed: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            self.dismiss(completion: nil)
        }
    }

}
