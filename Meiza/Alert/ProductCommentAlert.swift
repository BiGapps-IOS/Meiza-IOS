//
//  ProductCommentAlert.swift
//  Meiza
//
//  Created by Denis Windover on 03/08/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

let COMMENT_PLACEHOLDER = "כתוב את ההערה שלך כאן |".localized

class ProductCommentAlert: AlertVC {
    
    
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var txtViewComment: UITextView!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnSave: UIButton!{
        didSet{
            btnSave.setTitleColor(AppData.shared.mainColor, for: .normal)
            btnSave.borderColor = AppData.shared.mainColor
        }
    }
    
    var cartProduct: CartProduct!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtViewComment.becomeFirstResponder()
        
        Observable.just(cartProduct.comment).subscribe(txtViewComment.rx.text).disposed(by: disposeBag)

        txtViewComment.rx.text.orEmpty.scan("", accumulator: { return $1.containsEmoji || $1.count > 50 ? ($0 ?? "") : $1 }).subscribe(txtViewComment.rx.text).disposed(by: disposeBag)
        
        btnClose.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: nil)
        }).disposed(by: disposeBag)
        
        btnCancel.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: nil)
        }).disposed(by: disposeBag)
        
        btnSave.rx.tap.subscribe(onNext: { [weak self] _ in
            var comment = self?.txtViewComment.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if comment?.isEmpty == true {
                comment = nil
            }
            self?.cartProduct.setComment(comment)
            self?.dismiss(completion: nil)
        }).disposed(by: disposeBag)
        
    }
    
    var didLoad = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didLoad {
            didLoad = true
            txtViewComment.dropShadow()
        }
    }

}
