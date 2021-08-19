//
//  ShopsVC.swift
//  Meiza
//
//  Created by Denis Windover on 22/11/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import CoreLocation

class ShopsViewModel {
    
    let disposeBag = DisposeBag()
    private var allShops = BehaviorRelay<[ShopBasic]>(value: [])
    var shops = BehaviorRelay<[ShopBasic]>(value: [])
    var tags = BehaviorRelay<[Tag]>(value: [])
    var title = BehaviorRelay<String>(value: "")
    var selectedTags = BehaviorRelay<[Tag]>(value: [])
    var tmpSelectedTags = BehaviorRelay<[Tag]>(value: [])
    var tagDidSelect = PublishSubject<IndexPath>()
    var shopDidSelect = PublishSubject<IndexPath>()
    var tagsAreClosed = BehaviorRelay<Bool>(value: true)
    var shop = BehaviorRelay<Shop?>(value: nil)
    var location = BehaviorRelay<CLLocation?>(value: nil)
    var openTagsDidTap = PublishSubject<Void>()
    var confirmTagsDidTap = PublishSubject<Void>()
    var didGetLocation = BehaviorRelay<Bool>(value: false)
    var isNoResultsHidden = BehaviorRelay<Bool>(value: true)
    
    init(_ shops: [ShopBasic], tags: [Tag], title: String){
        
        allShops.accept(shops)
        self.tags.accept(tags)
        self.title.accept(title)
        
        Observable.combineLatest(allShops, selectedTags, location, didGetLocation){ _allShops, _selectedTags, _location, _didGetLocation -> [ShopBasic] in
            
            if !_didGetLocation{ return [] }
            
            var arr = [ShopBasic]()
            
            if _selectedTags.count == 0 {
                arr = _allShops
            }else{
                arr = _allShops.filter { shop -> Bool in
                    return _selectedTags.contains(where: { shop.tags.contains($0.id) })
                }
            }
            
            return _location != nil ? arr.sorted(by: { $0.location?.distance(from: _location!) ?? 0 < $1.location?.distance(from: _location!) ?? 0 }) : arr
            
        }.bind(to: self.shops).disposed(by: disposeBag)
        
        Observable.combineLatest(selectedTags, self.shops){ _selectedTags, _shops -> Bool in
            return !(_selectedTags.count > 0 && _shops.count == 0)
        }.bind(to: isNoResultsHidden).disposed(by: disposeBag)
        
        tagDidSelect.withLatestFrom(self.tags) { indexPath, _tags -> Tag in
            return _tags[indexPath.row]
        }.map { [weak self] _tag in
            
            if self?.tmpSelectedTags.value.contains(where: { $0.id == _tag.id }) == true {
                return self?.tmpSelectedTags.value.filter({ $0.id != _tag.id }) ?? []
            }else{
                return (self?.tmpSelectedTags.value ?? []) + [_tag]
            }
        }.bind(to: tmpSelectedTags).disposed(by: disposeBag)
        
        tmpSelectedTags.subscribe(onNext: { [weak self] _ in
            self?.tags.accept(self?.tags.value ?? [])
        }).disposed(by: disposeBag)
        
        shopDidSelect.withLatestFrom(self.shops) { indexPath, _shops in
            return _shops[indexPath.row]
        }.subscribe(onNext: { [weak self] _shop in
            
            AlertCoordinator.shared.welcomeShop(_shop) { [weak self] in
                SHOP_ID = _shop.id
                if LAST_USED_SHOP_ID != SHOP_ID {
                    CartProduct.deleteAllCartProducts()
                    AppData.shared.coupon = nil
                }
                
                self?.setShop()
            }
            
        }).disposed(by: disposeBag)
        
        shop.filter({ $0 != nil }).subscribe(onNext: { [weak self] _shop in
            if User.currentUser == nil {
                User.initCurrentUser(shop: _shop!)
            }
            
            AppData.shared.shop = _shop
            
            if SHOP_ID == LAST_USED_SHOP_ID {
                self?.getProducts(AppData.shared.cartProducts.value.map({ $0.productID }))
            }else{
                self?.getProducts([])
            }
            
        }).disposed(by: disposeBag)
        
        openTagsDidTap.map({ [weak self] _ in self?.tmpSelectedTags.accept(self?.selectedTags.value ?? []); return false }).bind(to: tagsAreClosed).disposed(by: disposeBag)
        
        confirmTagsDidTap.map({ [weak self] _ in self?.selectedTags.accept(self?.tmpSelectedTags.value ?? []); return true }).bind(to: tagsAreClosed).disposed(by: disposeBag)
        
    }
    
    private func setShop(){
        
        RequestManager.shared.setShop().subscribe(onNext: { [weak self] result in
            if let shop = result.shop {
                self?.shop.accept(shop)
            }else if let _ = result.error {
                self?.setShop()
            }
        }).disposed(by: disposeBag)
    }
    
    private func getProducts(_ cartProductIDs: [Int]){
        RequestManager.shared.getProducts(cartProductIDs, loader: false).subscribe(onNext: { result in
            if let products = result.products {
                AppData.shared.categoryProducts = products.categoryProducts
                AppData.shared.products.accept(Set(products.cart))
                
                LAST_USED_SHOP_ID = SHOP_ID
                
                Coordinator.shared.pushMain(false)
                
            }else if let error = result.error {
                error.toast()
            }
        }).disposed(by: disposeBag)
    }
    
}


