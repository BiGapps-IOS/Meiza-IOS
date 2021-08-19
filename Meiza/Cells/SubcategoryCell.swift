//
//  CategoryCell.swift
//  Meiza
//
//  Created by Denis Windover on 13/07/2021.
//  Copyright © 2021 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift


class SubcategoryCellViewModel {
    
    let disposeBag = DisposeBag()
    var subCategory: BehaviorRelay<Subcategory>
    
    init(_ subCategory: Subcategory){
        
        self.subCategory = BehaviorRelay(value: subCategory)
    }
    
}


class SubcategoryCell: UICollectionViewCell {
    

    @IBOutlet weak var btnSubcategory: UIButton!
    
    
    var viewModel: SubcategoryCellViewModel! {
        didSet{
            self.configureCell()
        }
    }
    
    var disposeBag: DisposeBag! = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    private func configureCell(){
        
        viewModel.subCategory.map({ $0.name }).bind(to: btnSubcategory.rx.title()).disposed(by: disposeBag)
        
    }
    
}
