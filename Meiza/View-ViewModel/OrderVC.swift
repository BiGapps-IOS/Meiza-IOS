//
//  OrderVC.swift
//  Meiza
//
//  Created by Denis Windover on 20/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources


//MARK: - VIEWMODEL
class OrderViewModel {
    
    let disposeBag = DisposeBag()
    var products:    SharedSequence<DriverSharingStrategy, [OrderProductSection]>
    var orderNum:    Observable<Int>
    
    
    init(_ order: Order){
        
        products = Observable<[OrderProduct]>.just(order.products).map({ _orderProducts -> [OrderProductSection] in
            
            var sections = [OrderProductSection]()
            
            _orderProducts.forEach { _orderProduct in
                _orderProduct.billLink = order.link
                let header = AppData.shared.shop.categories.first(where: { $0.codename == _orderProduct.product?.category})?.name ?? ""
                if let index = sections.firstIndex(where: { $0.header == header }) {
                    sections[index].items.append(_orderProduct)
                }else{
                    let section = OrderProductSection(header: header, items: [_orderProduct])
                    sections.append(section)
                }
            }
            let sortedSections = sections.sorted { (section1, section2) -> Bool in
                return (section1.items.first?.product?.categoryID ?? 1) < (section2.items.first?.product?.categoryID ?? 1)
            }
            return sortedSections
            
            }).asDriver(onErrorJustReturn: [])
        
        orderNum = Observable.just(order.id)
    }
    
}


//MARK: - VIEW
class OrderVC: BaseVC {
    
    @IBOutlet weak var lblOrderNum: UILabel!
    @IBOutlet weak var tblOrderProducts: UITableView!
    
    var viewModel: OrderViewModel!
    
    
    lazy var dataSource: RxTableViewSectionedReloadDataSource<OrderProductSection> = {
        let dataSource = RxTableViewSectionedReloadDataSource<OrderProductSection>(configureCell: { (_, tableView, indexPath, orderProduct) -> CheckoutCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: "CheckoutCell", for: indexPath) as! CheckoutCell
            cell.viewModel = CheckoutCellViewModel(orderProduct)
            return cell
        })
        
        return dataSource
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tblOrderProducts.rx.setDelegate(self).disposed(by: disposeBag)
        
        //MARK: - INPUTS
        viewModel.products.drive(tblOrderProducts.rx.items(dataSource: dataSource)).disposed(by: disposeBag)
        viewModel.orderNum.map({ "\("הזמנה".localized) #\($0)" }).bind(to: lblOrderNum.rx.text).disposed(by: disposeBag)
        
    }

}

//MARK: - TABLEVIEW DELEGATE
extension OrderVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let height = dataSource.sectionModels[section].header.height(withConstrainedWidth: WIDTH-32, font: UIFont(name: "Heebo-Bold", size: 20)!)
        let lbl = UILabel(frame: CGRect(x: 0, y: 0, width: WIDTH-32, height: height))
        lbl.text = dataSource.sectionModels[section].header
        lbl.textAlignment = .right
        lbl.font = UIFont(name: "Heebo-Bold", size: 20)
        lbl.textColor = .white
        return lbl
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

}
