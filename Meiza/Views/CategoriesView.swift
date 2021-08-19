//
//  CategoriesView.swift
//  Meiza
//
//  Created by Denis Windover on 26/08/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift



let categoryIconViewWidth:CGFloat = WIDTH / 5.5

class CategoriesView: UIView, UIScrollViewDelegate {
    
    var scrollView:UIScrollView?
    let midPage = WIDTH / 2
    let startPointX:CGFloat = categoryIconViewWidth * 0.25
    var categories = [CategoryView]()
    
    let currentCategoryIndex = BehaviorRelay<Int>(value: 0)
    let subcategories = BehaviorRelay<[Subcategory]>(value: [])
    let disposeBag = DisposeBag()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init (frame : CGRect) {
        super.init(frame: frame)
    }
    
    func configureCategories(_ categories:[Category]){
        
        
        currentCategoryIndex.map { _index -> [Subcategory] in
            return categories.reversed()[_index].subcategories
        }.bind(to: subcategories).disposed(by: disposeBag)
        
        self.backgroundColor = AppData.shared.mainColor
        
        let categoryCount = categories.count
        var startX:CGFloat = 0
        if categoryCount < 6{
            switch categoryCount{
            case 1:
                startX = startPointX + (categoryIconViewWidth * 2)
            case 2:
                startX = midPage - categoryIconViewWidth
            case 3:
                startX = startPointX + categoryIconViewWidth
            case 4:
                startX = midPage - (categoryIconViewWidth * 2)
            case 5:
                startX = startPointX
            default:break
            }
            
            for i in 0..<categoryCount{
                let frame = CGRect(x: startX + (categoryIconViewWidth*CGFloat(i)), y: 0, width: categoryIconViewWidth, height: self.frame.height)
                let categoryView = CategoryView(frame: frame, category: categories.reversed()[i])
                categoryView.tag = i
                categoryView.configureView(i)
                self.addSubview(categoryView)
                self.categories.append(categoryView)
            }
        }else{
            scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: WIDTH, height: self.frame.height))
            scrollView?.showsHorizontalScrollIndicator = false
            for i in 0..<categoryCount{
                let frame = CGRect(x: categoryIconViewWidth*CGFloat(i), y: 0, width: categoryIconViewWidth, height: self.frame.height)
                let categoryView = CategoryView(frame: frame, category: categories.reversed()[i])
                categoryView.configureView(i)
                scrollView?.addSubview(categoryView)
                self.categories.append(categoryView)
            }
            scrollView?.contentSize = CGSize.init(width: categoryIconViewWidth * CGFloat(categoryCount), height: self.frame.height)
            scrollView!.contentOffset = CGPoint.init(x: scrollView!.contentSize.width - scrollView!.frame.width, y: 0)
            self.addSubview(scrollView!)
        }
    }

}
