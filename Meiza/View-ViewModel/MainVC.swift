//
//  MainVC.swift
//  Meiza
//
//  Created by Denis Windover on 06/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxAnimated
import RxGesture
import RxDataSources
import UPCarouselFlowLayout

struct PagingData {
    
    var isLoading = BehaviorRelay<Bool>(value: false)
    var page = BehaviorRelay<Int>(value: 1)
    var itemDidLoad = PublishSubject<Int>()
    var loadedAllItems = BehaviorRelay<Bool>(value: false)
    
}

//MARK: - VIEWMODEL
class MainViewModel {
    
    let disposeBag                       = DisposeBag()
    var currentCategoryIndex             = BehaviorRelay<Int>(value: AppData.shared.shop.categories.count - 1)
    var pagingData: [String: PagingData] = [:]
    var cartProductAmout                 = BehaviorRelay<Int>(value: 0)
    var clearActiveProduct               = PublishSubject<Void>()
    var isInactiveHidden                 = BehaviorRelay<Bool>(value: true)
    var overallPrice                     = BehaviorRelay<Double>(value: 0)
    var cartProductDidSelect             = PublishSubject<CartProduct>()
    var isCartEmptyHidden                = BehaviorRelay<Bool>(value: true)
    var orderID: Int?
    var subcategories                    = BehaviorRelay<[Subcategory]>(value: [])
    var activeSubcategory                = BehaviorRelay<Subcategory?>(value: nil)
    var subcategoryDidSelect             = PublishSubject<IndexPath>()
    
    init(){
        
        for cat in AppData.shared.categoryProducts {
            guard let key = cat.first?.key else{ return }
            pagingData[key] = PagingData()
        }
        
        for (key, value) in pagingData {
            
            value.itemDidLoad.subscribe(onNext: { itemIndex in
                if (AppData.shared.categoryProducts.first(where: { $0.first?.key == key })?.first?.value.value.count ?? 0) - 10 == itemIndex && !value.isLoading.value {
                    value.isLoading.accept(true)
                }
            }).disposed(by: disposeBag)
            
            value.isLoading.filter({ $0 == true }).map({ _ in return User.currentUser?.shopID ?? 0 }).flatMap { shopID in
                return RequestManager.shared.getProductsByPage(value.page.value + 1, category: key)
            }.subscribe(onNext: { result in
                if !value.loadedAllItems.value{
                    if let _products = result.products, _products.count > 0 {
                        let currProduct = AppData.shared.categoryProducts.first(where: { $0.first?.key == key })?.first?.value.value ?? []
                        AppData.shared.categoryProducts.first(where: { $0.first?.key == key })?.first?.value.accept(currProduct + _products)
                        value.page.accept(value.page.value + 1)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    value.isLoading.accept(false)
                }
                
            }).disposed(by: disposeBag)
            
            
        }
        
        // reload data
        currentCategoryIndex.filter({ $0 == 0 }).map({ _ in return AppData.shared.cartProducts.value }).bind(to: AppData.shared.cartProducts).disposed(by: disposeBag)
        
        AppData.shared.cartProducts.map({ $0.filter({ $0.product != nil }) }).map({ !$0.isEmpty }).bind(to: isCartEmptyHidden).disposed(by: disposeBag)
        
//        isChosenAllDidTap.map({ [unowned self] _ in self.isChosenAll.value }).subscribe(onNext: { lastValue in
//            CartProduct.updateIsChosenAllObjects(!lastValue)
//        }).disposed(by: disposeBag)
        
        AppData.shared.cartProducts.map({ $0.filter({ $0.product != nil }) }).map({ $0.filter({ $0.amount > 0 && $0.isChosen }).count }).bind(to: cartProductAmout).disposed(by: disposeBag)
        
        AppData.shared.overallPrice.map({ $0.withCoupon }).bind(to: overallPrice).disposed(by: disposeBag)
        
        AppData.shared.currentActiveProduct.map({ $0 == nil }).bind(to: isInactiveHidden).disposed(by: disposeBag)
        
        currentCategoryIndex.map({ _ in return nil }).bind(to: AppData.shared.currentActiveProduct).disposed(by: disposeBag)
        
        clearActiveProduct.map({ _ in return nil }).bind(to: AppData.shared.currentActiveProduct).disposed(by: disposeBag)
        
        cartProductDidSelect.filter({ $0.productID != AppData.shared.currentActiveProduct.value?.id }).map({ $0.product }).bind(to: AppData.shared.currentActiveProduct).disposed(by: disposeBag)
        
        
        subcategoryDidSelect.withLatestFrom(subcategories, resultSelector: { $1.index($0.item) }).bind(to: activeSubcategory).disposed(by: disposeBag)
        
        currentCategoryIndex.map({ _ in return nil }).bind(to: activeSubcategory).disposed(by: disposeBag)
        
    }
    
    func isNeedToGoToOrders(){
        guard let id = orderID else{ return }
        Coordinator.shared.pushOrders(id)
        self.orderID = nil
    }
    
    func reloadCartData(){
        AppData.shared.cartProducts.accept(AppData.shared.cartProducts.value)
    }
    
}

//MARK: - VIEW
class MainVC: BaseVC {
    
    
    @IBOutlet weak var stackView: UIStackView!
    
    
    @IBOutlet weak var lblCartProductsAmount: UILabel! {
        didSet{ lblCartProductsAmount.backgroundColor = AppData.shared.mainColor }
    }
    

