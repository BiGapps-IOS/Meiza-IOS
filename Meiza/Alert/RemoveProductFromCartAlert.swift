//
//  RemoveProductFromCartAlert.swift
//  Meiza
//
//  Created by Denis Windover on 11/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit

class RemoveProductFromCartAlert: AlertVC {
    
    
    @IBOutlet weak var btnCancel: UIButton!{
        didSet{ btnCancel.setTitleColor(AppData.shared.mainColor, for: .normal) }
    }
    @IBOutlet weak var btnRemove: UIButton!{
        didSet{
            btnRemove.setTitleColor(AppData.shared.mainColor, for: .normal)
            btnRemove.borderColor = AppData.shared.mainColor
        }
    }
    
    
    var remove: ()->() = {}
    
    @IBAction func btnCancelTapped(_ sender: UIButton) {
        self.dismiss(completion: nil)
    }
    
    @IBAction func btnRemoveTapped(_ sender: UIButton) {
        self.dismiss { [weak self] in
            self?.remove()
        }
    }
    

}
