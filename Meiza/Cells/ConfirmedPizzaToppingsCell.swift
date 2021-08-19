//
//  ConfirmedPizzaToppingsCell.swift
//  Meiza
//
//  Created by Denis Windover on 15/11/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit

class ConfirmedPizzaToppingsCell: UITableViewCell {
    
    
    @IBOutlet weak var ivDeleteIcon: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var view: UIView!{
        didSet{ view.backgroundColor = AppData.shared.mainColor }
    }
    
    
}