    @IBOutlet weak var btnCart: UIButton!
    
    @IBOutlet weak var constrWidthCategoriesView: NSLayoutConstraint!
    @IBOutlet weak var constrTrailingCategoriesView: NSLayoutConstraint!
    
    @IBOutlet weak var lblOverallPrice: UILabel!
    
    @IBOutlet weak var categoriesView: CategoriesView!{
        didSet {
            categoriesView.configureCategories(AppData.shared.shop.categories)
            categoriesView.categories.forEach { catView in
                catView.btnChooseCategory.rx.tap.map({ _ in catView.tag }).bind(to: viewModel.currentCategoryIndex).disposed(by: disposeBag)
            }
            viewModel.currentCategoryIndex.bind(to: categoriesView.currentCategoryIndex).disposed(by: disposeBag)
            categoriesView.subcategories.bind(to: viewModel.subcategories).disposed(by: disposeBag)
        }
    }
    
    @IBOutlet weak var collCategories: UICollectionView!
    
    
    @IBOutlet weak var bottomView: UIView!{
        didSet{ bottomView.backgroundColor = AppData.shared.mainColor }
    }
    
    @IBOutlet weak var constrHeightCategoriesView: NSLayoutConstraint!
    @IBOutlet weak var constrWidthBackBtn: NSLayoutConstraint!
    @IBOutlet weak var viewMain: UIView!
    
    @IBOutlet weak var btnHebrew: UIButton!{
        didSet{ btnHebrew.backgroundColor = currentLanguage == "en" ? .white : .clear }
    }
    @IBOutlet weak var btnFrench: UIButton!{
        didSet{ btnFrench.backgroundColor = currentLanguage == "fr" ? .white : .clear }
    }
    
    @IBOutlet weak var constrHeightSubcategories: NSLayoutConstraint!
    @IBOutlet weak var viewSubcategories: UIView!{
        didSet{ viewSubcategories.backgroundColor = AppData.shared.mainColor }
    }
    
    @IBOutlet weak var btnAccessibility: UIButton!
    @IBOutlet weak var viewNoAccessibilities: UIView!{
        didSet{ self.viewNoAccessibilities.alpha = AppData.shared.accessibilityLink != nil && AppData.shared.accessibilityLink?.isEmpty == false ? 1 : 0 }
    }
    
    
    var viewModel = MainViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collCategories.rx.setDelegate(self).disposed(by: disposeBag)
        collCategories.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        
        if NAV.viewControllers.count == 1 { constrWidthBackBtn.constant = 0 }
        
        AppData.shared.calculatePrices()
        
        configureProductListsUI()
        
        isPushNotificationStatusNotDetermined { _notDetermined in
            DispatchQueue.main.async {
                if _notDetermined{ AlertCoordinator.shared.pushNotification() }
            }
        }

        constrWidthCategoriesView.constant = WIDTH * CGFloat(AppData.shared.categoryProducts.count)
        
        //MARK: - OUTPUTS
        collCategories.rx.itemSelected.bind(to: viewModel.subcategoryDidSelect).disposed(by: disposeBag)
        collCategories.rx.itemSelected.subscribe(onNext: { [weak self] _indexPath in
            if self?.categoriesView.subcategories.value.count ?? 0 > 3 {
                self?.collCategories.scrollToItem(at: _indexPath, at: .centeredHorizontally, animated: true)
            }
        }).disposed(by: disposeBag)
        
        btnAccessibility.rx.tap.subscribe(onNext:{ _ in
            if let url = URL(string: AppData.shared.accessibilityLink ?? ""){
                UIApplication.shared.open(url)
            }
        }).disposed(by: self.disposeBag)
        
        btnAccessibility.rx.swipeGesture(.right).when(.recognized).bind { _ in
            self.viewNoAccessibilities.alpha = 0
        }.disposed(by: disposeBag)
        
