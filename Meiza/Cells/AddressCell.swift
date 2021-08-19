//
//  AddressCell.swift
//  Meiza
//
//  Created by Denis Windover on 09/11/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class AddressCellViewModel {
    
    var attributedAddress = BehaviorRelay<NSAttributedString?>(value: nil)
    
    deinit {
        print("-------DEINIT---------")
        print(self)
        print("-------DEINIT---------")
    }
    
    init(address: Address){
        
        let attrText = NSMutableAttributedString()
        attrText
            .normal(address.mainText + "\n", fontSize: 18, color: .black, alignment: .right)
            .normal(address.secondaryText, fontSize: 16, color: .black, alignment: .right)
        
        attributedAddress.accept(NSAttributedString(attributedString: attrText))
        
    }
    
}

class AddressCell: UITableViewCell {
    
    
    @IBOutlet weak var lblAddress: UILabel!
    
    var viewModel: AddressCellViewModel! {
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
        
        viewModel.attributedAddress.bind(to: lblAddress.rx.attributedText).disposed(by: disposeBag)
        
    }

}
