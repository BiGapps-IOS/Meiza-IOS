//
//  TagCell.swift
//  Meiza
//
//  Created by Denis Windover on 22/11/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit

class TagCell: UITableViewCell {
    
    
    @IBOutlet weak var viewTag: UIView!
    @IBOutlet weak var lblName: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
