//
//  CategoryView.swift
//  FFApp
//
//  Created by Denis Windover on 08/11/2018.
//  Copyright © 2018 bigapps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift


class CategoryView: UIView {

    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var viewCircle: UIView!
    @IBOutlet weak var ivIcon: UIImageView!
    @IBOutlet weak var lblCategory: UILabel!
    @IBOutlet weak var btnChooseCategory: UIButton!
    
    var category: Category!
    var disposeBag = DisposeBag()
    
    init(frame:CGRect, category:Category) {
        super.init(frame: frame)
        self.category = category
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit(){
        Bundle.main.loadNibNamed("CategoryView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        RequestManager.shared.rx_sd_image(imageUrl: category.icon).asObservable().bind(to: ivIcon.rx.image).disposed(by: disposeBag)
        
    }
    
    func configureView(_ tag: Int){
        
        self.tag = tag
        viewCircle.cornerRadius = (WIDTH / 5.5 - 6) / 2
        viewCircle.borderWidth = 2
        viewCircle.borderColor = .white
        lblCategory.text = category.name
        
    }
    
}
