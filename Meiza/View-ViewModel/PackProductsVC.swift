//
//  PackProductsVC.swift
//  Meiza
//
//  Created by Denis Windover on 10/01/2021.
//  Copyright © 2021 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxDataSources


class PackProductsViewModel {
    
    let disposeBag = DisposeBag()
    var cartProductAmout = BehaviorRelay<Int>(value: 0)
    var overallPrice = BehaviorRelay<Double>(value: 0)
    var packData: SharedSequence<DriverSharingStrategy, [ProductSection]>
    var title: Observable<String?>
    var levelProductDidSelect = PublishSubject<CartProduct>()
    var pack: CartProduct
    var deleteLevelProductDidTap = PublishSubject<CartProduct>()
    
    init(_ pack: CartProduct) {
        
        self.pack = pack
        
        AppData.shared.editingPack.accept(pack)
        
        packData = AppData.shared.editingPack.map({ _pack -> [ProductSection] in
            var sections = [ProductSection]()
            
            _pack?.levels.forEach({ level in
                let header = level.description
                let section = ProductSection(header: header, items: level.selectedProducts)
                sections.append(section)
            })
            
            return sections
        }).asDriver(onErrorJustReturn: [])
        
        title = Observable.just(pack.product?.name)
        
        AppData.shared.cartProducts.map({ $0.filter({ $0.product != nil }) }).map({ $0.filter({ $0.amount > 0 && $0.isChosen }).count }).bind(to: cartProductAmout).disposed(by: disposeBag)
        
        AppData.shared.overallPrice.map({ $0.withCoupon }).bind(to: overallPrice).disposed(by: disposeBag)
        
        deleteLevelProductDidTap.subscribe(onNext: { _levelProduct in
            
            AlertCoordinator.shared.removeProductFromCart {
                guard let level = AppData.shared.editingPack.value?.levels.first(where: { $0.selectedProducts.contains(where: { $0._tmpID == _levelProduct._tmpID }) }) else { return }
                AppData.shared.currentActiveProduct.accept(nil)
                Coordinator.shared.level(level, levelProductToDelete: _levelProduct)
            }
            
        }).disposed(by: disposeBag)
        
        levelProductDidSelect.subscribe(onNext: { _levelProduct in
            
            guard let product = pack.levels.map({ return $0.products }).first(where: { $0.contains(where: { $0.id == _levelProduct.productID }) })?.first(where: { $0.id == _levelProduct.productID }),
                  let level = AppData.shared.editingPack.value?.levels.first(where: { $0.selectedProducts.contains(where: { $0._tmpID == _levelProduct._tmpID }) })
            else{ return }
            
            _levelProduct.setProduct(product)
            
            if _levelProduct.product?.type == .pizza || _levelProduct.product?.toppings.count ?? 0 > 0 {
                AlertCoordinator.shared.toppings(product, level: level, existLevelProduct: _levelProduct, isProductForReplacing: false)
            }else{
                AlertCoordinator.shared.removeProductFromCart {
                    guard let level = AppData.shared.editingPack.value?.levels.first(where: { $0.selectedProducts.contains(where: { $0._tmpID == _levelProduct._tmpID }) }) else { return }
                    
                    Coordinator.shared.level(level, levelProductToDelete: _levelProduct)
                }
            }
            
        }).disposed(by: disposeBag)
        
    }
    
    func getProduct(_ id: Int) -> Product? {
        
        var product: Product?
        
        pack.levels.forEach { level in
            if let _product = level.products.first(where: { $0.id == id }) {
                product = _product
            }
        }
        return product
    }
    
    
}


class PackProductsVC: BaseVC {
    
    
    @IBOutlet weak var viewCart: UIView!{
        didSet{ viewCart.backgroundColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var lblCartProductsAmount: UILabel!{
        didSet{ lblCartProductsAmount.backgroundColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var lblOverallPrice: UILabel!
    
    @IBOutlet weak var lblPackDescription: UILabel!
    @IBOutlet weak var tblLevels: UITableView!
    
    
    var viewModel: PackProductsViewModel!
    
    lazy var dataSource: RxTableViewSectionedReloadDataSource<ProductSection> = {
        let dataSource = RxTableViewSectionedReloadDataSource<ProductSection>(configureCell: { [unowned self] (_, tableView, indexPath, cartProduct) -> ProductCell2 in
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell2", for: indexPath) as! ProductCell2
            cell.viewModel = ProductCell2ViewModel(cartProduct, product: self.viewModel.getProduct(cartProduct.productID)!, isCart: false)
            return cell
        })
        
        return dataSource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("deleteLevelProduct"), object: nil, queue: .main) { [weak self] _not in
            guard let levelProduct = _not.object as? CartProduct else{ return }
            self?.viewModel.deleteLevelProductDidTap.onNext(levelProduct)
        }

        tblLevels.rx.setDelegate(self).disposed(by: disposeBag)
        
        tblLevels.rx.itemSelected.map({ [unowned self] indexPath in self.dataSource.sectionModels[indexPath.section].items[indexPath.row] }).bind(to: viewModel.levelProductDidSelect).disposed(by: disposeBag)
        
        
        
        //MARK: - INPUTS
        viewModel.cartProductAmout.map({ $0.toString }).bind(to: lblCartProductsAmount.rx.animated.fade(duration: 0.5).text).disposed(by: disposeBag)
        
        viewModel.overallPrice.map({ $0.clean }).bind(to: lblOverallPrice.rx.animated.fade(duration: 0.5).text).disposed(by: disposeBag)
        
        viewModel.packData.drive(tblLevels.rx.items(dataSource: dataSource)).disposed(by: disposeBag)
        
        viewModel.title.bind(to: lblPackDescription.rx.text).disposed(by: disposeBag)
        
    }

}

//MARK: - TABLEVIEW DELEGATE
extension PackProductsVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let height = dataSource.sectionModels[section].header.height(withConstrainedWidth: WIDTH-32, font: UIFont(name: "Heebo-Bold", size: 20)!)
        let lbl = UILabel(frame: CGRect(x: 0, y: 0, width: WIDTH-32, height: height))
        lbl.text = dataSource.sectionModels[section].header
        lbl.textAlignment = .center
        lbl.font = UIFont(name: "Heebo-Bold", size: 20)
        lbl.textColor = .white
        lbl.numberOfLines = 0
        
        return lbl
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let height = dataSource.sectionModels[section].header.height(withConstrainedWidth: WIDTH-32, font: UIFont(name: "Heebo-Bold", size: 20)!)
        return height
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as? ProductCell2)?.ivProduct.image = nil
    }

}