        btnHebrew.rx.tap.subscribe(onNext: { _ in
            if currentLanguage == "en" { return }
            currentLanguage = "en"
            Loader.show()
            _ = AppDelegate.getMainDelegate().application(UIApplication.shared, didFinishLaunchingWithOptions: [:])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                _ = AppDelegate.getMainDelegate().application(UIApplication.shared, didFinishLaunchingWithOptions: [:])
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                Loader.dismiss()
                Coordinator.shared.pushSplash()
            }
        }).disposed(by: disposeBag)
        
        btnFrench.rx.tap.subscribe(onNext: { _ in
            if currentLanguage == "fr" { return }
            currentLanguage = "fr"
            Loader.show()
            _ = AppDelegate.getMainDelegate().application(UIApplication.shared, didFinishLaunchingWithOptions: [:])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                _ = AppDelegate.getMainDelegate().application(UIApplication.shared, didFinishLaunchingWithOptions: [:])
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                Loader.show()
                Coordinator.shared.pushSplash()
            }
        }).disposed(by: disposeBag)
        
        btnCart.rx.tap.subscribe(onNext: { _ in
            AppData.shared.currentActiveProduct.accept(nil)
            Coordinator.shared.pushCart()
        }).disposed(by: disposeBag)
        
        
        //MARK: - INPUTS
        viewModel.cartProductAmout.map({ $0.toString }).bind(to: lblCartProductsAmount.rx.animated.fade(duration: 0.5).text).disposed(by: disposeBag)
        
        viewModel.currentCategoryIndex.map({ -(CGFloat($0) * WIDTH) }).bind(to: constrTrailingCategoriesView.rx.animated.layout(duration: 0.3).constant).disposed(by: disposeBag)

        viewModel.currentCategoryIndex.subscribe(onNext: { [weak self] index in
            self?.categoriesView.categories.forEach({ $0.viewCircle.backgroundColor = $0.tag == index ? .white : .clear })
        }).disposed(by: disposeBag)

        viewModel.currentCategoryIndex.skip(1).subscribe(onNext: { [unowned self] index in
            if (self.categoriesView.scrollView?.contentSize.width ?? 0) > WIDTH{
                let halfScreen = (WIDTH / 2) - (categoryIconViewWidth / 2)
                if CGFloat(index) * categoryIconViewWidth > halfScreen && (CGFloat(index) * categoryIconViewWidth) + ((WIDTH / 2) + (categoryIconViewWidth / 2)) < (self.categoriesView.scrollView?.contentSize.width ?? 0) {
                    UIView.animate(withDuration: 0.3) {
                        self.categoriesView.scrollView?.contentOffset = CGPoint(x: CGFloat(index) * categoryIconViewWidth - halfScreen, y: 0)
                    }
                }else if index == 0 || index == 1 || index == 2 {
                    UIView.animate(withDuration: 0.3) {
                        self.categoriesView.scrollView?.contentOffset = CGPoint(x: 0, y: 0) // scroll to start
                    }
                }else if index == self.categoriesView.categories.count - 1 || index == self.categoriesView.categories.count - 2 || index == self.categoriesView.categories.count - 3 {
                    UIView.animate(withDuration: 0.3) {
                        self.categoriesView.scrollView?.contentOffset = CGPoint(x: (self.categoriesView.scrollView?.contentSize.width ?? 0) - WIDTH, y: 0) // scroll to end
                    }
                }
            }
        }).disposed(by: disposeBag)
        
        viewModel.overallPrice.map({ $0.clean }).bind(to: lblOverallPrice.rx.animated.fade(duration: 0.5).text).disposed(by: disposeBag)
        
        viewModel.subcategories.map({ $0.count == 0 ? 0 : 40 }).bind(to: constrHeightSubcategories.rx.animated.layout(duration: 0.5).constant).disposed(by: disposeBag)
        
        viewModel.subcategories.bind(to: collCategories.rx.items(cellIdentifier: "SubcategoryCell", cellType: SubcategoryCell.self)){ [unowned self] item, subcategory, cell in
            cell.contentView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            cell.viewModel = SubcategoryCellViewModel(subcategory)
            viewModel.activeSubcategory.map({ $0?.codename == subcategory.codename ? .black : .white }).bind(to: cell.btnSubcategory.rx.animated.fade(duration: 0.5).titleColor).disposed(by: cell.disposeBag)
            viewModel.activeSubcategory.map({ $0?.codename == subcategory.codename ? .white : .clear }).bind(to: cell.btnSubcategory.rx.backgroundColor).disposed(by: cell.disposeBag)
        }.disposed(by: disposeBag)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reloadCartData()
        viewModel.isNeedToGoToOrders()
        viewModel.clearActiveProduct.onNext(())
        
        constrHeightCategoriesView.constant = AppData.shared.categoryProducts.count == 1 ? 0 : WIDTH / 4.16
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

}

