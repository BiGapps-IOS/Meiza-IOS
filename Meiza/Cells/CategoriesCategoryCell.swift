//
//  CategoriesCategoryCell.swift
//  Meiza
//
//  Created by Denis Windover on 26/07/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxAnimated


class CategoriesCategoryCellViewModel {
    
    let disposeBag = DisposeBag()
    var bgColor = BehaviorRelay<UIColor>(value: .clear)
    var name = BehaviorRelay<String?>(value: nil)
    
    
    init(_ categoryCodename: String, currentCategoryIndex: Observable<Int>, index: Int) {
        
        currentCategoryIndex.map({ $0 == index ? .myBlackOp50 : .clear }).bind(to: bgColor).disposed(by: disposeBag)
        Observable.just(AppData.shared.shop.categories.first(where: { $0.codename == categoryCodename })?.name).bind(to: name).disposed(by: disposeBag)
        
    }
    
}


class CategoriesCategoryCell: UICollectionViewCell {
    
    
    @IBOutlet weak var lblCategory: UILabel!
    
    
    var viewModel: CategoriesCategoryCellViewModel! {
        didSet {
            self.configureCell()
        }
    }
    
    var disposeBag: DisposeBag! = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    private func configureCell(){
        
        viewModel.bgColor.bind(to: self.rx.backgroundColor ).disposed(by: disposeBag)
        viewModel.name.bind(to: lblCategory.rx.text).disposed(by: disposeBag)
        
    }
    
}
