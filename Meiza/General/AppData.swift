//
//  AppData.swift
//  Meiza
//
//  Created by Denis Windover on 05/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import RxCocoa
import RxSwift
import AVFoundation
import CoreLocation

class AppData: NSObject {
    
    static let shared           = AppData()
    private var disposeBag      = DisposeBag()
    var shopID:                   Int?
    var shop:                     Shop! {
        didSet{ RequestManager.shared.setOnesignal() }
    }
    var terms:                    String?
    var aboutUs:                  String?
    var privacy:                  String?
    var returnPolicy:             String?
    var accessibilityLink:        String?
    var paymentDescription:       String = ""
    var categoryProducts: [[String: BehaviorRelay<[Product]>]] = []
    var products                = BehaviorRelay<Set<Product>>(value: Set<Product>())
    var cartProducts            = BehaviorRelay<[CartProduct]>(value: [])
    var currentActiveProduct    = BehaviorRelay<Product?>(value: nil)
    var overallPrice            = BehaviorRelay<(withoutCoupon: Double, withCoupon: Double)>(value: (withoutCoupon: 0, withCoupon: 0))
    var inProccess:               Bool = false
    var toast                   = BehaviorRelay<String?>(value: nil)
    var _coupon                 = BehaviorRelay<Double>(value: 0)
    var coupon: (name: String, discount: Double)? {
        set{
            UserDefaults.standard.set(newValue?.name, forKey: "couponName")
            UserDefaults.standard.set(newValue?.discount, forKey: "couponDiscount")
            _coupon.accept(newValue?.discount ?? 0)
        }
        get{
            guard let name = UserDefaults.standard.object(forKey: "couponName") as? String,
                  let discount = UserDefaults.standard.object(forKey: "couponDiscount") as? Double else{ return nil }
            _coupon.accept(discount)
            return (name: name, discount: discount)
        }
    }
    private var disposablePrices: Disposable?
    var mainColor: UIColor {
        return shop?.mainColor ?? defaultColor
    }
    private let defaultColor = UIColor(r: 15, g: 177, b: 226)
    var bg: UIImage {
        return UIImage(named: shop.bgName) ?? UIImage(named: "bg")!
    }
    
    var polygonsDeliveryCost: Double?
    var deliveryCost: Double {
        
        if let polygonsDeliveryCost = polygonsDeliveryCost {
            return polygonsDeliveryCost
        }
        
        if shop.isAreaDelivery {
            return 0
        }
        
        var deliveryCost = self.shop.deliveryZones.sorted(by: { $0.deliveryCost < $1.deliveryCost }).first?.deliveryCost ?? self.shop._deliveryCost
        
        guard let location = self.shop.location, let userLat = User.currentUser?.lat, let userLon = User.currentUser?.lon else{ return deliveryCost }
        
        let userLocation = CLLocation(latitude: userLat, longitude: userLon)
        let distance = location.distance(from: userLocation)
        
        shop.deliveryZones.forEach { delZone in
            if (delZone.from * 1000) <= distance && (delZone.to * 1000) >= distance {
                deliveryCost = delZone.deliveryCost
                
            }
        }
        
        return deliveryCost
    }
    
    var localized: [String: Any] = [:]
    var currentPack = BehaviorRelay<CartProduct?>(value: nil)
    var editingPack = BehaviorRelay<CartProduct?>(value: nil)
    
    override init(){
        cartProducts.accept(CartProduct.getCartProducts())
        
        currentPack.subscribe(onNext: { _pack in
            guard let pack = _pack, let currentLevelIndex = pack.currentLevelIndex, let product = pack.product else{ return }
      
            if pack.levels.index(currentLevelIndex)?.productsAmount == pack.levels.index(currentLevelIndex)?.selectedProducts.count {
                if product.levels.index(currentLevelIndex+1) != nil { // GO TO NEXT LEVEL
                    Coordinator.shared.level(product, cartProduct: pack, levelIndex: currentLevelIndex+1)
                }else{ //ADD TO CART
                    CartProduct.addPackToCart(pack, product: product)
                    DispatchQueue.main.async {
                        AppData.shared.currentPack.accept(nil)
                        AppData.shared.playSound()

                        AlertCoordinator.shared.finishPack(product)
                    }
                }
            }

        }).disposed(by: disposeBag)
        
        editingPack.skip(1).subscribe(onNext: { _editingPack in
            AppData.shared.calculatePrices()
        }).disposed(by: disposeBag)
    }
    
