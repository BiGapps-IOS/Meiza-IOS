//
//  OrderCell.swift
//  Meiza
//
//  Created by Denis Windover on 19/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift


class OrderCellViewModel {
    
    let disposeBag = DisposeBag()
    var order:       Observable<Order>
    
    deinit {
        print("-------DEINIT---------")
        print(self)
        print("-------DEINIT---------")
    }
    
    init(_ order: Order){
        
        self.order = Observable<Order>.just(order)
        
    }
    
    
}


class OrderCell: UITableViewCell {
    
    
    @IBOutlet weak var viewMain: UIView!
    @IBOutlet weak var lblOrderNum: UILabel!{
        didSet{ lblOrderNum.textColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var lblSummary: UILabel!{
        didSet{ lblSummary.textColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var lblDate: UILabel!{
        didSet{ lblDate.textColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var lblDeliveryType: UILabel!{
        didSet{ lblDeliveryType.textColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var lblDeliveryTime: UILabel!{
        didSet{ lblDeliveryTime.textColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var lblOrderStatus: UILabel!{
        didSet{ lblOrderStatus.textColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var ivStatus: UIImageView!
    
    
    var viewModel: OrderCellViewModel! {
        didSet {
            self.configureCell()
        }
    }
    
    var disposeBag: DisposeBag! = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    private func configureCell(){
        
        //MARK: - OUTPUTS

        
        //MARK: - INPUTS
        viewModel.order.map({ $0.id.toString }).bind(to: lblOrderNum.rx.text).disposed(by: disposeBag)
        viewModel.order.map({ $0.createdDate.formattedFullDateString }).bind(to: lblDate.rx.text).disposed(by: disposeBag)
        viewModel.order.map({ "₪" + $0.price.clean }).bind(to: lblSummary.rx.text).disposed(by: disposeBag)
        viewModel.order.map({ $0.statusHebrew }).bind(to: lblOrderStatus.rx.text).disposed(by: disposeBag)
        viewModel.order.map({ $0.statusColor }).bind(to: ivStatus.rx.imageColor).disposed(by: disposeBag)
        viewModel.order.map({ $0.deliveryDateStr }).bind(to: lblDeliveryTime.rx.text).disposed(by: disposeBag)
        viewModel.order.map({ $0.orderTypeHebrew }).bind(to: lblDeliveryType.rx.text).disposed(by: disposeBag)
        
    }

}
