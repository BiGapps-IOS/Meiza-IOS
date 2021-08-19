//
//  ToppingCell.swift
//  Meiza
//
//  Created by Denis Windover on 27/08/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit

class ToppingCell: UITableViewCell {
    
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var viewCheckbox: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
