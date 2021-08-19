//
//  ProductListView.swift
//  Meiza
//
//  Created by Denis Windover on 26/07/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit

class ProductListView: UIView {

    @IBOutlet weak var tblView: UITableView!
    @IBOutlet weak var collView: UICollectionView!
    
    
    static func getProductListView() -> ProductListView {
        
        let view = UINib(nibName: "ProductListView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! ProductListView
        
        if AppData.shared.shop.layout == 1 {
            view.tblView.register(UINib(nibName:"ProductCell2", bundle: nil), forCellReuseIdentifier: "ProductCell2")
            view.collView.isHidden = true
        }else if AppData.shared.shop.layout == 4 {
            view.tblView.register(UINib(nibName:"ProductCell3", bundle: nil), forCellReuseIdentifier: "ProductCell3")
            view.collView.isHidden = true
        }else{
            view.collView.register(UINib(nibName:"ProductCell", bundle: nil), forCellWithReuseIdentifier: "ProductCell")
            view.tblView.isHidden = true
        }
        
        return view
        
    }

}
