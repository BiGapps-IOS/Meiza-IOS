//
//  DWInputPicker.swift
//  Meiza
//
//  Created by Denis Windover on 13/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit

class DWInputPicker: UIView {

    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnChoose: UIButton!{
        didSet{ btnChoose.backgroundColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var picker: UIPickerView!
    
    
    static func getFromNib() -> DWInputPicker{
        
        let view = UINib(nibName: "DWInputPicker", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! DWInputPicker
        return view
        
    }

}
