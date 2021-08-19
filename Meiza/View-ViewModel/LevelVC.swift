//
//  LevelVC.swift
//  Meiza
//
//  Created by Denis Windover on 04/01/2021.
//  Copyright © 2021 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import UPCarouselFlowLayout

// TO DO:
// UI cells for pack
// btn delete from cart updated for deleting levelproduct from level

class LevelViewModel {
    
    let disposeBag = DisposeBag()
    var product = BehaviorRelay<Product?>(value: nil)
    var levelProducts = BehaviorRelay<[Product]>(value: [])
    var level = BehaviorRelay<Level?>(value: nil)
    var title: Observable<String?>
    var levelIndex = 0
    var newLevelProduct = BehaviorRelay<CartProduct?>(value: nil)
    var isNeedToDeleteAllLevelProducts = true
    
    init(_ level: Level, levelProductToDelete levelProduct: CartProduct){
        
        isNeedToDeleteAllLevelProducts = false
        
        title = Observable.just(level.description)
        
        self.level.accept(level)
        
        levelProducts.accept(level.products)
        
        newLevelProduct.filter({ $0 != nil }).subscribe(onNext: { _cartProduct in
            
            var _indexToReplace: Int?
            
            for i in 0..<level.selectedProducts.count {
                let oldProduct = level.selectedProducts[i]
                if oldProduct._tmpID == levelProduct._tmpID {
                    _indexToReplace = i
                }
            }
            
            guard let indexToReplace = _indexToReplace, let cartProduct = _cartProduct else{ return }
            
            level.selectedProducts[indexToReplace] = cartProduct
            AppData.shared.editingPack.accept(AppData.shared.editingPack.value)
            Coordinator.shared.goBack()
            CartProduct.saveCartProducts(AppData.shared.cartProducts.value)
            
        }).disposed(by: disposeBag)
        
    }
    
    init(_ product: Product, cartProduct: CartProduct, levelIndex: Int = 0){
        
        self.product.accept(product)
        
        self.levelIndex = levelIndex
        
        if cartProduct.productID == 0 {
            cartProduct.productID = product.id
            cartProduct.setProduct(product)
        }
        if AppData.shared.currentPack.value != cartProduct {
            AppData.shared.currentPack.accept(cartProduct)
        }
        
        title = level.map({ $0?.description })
        
        self.product.map({ $0?.levels.index(levelIndex) }).bind(to: level).disposed(by: disposeBag)
        
        levelProducts.accept(product.levels.index(levelIndex)?.products ?? [])
    
        
    }
    
    func setLevelIndex(){
        guard let pack = AppData.shared.currentPack.value else{ return }
        pack.currentLevelIndex = self.levelIndex
        AppData.shared.currentPack.accept(pack)
    }
    
}


class LevelVC: BaseVC {
    
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var viewContent: UIView!
    
    var viewModel: LevelViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("replaceLevelProduct"), object: nil, queue: .main) { [weak self] _not in
            guard let newLevelProduct = _not.object as? CartProduct, let `self` = self else{ return }
            self.viewModel.newLevelProduct.accept(newLevelProduct)
            DispatchQueue.main.async {
                AlertCoordinator.shared.productWasAdded("update", imageUrl: AppData.shared.editingPack.value?.product?.image)
            }
        }

        //MARK: - HELPERS
        configureProductsUI()
        
        //MARK: - OUTPUTS
        btnBack.rx.tap.subscribe(onNext: { [unowned self] _ in
            
            guard let pack = AppData.shared.currentPack.value, self.viewModel.isNeedToDeleteAllLevelProducts else{ return }
            
            for i in 0..<pack.levels.count {
                
                if i >= self.viewModel.levelIndex || self.viewModel.levelIndex - 1 == i && i >= 0 {
                    pack.levels.index(i)?.selectedProducts.removeAll()
                }
                
            }
            
            var toDeletePack = true
            pack.levels.forEach({ _lvl in
                if _lvl.selectedProducts.count > 0 {
                    toDeletePack = false
                }
            })

            if toDeletePack && !NAV.viewControllers.contains(where: { $0 is LevelVC }) {
                AppData.shared.currentPack.accept(nil)
            }
            
        }).disposed(by: disposeBag)
        
        //MARK: - INPUTS
        viewModel.title.bind(to: lblTitle.rx.text).disposed(by: disposeBag)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.setLevelIndex()
    }
    
    fileprivate func configureProductsUI(){
        
        let products = ProductListView.getProductListView()
        
        viewContent.addSubview(products)
        
        products.translatesAutoresizingMaskIntoConstraints = false
        
        var anchors = [NSLayoutConstraint]()
            anchors.append(viewContent.topAnchor.constraint(equalTo: products.topAnchor, constant: 0))
            anchors.append(viewContent.leadingAnchor.constraint(equalTo: products.leadingAnchor, constant: 0))
            anchors.append(viewContent.trailingAnchor.constraint(equalTo: products.trailingAnchor, constant: 0))
            anchors.append(viewContent.bottomAnchor.constraint(equalTo: products.bottomAnchor, constant: 0))
            NSLayoutConstraint.activate(anchors)
        
        if AppData.shared.shop.layout == 1 || AppData.shared.shop.layout == 4 {
            products.tblView.register(UINib(nibName:"ProductCell2", bundle: nil), forCellReuseIdentifier: "ProductCell2")
            products.tblView.rx.setDelegate(self).disposed(by: disposeBag)
        }else if AppData.shared.shop.layout == 2 {
            products.collView.rx.setDelegate(self).disposed(by: disposeBag)
        }else if AppData.shared.shop.layout == 3 {
            products.collView.rx.setDelegate(self).disposed(by: disposeBag)
            let width = WIDTH / 1.5
            let height = width / 0.8
            let layout = UPCarouselFlowLayout()
            layout.scrollDirection = .horizontal
            layout.spacingMode = UPCarouselFlowLayoutSpacingMode.fixed(spacing: 10)
            layout.itemSize = CGSize(width: width, height: height)
            products.collView.collectionViewLayout = layout
            products.collView.showsHorizontalScrollIndicator = false
        }
        
        if AppData.shared.shop.layout == 1 || AppData.shared.shop.layout == 4 {
            viewModel.levelProducts.bind(to: products.tblView.rx.items(cellIdentifier: "ProductCell2", cellType: ProductCell2.self)){ [weak self] item, product, cell in
                cell.viewModel = ProductCell2ViewModel(product, level: self?.viewModel.level.value, isProductForReplacing: self?.viewModel.isNeedToDeleteAllLevelProducts == false)
            }.disposed(by: disposeBag)
        }else{
            viewModel.levelProducts.bind(to: products.collView.rx.items(cellIdentifier: "ProductCell", cellType: ProductCell.self)){ [weak self] item, product, cell in
                cell.viewModel = ProductCellViewModel(product, isCart: false, level: self?.viewModel.level.value, isProductForReplacing: self?.viewModel.isNeedToDeleteAllLevelProducts == false)
                cell.viewModel.isLevelVC.accept(true)
            }.disposed(by: disposeBag)
        }
        
    }

}

//MARK: - TABLEVIEW DELEGATE
extension LevelVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as? ProductCell2)?.ivProduct.image = nil
    }

}

//MARK: - COLLECTIONVIEW DELEGATE
extension LevelVC: UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = AppData.shared.shop.layout == 2 ? (WIDTH - 16) / 2 : WIDTH / 1.5
        let height = width / 0.8
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if AppData.shared.shop.layout == 3 {
            AppData.shared.playScrollSound()
        }
    }
    
}