    func calculatePrices(){
        
        disposablePrices?.dispose()
        
        disposablePrices =  Observable<(withoutCoupon: Double, withCoupon: Double)>.combineLatest(cartProducts, products, _coupon){ _cartProducts, _, _coupon in
            let price = _cartProducts.reduce(0.0, { result, _cartProduct -> Double in
                return result + (_cartProduct.isChosen ? _cartProduct.price : 0)
            })
            return (withoutCoupon: price, withCoupon: price * (1 - (_coupon / 100)))
            }.bind(to: overallPrice)
        
    }
    
    func start(){
        localized = getLocalized()
    }
    
    private var player: AVAudioPlayer?
    private let pathToppingSound = Bundle.main.path(forResource: "topping.mpeg", ofType: nil)
    private let pathProductSound = Bundle.main.path(forResource: "cash.mp3", ofType: nil)
    private let pathScrollSound = Bundle.main.path(forResource: "tick.wav", ofType: nil)
    
    func playSound(isProduct: Bool = true) {
        
        guard shop?.withSound ?? false else{ return }
        
        if player?.isPlaying == true  {
            player?.stop()
        }
        
        let _path = isProduct ? pathProductSound : pathToppingSound

        guard let path = _path else{ return }
        
        let sound = URL(fileURLWithPath: path)
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        try? player = AVAudioPlayer(contentsOf: sound)
        player?.prepareToPlay()
        player?.play()
        
    }
    func playScrollSound() {
        
        guard shop?.withSound ?? false else{ return }
        
        if player?.isPlaying == true {
            player?.stop()
        }
        
        let _path = pathScrollSound

        guard let path = _path else{ return }
        
        let sound = URL(fileURLWithPath: path)
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        try? player = AVAudioPlayer(contentsOf: sound)
        player?.prepareToPlay()
        player?.play()
        
    }
    
    func updateAllData(completion: @escaping()->()) {
        
        updateShop {
            completion()
        }
        
    }
    
    private func updateShop(completion: @escaping()->()) {
        
        RequestManager.shared.setShop(false).subscribe(onNext: { [weak self] result in
            if let shop = result.shop {
                AppData.shared.shop = shop
                self?.updateProducts(self?.cartProducts.value.map({ $0.productID }) ?? [], completion: completion)
            }else if let _ = result.error {
                self?.updateShop(completion: completion)
            }
        }).disposed(by: disposeBag)
        
    }
    
    private func updateProducts(_ cartProductIDs: [Int], completion: @escaping()->()){
        RequestManager.shared.getProducts(cartProductIDs, loader: false).subscribe(onNext: { [weak self] result in
            if let products = result.products {
                AppData.shared.categoryProducts = products.categoryProducts
                completion()
            }else if let error = result.error {
                error.toast()
                self?.updateProducts(cartProductIDs, completion: completion)
            }
        }).disposed(by: disposeBag)
    }
    
    func loadAllCategoryProducts(_ categoryId: String, pagingData: PagingData){
        RequestManager.shared.searchProducts("", categoryId: categoryId).subscribe { (products: [Product]?, error: Error?) in
            if let products = products {
                if AppData.shared.categoryProducts.first(where: { $0.first?.key == "category_\(categoryId)" })?.first?.value.value.sorted(by: { p1, p2 in p1.id == p2.id}) != products.sorted(by: {p1, p2 in p1.id == p2.id}) {
                    pagingData.loadedAllItems.accept(true)
                    AppData.shared.categoryProducts.first(where: { $0.first?.key == "category_\(categoryId)" })?.first?.value.accept(products)
                }
            }
        }.disposed(by: disposeBag)
    }
}


extension AppData {

    func getLocalized() -> [String: Any] {
        
        guard let path = Bundle.main.path(forResource: "Localized", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
              let json = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves),
              let jsonResult = json as? Dictionary<String, AnyObject> else{ return [:] }
            
        return jsonResult
    }
    
}
