//
//  OrdersVC.swift
//  Meiza
//
//  Created by Denis Windover on 19/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

//MARK: - VIEWMODEL
class OrdersViewModel {
    
    let disposeBag          = DisposeBag()
    let orders              = BehaviorRelay<[Order]>(value: [])
    var orderDidTap         = PublishSubject<IndexPath>()
    var isOrdersEmptyHidden = BehaviorRelay<Bool>(value: true)
    var popToMainDidTap     = PublishSubject<Void>()
    
    init(_ orderID: Int? = nil){
        
        var _orderID = orderID
        
        orders.subscribe(onNext: { orders in
            guard let id = _orderID else{ return }
            if let order = orders.first(where: { $0.id == id }) {
                Coordinator.shared.pushOrder(order, animated: false)
                _orderID = nil
            }
        }).disposed(by: disposeBag)
        
        orders.skip(1).map({ $0.count != 0 }).bind(to: isOrdersEmptyHidden).disposed(by: disposeBag)
        
        RequestManager.shared.ordersHistory().map({ $0.orders.sorted(by: { $0.createdDate > $1.createdDate }) }).bind(to: orders).disposed(by: disposeBag)
        
        orderDidTap
            .map({ [weak self] indexPath in return self?.orders.value[indexPath.row] })
            .subscribe(onNext: { _order in
                guard let order = _order else{ return }
                Coordinator.shared.pushOrder(order)
            }).disposed(by: disposeBag)
        
        popToMainDidTap.subscribe(onNext: { _ in
            Coordinator.shared.popMain(1)
        }).disposed(by: disposeBag)
        
        
        
    }
    
}

//MARK: - VIEW
class OrdersVC: BaseVC {
    
    @IBOutlet weak var tblViewOrders: UITableView!
    @IBOutlet weak var viewOrdersEmpty: UIView!
    @IBOutlet weak var btnPopToMain: UIButton!
    
    
    var viewModel = OrdersViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        //MARK: - OUTPUTS
        tblViewOrders.rx.itemSelected.bind(to: viewModel.orderDidTap).disposed(by: disposeBag)
        btnPopToMain.rx.tap.bind(to: viewModel.popToMainDidTap).disposed(by: disposeBag)
        
        //MARK: - INPUTS
        viewModel.orders.bind(to: tblViewOrders.rx.items(cellIdentifier: "OrderCell", cellType: OrderCell.self)){ row, order, cell in
            cell.viewModel = OrderCellViewModel(order)
        }.disposed(by: disposeBag)
        
        viewModel.isOrdersEmptyHidden.bind(to: viewOrdersEmpty.rx.animated.fade(duration: 0.5).isHidden).disposed(by: disposeBag)
    }

}