class ShopsVC: BaseVC {
    
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var btnOpenTags: UIButton!
    @IBOutlet weak var collView: UICollectionView!
    
    @IBOutlet weak var constrLeadingTags: NSLayoutConstraint!
    @IBOutlet weak var btnCloseTags: UIButton!
    @IBOutlet weak var btnConfirmTags: UIButton!{
        didSet{ btnConfirmTags.setTitleColor(AppData.shared.mainColor, for: .normal) }
    }
    @IBOutlet weak var tblTags: UITableView!
    @IBOutlet weak var btnCancelFilter: UIButton!
    @IBOutlet weak var viewCancelFilter: UIView!
    @IBOutlet weak var viewNoResults: UIView!
    @IBOutlet weak var btnAccessibility: UIButton!
    @IBOutlet weak var viewNoAccessibilities: UIView!{
        didSet{ self.viewNoAccessibilities.alpha = AppData.shared.accessibilityLink != nil && AppData.shared.accessibilityLink?.isEmpty == false ? 1 : 0 }
    }
    
    
    private let locationManager:CLLocationManager = CLLocationManager()
    var viewModel: ShopsViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
    
        collView.rx.setDelegate(self).disposed(by: disposeBag)
        constrLeadingTags.constant = WIDTH
        btnOpenTags.rx.tap.bind(to: viewModel.openTagsDidTap).disposed(by: disposeBag)
        btnCloseTags.rx.tap.map({ _ in return true }).bind(to: viewModel.tagsAreClosed).disposed(by: disposeBag)
        btnConfirmTags.rx.tap.bind(to: viewModel.confirmTagsDidTap).disposed(by: disposeBag)
        btnCancelFilter.rx.tap.map({ _ in return [] }).bind(to: viewModel.selectedTags).disposed(by: disposeBag)
        tblTags.rx.itemSelected.bind(to: viewModel.tagDidSelect).disposed(by: disposeBag)
        
        btnAccessibility.rx.tap.asObservable().bind { () in
                if let url = URL(string: AppData.shared.accessibilityLink ?? ""){
                    UIApplication.shared.open(url)
                }
            }.disposed(by: self.disposeBag)
        
        viewModel.title.bind(to: lblTitle.rx.text).disposed(by: disposeBag)
        
        viewModel.shops.bind(to: collView.rx.items(cellIdentifier: "ShopCell", cellType: ShopCell.self)){ item, shop, cell in
            RequestManager.shared.rx_sd_image(imageUrl: shop.image).asObservable().bind(to: cell.ivLogo.rx.image).disposed(by: cell.disposeBag)
            Observable.just(shop.name).bind(to: cell.lblName.rx.text).disposed(by: cell.disposeBag)
            Observable.just(shop.address).bind(to: cell.lblAddress.rx.text).disposed(by: cell.disposeBag)
            Observable.just(shop.deliveryTime).bind(to: cell.lblDeliveryTime.rx.text).disposed(by: cell.disposeBag)
            Observable.just(shop.deliveryTime == nil).bind(to: cell.ivDeliveryIcon.rx.isHidden).disposed(by: cell.disposeBag)
            Observable.just(shop.isMakingDelivery ? UIImage(named: "green_circle") : UIImage(named: "red_circle")).bind(to: cell.ivIsMakingDelivery.rx.image).disposed(by: cell.disposeBag)

        }.disposed(by: disposeBag)
        
        viewModel.tags.bind(to: tblTags.rx.items(cellIdentifier: "TagCell", cellType: TagCell.self)){ [unowned self] item, tag, cell in
            
            cell.lblName.text = tag.name
            cell.lblName.textColor = self.viewModel.tmpSelectedTags.value.contains(where: { $0.id == tag.id }) ? AppData.shared.mainColor : .white
            cell.viewTag.backgroundColor = self.viewModel.tmpSelectedTags.value.contains(where: { $0.id == tag.id }) ? .white : .clear
            
        }.disposed(by: disposeBag)
        
        viewModel.tagsAreClosed.map({ $0 ? WIDTH : 0 }).bind(to: constrLeadingTags.rx.animated.layout(duration: 0.5).constant).disposed(by: disposeBag)
        
        viewModel.selectedTags.map({ $0.count == 0 }).bind(to: viewCancelFilter.rx.isHidden).disposed(by: disposeBag)
        
        viewModel.isNoResultsHidden.bind(to: viewNoResults.rx.isHidden).disposed(by: disposeBag)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fetchLocation()
        
    }
    
    private func fetchLocation(){
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.fetchLocation()
            }
            return
        }else{
            viewModel.location.accept(locationManager.location ?? CLLocation(latitude: 32.0879994, longitude: 34.7622266))
            viewModel.didGetLocation.accept(true)
        }
        
    }

}

//MARK: - COLLECTIONVIEW DELEGATE
extension ShopsVC: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width / 2)
        let height = width / 1.1
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: {
            collectionView.cellForItem(at: indexPath)?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseIn], animations: {
                collectionView.cellForItem(at: indexPath)?.transform = CGAffineTransform(scaleX: 1, y: 1)
            }) { _ in
                self.viewModel?.shopDidSelect.onNext(indexPath)
            }
        }
        
    }
    
}

extension ShopsVC: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        viewModel.location.accept(locations[0])
    }
    
}