//MARK: - HELPERS
extension MainVC {
    
    fileprivate func configureProductListsUI() {
        
        
        for categoryProducts in AppData.shared.categoryProducts.reversed() {
            
            let newCat = ProductListView.getProductListView()
            
            stackView.addArrangedSubview(newCat)
            
            if AppData.shared.shop.layout == 1 {
                newCat.tblView.rx.setDelegate(self).disposed(by: disposeBag)
            }else if AppData.shared.shop.layout == 2 {
                newCat.collView.rx.setDelegate(self).disposed(by: disposeBag)
            }else if AppData.shared.shop.layout == 3 {
                newCat.collView.rx.setDelegate(self).disposed(by: disposeBag)
                let width = WIDTH / 1.5
                let height = width / 0.8
                let layout = UPCarouselFlowLayout()
                layout.scrollDirection = .horizontal
                layout.spacingMode = UPCarouselFlowLayoutSpacingMode.fixed(spacing: 10)
                layout.itemSize = CGSize(width: width, height: height)
                newCat.collView.collectionViewLayout = layout
                newCat.collView.showsHorizontalScrollIndicator = false
            }else if AppData.shared.shop.layout == 4 {
                newCat.tblView.rx.setDelegate(self).disposed(by: disposeBag)
            }
            
            
            for (key, value) in categoryProducts {
                if AppData.shared.shop.layout == 1 {
                    Observable.combineLatest(value, viewModel.activeSubcategory){ _products, _activeSubcategory -> [Product] in
                        if key == AppData.shared.shop.getCodenameByCategoryId(_activeSubcategory?.parentId) {
                            return _products.filter({ $0.subcategoryCodename == _activeSubcategory?.codename })
                        }
                        return _products
                    }.bind(to: newCat.tblView.rx.items(cellIdentifier: "ProductCell2", cellType: ProductCell2.self)){ [weak self] item, product, cell in
                        cell.viewModel = ProductCell2ViewModel(product)
                        self?.viewModel.pagingData[key]?.itemDidLoad.onNext(item)
                    }.disposed(by: disposeBag)
                }else if AppData.shared.shop.layout == 4 {
                    Observable.combineLatest(value, viewModel.activeSubcategory){ _products, _activeSubcategory -> [Product] in
                        if key == AppData.shared.shop.getCodenameByCategoryId(_activeSubcategory?.parentId) {
                            return _products.filter({ $0.subcategoryCodename == _activeSubcategory?.codename })
                        }
                        return _products
                    }.bind(to: newCat.tblView.rx.items(cellIdentifier: "ProductCell3", cellType: ProductCell3.self)){ [weak self] item, product, cell in
                        cell.viewModel = ProductCell3ViewModel(product)
                        self?.viewModel.pagingData[key]?.itemDidLoad.onNext(item)
                    }.disposed(by: disposeBag)
                }else{
                    Observable.combineLatest(value, viewModel.activeSubcategory){ _products, _activeSubcategory -> [Product] in
                        if let pagingData = self.viewModel.pagingData["category_\(_activeSubcategory?.parentId ?? 0)"]{
                            AppData.shared.loadAllCategoryProducts(_activeSubcategory?.parentId?.toString ?? "", pagingData: pagingData)
                        }
                        if key == AppData.shared.shop.getCodenameByCategoryId(_activeSubcategory?.parentId) {
                            return _products.filter({ $0.subcategoryCodename == _activeSubcategory?.codename })
                        }
                        return _products
                    }.bind(to: newCat.collView.rx.items(cellIdentifier: "ProductCell", cellType: ProductCell.self)){ [weak self] item, product, cell in
                        cell.viewModel = ProductCellViewModel(product)
                        self?.viewModel.pagingData[key]?.itemDidLoad.onNext(item)
                    }.disposed(by: disposeBag)
                    
                }
                
            }
            
            
        }
        
    }
    
}

//MARK: - TABLEVIEW DELEGATE
extension MainVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as? ProductCell2)?.ivProduct.image = nil
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if AppData.shared.shop.layout == 4 {
            return WIDTH
        }
        return 120
    }

}

//MARK: - COLLECTIONVIEW DELEGATE
extension MainVC: UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == collCategories {
            let subcategory = viewModel.subcategories.value.index(indexPath.item)
            let width = (subcategory?.name?.widthOfString(usingFont: UIFont(name: "Heebo-Regular", size: 16)!) ?? 0) + 16
            return CGSize(width: width, height: collectionView.bounds.height)
        }
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
