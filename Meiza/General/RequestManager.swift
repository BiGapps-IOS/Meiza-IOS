//
//  RequestManager.swift
//  Meiza
//
//  Created by Denis Windover on 05/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import Alamofire
import RxCocoa
import RxSwift
import ObjectMapper
import OneSignal
import CoreLocation


class RequestManager {
    
    struct APIError{
        enum General: Error, Equatable{
            case parse, unknown, shopNotFound, userNotFound, defaultTranzila, cardBlocked, cardStolen, callCreditCompany, cardRejected, cardFake, cvvInvalid, zcredit(String), dateError, couponError(String)
            
            var type: APIError.General {
                return self
            }
            
            public var errorDescription: String {
                return _errorDescription
            }
            
            private var _errorDescription: String {
                switch self {
                case .parse: return "שגיאת שרת! לא ניתן לעבד נתונים!"
                case .shopNotFound: return "לא קיים"
                case .userNotFound: return "משתמש לא קיים, יש להזין מס׳ חנות"
                case .defaultTranzila: return "שגיאת בסליקת כרטיס האשראי"
                case .cardBlocked: return "כרטיס אשראי חסום!"
                case .cardStolen: return "כרטיס אשראי גנוב!"
                case .callCreditCompany: return "שגאיה! התקשר לחברת אשראי!"
                case .cardRejected: return "סירוב!"
                case .cardFake: return "כרטיס אשראי מזויף"
                case .cvvInvalid: return "ת.ז. או CVV שגויים!"
                case .zcredit(let message): return message
                case .couponError(let message): return message
                    
                default:
                    return ""
                }
            }
        }
        
        private static let shopNotFound    = "SHOP_NOT_FOUND"
        private static let userNotFound    = "USER_NOT_FOUND"
        private static let dateError       = "DATE_ERROR"
        private static let couponIsUsed    = "COUPON_IS_USED"
        private static let couponIsExpired = "COUPON_EXPIRED"
        
        static func getError(from text: String, message: String = "") -> Error {
            
            switch text {
            case shopNotFound: return APIError.General.shopNotFound
            case userNotFound: return APIError.General.userNotFound
            case dateError: return APIError.General.dateError
            case couponIsUsed, couponIsExpired:
                AppData.shared.coupon = nil
                return APIError.General.couponError(message)
                
            default:
                return APIError.General.unknown
            }
            
        }
        
        
    }
    
    struct API{
        //Server API
        static private let productionUrl = "https://yazbak.bigapps.co.il/api/" //"https://myshopplus.bigapps.co.il/api/"
        static private let devUrl = "http://myplus2-bigapps.jp.ngrok.io/api/" //"http://myplus.bigapps.eu.ngrok.io/api/"
        
        //Google API
        static let googleResultLanguage = currentLanguage == "en" ? "he" : currentLanguage
        private static let googleURL = "https://maps.googleapis.com/maps/api/"
        
        static let autocompleteAddress = googleURL + "place/autocomplete/json"
        static let geocodingAddress    = googleURL + "geocode/json"
        static let distanceMatrix      = googleURL + "distancematrix/json"
        static let directions          = googleURL + "directions/json"
        
        //Tranzila API
        private static let zcreditURL = "https://pci.zcredit.co.il/ZCreditWS/api/Transaction/"
        static let getToken           = zcreditURL + "ValidateCard"
        static let j5Transaction      = zcreditURL + "CommitFullTransaction"
        
        static let getShops       = (IS_PRODUCTION ? productionUrl : devUrl) + "get-shops"
        static let setShop        = (IS_PRODUCTION ? productionUrl : devUrl) + "set-shop"
        static let userPhone      = (IS_PRODUCTION ? productionUrl : devUrl) + "user-phone"
        static let getProducts    = (IS_PRODUCTION ? productionUrl : devUrl) + "get-products"
        static let upsertUser     = (IS_PRODUCTION ? productionUrl : devUrl) + "upsert-user"
        static let verifyPhone    = (IS_PRODUCTION ? productionUrl : devUrl) + "verify-phone"
        static let makeOrder      = (IS_PRODUCTION ? productionUrl : devUrl) + "make-order"
        static let setOnesignal   = (IS_PRODUCTION ? productionUrl : devUrl) + "set-onesignal"
        static let searchProducts = (IS_PRODUCTION ? productionUrl : devUrl) + "search-products"
        static let ordersHistory  = (IS_PRODUCTION ? productionUrl : devUrl) + "get-order-history"
        static let remindOrder    = (IS_PRODUCTION ? productionUrl : devUrl) + "remind-order"
        static let checkCoupon    = (IS_PRODUCTION ? productionUrl : devUrl) + "check-coupon"
        static let getDeliveryPrice = (IS_PRODUCTION ? productionUrl : devUrl) + "get-delivery-price"
    }
    
    static let shared = RequestManager()
    private var manager = Alamofire.Session.default
    private var disposeBag = DisposeBag()
    private var headers: HTTPHeaders? {
        return User.currentUser?.jwt != nil ? ["Bearer": User.currentUser!.jwt!] : nil
    }
    var userDidSave = PublishSubject<Void>()
    
    
    
    init() {
        manager.session.configuration.timeoutIntervalForRequest = 20
        //manager.session.configuration.httpShouldSetCookies = true
        
        userDidSave.debounce(.milliseconds(500), scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.setOnesignal()
        }).disposed(by: disposeBag)
        
    }
    
    //MARK: - SERVER REQUESTS
    func getDeliveryPrice(_ location: CLLocation) -> Observable<Double?> {
        
        var params = ["deliveryLat": location.coordinate.latitude,
                      "deliveryLon": location.coordinate.longitude] as [String: Any]
        
        if let shopID = SHOP_ID {
            params["shopId"] = shopID
        }
        
        Loader.show()
        
        return Observable.create { observer in
            
            self.manager.request(API.getDeliveryPrice, method: .post, parameters: params, headers: self.headers).responseJSON { response in
                RequestManager.printRequestDebugDescription(API.getDeliveryPrice, params: params, response: response)
                
                Loader.dismiss()
                
                switch response.result{
                case .success(let data):
                    
                    guard let errorCode = (data as? [String: Any])?["errorCode"] as? String else{
                        observer.onNext(nil)
                        return
                    }
                    
                    switch errorCode {
                    case "0":
                        guard let dic = data as? [String: Any],
                              let _data = dic["data"] as? [String: Any],
                              let deliveryCost = _data["deliveryCost"] as? Double else{
                            observer.onNext(nil)
                            return
                        }
                        
                        observer.onNext(deliveryCost)
                        
                    default:
                        observer.onNext(nil)
                    }
                    
                case .failure(_):
                    observer.onNext(nil)
                    
                }
                
            }
            
            return Disposables.create()
        }
        
    }
    
    func checkCoupon(_ coupon: String) -> Observable<(discount: Double?, error: Error?)> {
        
        var params = ["coupon": coupon] as [String: Any]
        
        if let shopID = SHOP_ID {
            params["shopId"] = shopID
        }
        
        Loader.show()
        
        return Observable.create { observer in
            
            self.manager.request(API.checkCoupon, method: .post, parameters: params, headers: self.headers).responseJSON { response in
                RequestManager.printRequestDebugDescription(API.checkCoupon, params: params, response: response)
                
                Loader.dismiss()
                
                switch response.result{
                case .success(let data):
                    
                    guard let errorCode = (data as? [String: Any])?["errorCode"] as? String else{
                        observer.onNext((discount: nil, error: APIError.General.parse))
                        return
                    }
                    
                    switch errorCode {
                    case "0":
                        guard let dic = data as? [String: Any],
                              let _data = dic["data"] as? [String: Any],
                              let discount = _data["discount"] as? Double else{
                            observer.onNext((discount: nil, error: APIError.General.parse))
                            return
                        }
                        
                        observer.onNext((discount: discount, error: nil))
                        
                    default:
                        guard let message = (data as? [String: Any])?["errorMessage"] as? String else{
                            observer.onNext((discount: nil, error: APIError.General.unknown))
                            return
                        }
                        observer.onNext((discount: nil, error: APIError.General.couponError(message)))
                    }
                    
                case .failure(let error):
                    observer.onNext((discount: nil, error: error))
                    
                }
                
            }
            
            return Disposables.create()
        }
        
    }
    
    func remindOrder() {
        
        if IS_NEED_REMIND_ORDER {
            guard let onesignalID = OneSignal.getPermissionSubscriptionState().subscriptionStatus.userId else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.remindOrder()
                }
                return
            }
            
            let params = ["onesignalId": onesignalID]
            
            self.manager.request(API.remindOrder, method: .post, parameters: params, headers: self.headers).responseJSON { response in
                RequestManager.printRequestDebugDescription(API.remindOrder, params: params, response: response)
                
                if response.error == nil {
                    IS_NEED_REMIND_ORDER = false
                }
            }
            
        }
        
    }
    
    func ordersHistory() -> Observable<(orders: [Order], error: Error?)> {
        
        var params = [
            "userId": User.currentUser?.id ?? 0] as [String : Any]
        
        if let shopID = SHOP_ID {
            params["shopId"] = shopID
        }
        
        Loader.show()
        
        return Observable.create { observer in
            
            self.manager.request(API.ordersHistory, method: .post, parameters: params, headers: self.headers).responseJSON { response in
                RequestManager.printRequestDebugDescription(API.ordersHistory, params: params, response: response)
                
                Loader.dismiss()
                
                switch response.result{
                case .success(let data):
                    
                    guard let _data = (data as? [String: Any])?.serverResponse.data else {
                        guard let error = (data as? [String: Any])?.serverResponse.error else{
                            observer.onNext((orders: [], error: nil))
                            return
                        }
                        observer.onNext((orders: [], error: error))
                        return
                    }
                    
                    guard let ordersRaw = _data["orders"] as? [[String: Any]] else{
                            observer.onNext((orders: [], error: APIError.General.parse))
                            return
                    }
                    
                    let orders = Mapper<Order>().mapArray(JSONArray: ordersRaw)
                    
                    observer.onNext((orders: orders, error: nil))
                    
                case .failure(let error):
                    observer.onNext((orders: [], error: error))
                    
                }
                
            }
            
            return Disposables.create()
        }
        
    }
    
    func searchProducts(_ text: String, categoryId: String?) -> Observable<(products: [Product]?, error: Error?)> {
        
        var params = [
            "shopId": AppData.shared.shop.id,
            "productName": text,
            "categoryId": categoryId ?? ""
        ] as [String : Any]
        
        if let shopID = SHOP_ID {
            params["shopId"] = shopID
        }
        
        return Observable.create { observer in
            
            self.manager.request(API.searchProducts, method: .post, parameters: params, headers: self.headers).responseJSON { response in
                RequestManager.printRequestDebugDescription(API.searchProducts, params: params, response: response)
                
                switch response.result{
                case .success(let data):
                    
                    guard let _data = (data as? [String: Any])?.serverResponse.data else {
                        guard let error = (data as? [String: Any])?.serverResponse.error else{
                            observer.onNext((products: nil, error: nil))
                            return
                        }
                        observer.onNext((products: nil, error: error))
                        return
                    }
                    
                    guard let productsRaw = _data["products"] as? [[String: Any]] else{
                            observer.onNext((products: nil, error: APIError.General.parse))
                            return
                    }
                    
                    let products = Mapper<Product>().mapArray(JSONArray: productsRaw)
                    
                    observer.onNext((products: products, error: nil))
                    
                case .failure(let error):
                    observer.onNext((products: nil, error: error))
                    
                }
                
            }
            
            return Disposables.create()
        }
        
    }
    
    func setOnesignal(){
        guard let onesignalID = OneSignal.getPermissionSubscriptionState().subscriptionStatus.userId, AppData.shared.shop?.id != nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.setOnesignal()
            }
            return
        }

        self.setOnesignal(onesignalID).subscribe(onNext: nil, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
        
    }
    private func setOnesignal(_ onesignalID: String) -> Observable<Error?> {
        
        var params = [
            "onesignalId": onesignalID] as [String : Any]
        
        if let id = User.currentUser?.id {
            params["userId"] = id
        }
        
        if let shopID = SHOP_ID {
            params["shopId"] = shopID
        }
        
        return Observable.create { observer in
            self.manager.request(API.setOnesignal, method: .post, parameters: params, headers: self.headers).responseJSON { response in
                RequestManager.printRequestDebugDescription(API.setOnesignal, params: params, response: response)
                
                switch response.result{
                case .success(_):
                    
                    observer.onNext(nil)
                    
                case .failure(let error):
                    observer.onNext(error)
                    
                }
                
            }
            
            return Disposables.create()
        }
        
    }
    
    func makeOrder(_ order: NewOrder, cvv: String? = nil) -> Observable<(orderID: Int?, error: Error?)> {
        
        Loader.show()
        
        var params = [
            "userId": User.currentUser?.id ?? 0,
            "shopId": AppData.shared.shop.id,
            "orderType": order.orderType,
            "paymentType": order.paymentType ?? "",
            "deliveryDate": order.deliveryTime?.date ?? Int(Date().timeIntervalSince1970),
            "deliveryFrom": order.deliveryTime?.from ?? "12:00",
            "deliveryTo": order.deliveryTime?.to ?? "12:00",
            "comment": User.currentUser?.comment ?? "",
            "onesignalId": OneSignal.getPermissionSubscriptionState().subscriptionStatus.userId ?? "",
            "source": "app"] as [String : Any]
        
        
        if order.orderType == "delivery"{
            params["deliveryComment"] = User.currentUser?.comment2 ?? ""
            params["deliveryCost"] = AppData.shared.deliveryCost
            params["distance"] = Int(AppData.shared.shop.distanceFromMe)
            
            if let lat = User.currentUser?.lat, let lon = User.currentUser?.lon, User.currentUser?.isNeedRemoveTempLocation == true {
                params["deliveryLat"] = lat
                params["deliveryLon"] = lon
            }
        }
        
        if order.paymentType == "credit" {
            params["creditTxIndex"] = order.referenceNum ?? 0
            params["creditTxConfirm"] = User.currentUser?.zcreditToken
            params["creditTxCardNo"] = User.currentUser?.creditCartLast4Digits ?? ""
            params["creditTxExpDate"] = User.currentUser?.expDate ?? ""
            params["creditTxHolderId"] = User.currentUser?.passID ?? ""
            params["creditNumberOfPayments"] = order.payments
            if let cvv = cvv {
                params["creditTxCVV"] = cvv
            }
        }
        
        if let coupon = AppData.shared.coupon {
            params["coupon"] = coupon.name
        }
        
        if let branch = order.branch {
            params["branchId"] = branch.id
        }
        
        if let shopID = SHOP_ID {
            params["shopId"] = shopID
        }
        
        print(order.products)
        params.update(other: order.products)
        
        return Observable.create { observer in
            self.manager.request(API.makeOrder, method: .post, parameters: params, encoding: URLEncoding(destination: .methodDependent)
                , headers: self.headers).responseJSON { response in
                    RequestManager.printRequestDebugDescription(API.makeOrder, params: params, response: response)
                    
                    Loader.dismiss()
                    
                    if User.currentUser?.isNeedRemoveTempLocation == true {
                        User.currentUser?.lat = nil
                        User.currentUser?.lon = nil
                    }
                    
                    switch response.result {
                    case .success(let data):
                        
                        guard let dic = (data as? [String: Any])?.serverResponse.data,
                            let id = dic["id"] as? Int else {
                                guard let error = (data as? [String: Any])?.serverResponse.error else{
                                    observer.onNext((orderID: nil, error: APIError.General.unknown))
                                    return
                                }
                                observer.onNext((orderID: nil, error: error))
                                return
                        }
                        AppData.shared.polygonsDeliveryCost = nil
                        AppData.shared.coupon = nil
                        AppData.shared.currentPack.accept(nil)
                        AppData.shared.editingPack.accept(nil)
                        observer.onNext((orderID: id, error: nil))
                        
                    case .failure(let error):
                        observer.onNext((orderID: nil, error: error))
                        
                    }
                    
            }
            
            return Disposables.create()
        }
        
    }
    
    func verifyPhone(_ phone: String, code: String) -> Observable<(userID: Int?, error: Error?)> {
        
        Loader.show()
        
        let params = [
            "phone": phone,
            "code": code]
        
        return Observable.create { observer in
            self.manager.request(API.verifyPhone, method: .post, parameters: params, headers: self.headers).responseJSON { response in
                RequestManager.printRequestDebugDescription(API.verifyPhone, params: params, response: response)
                
                Loader.dismiss()
                
                switch response.result{
                case .success(let data):
                    
                    guard let _data = (data as? [String: Any])?.serverResponse.data else {
                        guard let error = (data as? [String: Any])?.serverResponse.error else{
                            observer.onNext((userID: nil, error: APIError.General.unknown))
                            return
                        }
                        observer.onNext((userID: nil, error: error))
                        return
                    }
                    
                    let name = _data["name"] as? String
                    let phone = _data["phone"] as? String
                    let street = _data["streetName"] as? String
                    let streetNum = _data["streetNumber"] as? String
                    let floor = _data["floorNumber"] as? String
                    let entranceCode = _data["entranceCode"] as? String
                    let apartment = _data["apartmentNumber"] as? String
                    let city = _data["city"] as? String
                    
                    if User.currentUser == nil, let shopID = _data["shopId"] as? Int {
                        User.initCurrentUser(shopID: shopID)
                        User.currentUser?.fullName = name
                        User.currentUser?.phone = phone
                        User.currentUser?.street = street
                        User.currentUser?.streetNum = streetNum
                        User.currentUser?.floor = floor
                        User.currentUser?.entranceCode = entranceCode
                        User.currentUser?.apartment = apartment
                        User.currentUser?.city = city
                    }
 
                    if let token = _data["token"] as? String, let id = _data["id"] as? Int {
                        User.currentUser?.jwt = token
                        observer.onNext((userID: id, error: nil))
                    }else{
                        observer.onNext((userID: nil, error: APIError.General.parse))
                    }
                    
                case .failure(let error):
                    observer.onNext((userID: nil, error: error))
                    
                }
                
            }
            
            return Disposables.create()
        }
        
    }
    
    func upsertUser() -> Observable<(userID: Int?, error: Error?)> {
        
        Loader.show()
        
        var params = [
            "email": User.currentUser?.email ?? "",
            "name": User.currentUser?.fullName ?? "",
            "phone": User.currentUser?.phone ?? "",
            "shopId": User.currentUser?.shopID ?? 0,
            "streetName": User.currentUser?.street ?? "",
            "streetNumber": User.currentUser?.streetNum ?? "",
            "city": User.currentUser?.city ?? "",
            "floorNumber": User.currentUser?.floor ?? "",
            "entranceCode": User.currentUser?.entranceCode ?? "",
            "apartmentNumber": User.currentUser?.apartment ?? ""] as [String : Any]
        
        if let userID = User.currentUser?.id {
            params["userId"] = userID
        }
        
        if let shopID = SHOP_ID {
            params["shopId"] = shopID
        }
        
        
        return Observable.create { observer in
            self.manager.request(API.upsertUser, method: .post, parameters: params, headers: self.headers).responseJSON { response in
                RequestManager.printRequestDebugDescription(API.upsertUser, params: params, response: response)
                
                Loader.dismiss()
                
                switch response.result{
                case .success(let data):
                    
                    guard let _data = (data as? [String: Any])?.serverResponse.data else {
                        guard let error = (data as? [String: Any])?.serverResponse.error else{
                            observer.onNext((userID: 0, error: nil))
                            return
                        }
                        observer.onNext((userID: nil, error: error))
                        return
                    }
                    
                    if let token = _data["token"] as? String, let id = _data["id"] as? Int {
                        User.currentUser?.jwt = token
                        observer.onNext((userID: id, error: nil))
                    }else{
                        observer.onNext((userID: nil, error: APIError.General.parse))
                    }
                    
                case .failure(let error):
                    observer.onNext((userID: nil, error: error))
                    
                }
                
            }
            
            return Disposables.create()
        }
        
    }
    
    func getProductsByPage(_ page: Int, category: String) -> Observable<(products: [Product]?, error: Error?)> {
        
        var params = ["shopId": AppData.shared.shop.id,
                      "page": page,
                      "categoryCodename": category] as [String : Any]
        
        if let shopID = SHOP_ID {
            params["shopId"] = shopID
        }
        
        return Observable.create { observer in
            self.manager.request(API.getProducts, method: .post, parameters: params).responseJSON { response in
                RequestManager.printRequestDebugDescription(API.getProducts, params: params, response: response)
                
                switch response.result{
                case .success(let data):
                    
                    guard let _data = (data as? [String: Any])?.serverResponse.data else {
                        guard let error = (data as? [String: Any])?.serverResponse.error else{
                            observer.onNext((products: nil, error: APIError.General.unknown))
                            return
                        }
                        observer.onNext((products: nil, error: error))
                        return
                    }
                    
                    guard let categoryProducts = _data["categoryProducts"] as? [String: Any],
                        let productsRaw = categoryProducts[category] as? [[String: Any]] else{
                            observer.onNext((products: nil, error: APIError.General.parse))
                            return
                    }
                    
                    let products = Mapper<Product>().mapArray(JSONArray: productsRaw)
                    
                    
                    observer.onNext((products: products, error: nil))
                    
                case .failure(let error):
                    observer.onNext((products: nil, error: error))
                    
                }
                
            }
            
            return Disposables.create()
        }
        
    }
    
    func getProducts(_ cartProductIDs: [Int], loader: Bool = true) -> Observable<(products: (cart: [Product], categoryProducts: [[String: BehaviorRelay<[Product]>]])?, error: Error?)> {
        
        if loader{ Loader.show() }
        
        var params = ["cartProductIds": cartProductIDs] as [String : Any]
        
        if let shopID = SHOP_ID {
            params["shopId"] = shopID
        }
        
        return Observable.create { observer in
            self.manager.request(API.getProducts, method: .post, parameters: params).responseJSON { response in
                RequestManager.printRequestDebugDescription(API.getProducts, params: params, response: response)
                
                Loader.dismiss()
                
                switch response.result{
                case .success(let data):
                    
                    guard let _data = (data as? [String: Any])?.serverResponse.data else {
                        guard let error = (data as? [String: Any])?.serverResponse.error else{
                            observer.onNext((products: nil, error: APIError.General.unknown))
                            return
                        }
                        observer.onNext((products: nil, error: error))
                        return
                    }
                    
                    let categoryProductsRaw = _data["categoryProducts"] as? [String: Any]
                    
                    var categoryProducts: [[String: BehaviorRelay<[Product]>]] = []
                    
                    AppData.shared.shop?.categories.forEach({ cat in
                        let productsRelay = BehaviorRelay<[Product]>(value: [])
                        if let productsRaw = categoryProductsRaw?[cat.codename ?? ""] as? [[String: Any]] {
                            let products = Mapper<Product>().mapArray(JSONArray: productsRaw)
                            productsRelay.accept(products)
                        }
                        categoryProducts.append([cat.codename ?? "": productsRelay])
                    })
                    
                    var cartProducts = [Product]()
                    
                    if let cartProductsRaw = _data["cartProducts"] as? [[String: Any]]{
                        cartProducts = Mapper<Product>().mapArray(JSONArray: cartProductsRaw)
                    }
                    
                    //demo products if null
                    if categoryProductsRaw == nil, let demoData = getDemoProducts() {
                        AppData.shared.shop?.categories.removeAll()
                        AppData.shared.shop?.categories.append(demoData.category)
                        let productsRelay = BehaviorRelay<[Product]>(value: demoData.products)
                        categoryProducts.removeAll()
                        categoryProducts.append([demoData.category.codename ?? "": productsRelay])
                    }
                    
                    observer.onNext((products: (cart: cartProducts, categoryProducts: categoryProducts), error: nil))
                    
                case .failure(let error):
                    observer.onNext((products: nil, error: error))
                    
                }
                
            }
            
            return Disposables.create()
        }
        
    }
    
    func userPhone(_ phone: String) -> Observable<Error?> {
        
        Loader.show()
        
        let params = ["phone": phone]
        
        return Observable.create { observer in
            self.manager.request(API.userPhone, method: .post, parameters: params).responseJSON { response in
                RequestManager.printRequestDebugDescription(API.userPhone, params: params, response: response)
                
                Loader.dismiss()
                
                switch response.result{
                case .success(let data):
                    
                    guard let error = (data as? [String: Any])?.serverResponse.error else{
                        observer.onNext(nil)
                        return
                    }
                    
                    observer.onNext(error)
                    
                case .failure(let error):
                    observer.onNext(error)
                    
                }
                
            }
            
            return Disposables.create()
        }
        
    }
    
    func setShop(_ loader: Bool = true) -> Observable<(shop: Shop?, error: Error?)> {
        
        if loader{ Loader.show() }
        
        var params: [String: Any]? = nil
        
        if let shopID = SHOP_ID {
            params = [:]
            params?["shopId"] = shopID
        }
        
        return Observable.create { observer in
            self.manager.request(API.setShop, method: .post, parameters: params).responseJSON { response in
                RequestManager.printRequestDebugDescription(API.setShop, params: params, response: response)
                
                Loader.dismiss()
                
                switch response.result{
                case .success(let data):
                    
                    guard let _data = (data as? [String: Any])?.serverResponse.data else {
                        guard let error = (data as? [String: Any])?.serverResponse.error else{
                            observer.onNext((shop: nil, error: APIError.General.unknown))
                            return
                        }
                        observer.onNext((shop: nil, error: error))
                        return
                    }
                    
                    guard let shopRaw = _data["shop"] as? [String: Any] else{
                        observer.onNext((shop: nil, error: APIError.General.parse))
                        return
                    }
                    
                    AppData.shared.terms = _data["rules"] as? String
                    AppData.shared.aboutUs = _data["about"] as? String
                    AppData.shared.privacy = _data["privacy_policy"] as? String
                    AppData.shared.returnPolicy = _data["return_policy"] as? String
                    AppData.shared.paymentDescription = _data["paymentDescription"] as? String ?? ""
                    
                    if let shop = Mapper<Shop>().map(JSON: shopRaw) {
                        self.setOnesignal()
                        observer.onNext((shop: shop, error: nil))
                    }else{
                        observer.onNext((shop: nil, error: APIError.General.parse))
                    }
                    
                case .failure(let error):
                    observer.onNext((shop: nil, error: error))
                    
                }
                
            }
            
            return Disposables.create()
        }
        
    }
    
    func getShops(completion: @escaping(String, [ShopBasic], [Tag])->()) {
        
        manager.request(API.getShops, method: .post).responseJSON { response in
            RequestManager.printRequestDebugDescription(API.getShops, params: nil, response: response)
            
            switch response.result{
            case .success(let data):
                guard let dic = data as? [String: Any],
                      (dic["errorCode"] as? String) == "0" else{
                    self.getShops(completion: completion)
                    return
                }
                
                let data = dic["data"] as? [String: Any]
                let tagsRaw = data?["tags"] as? [[String: Any]]
                let shopsRaw = data?["shops"] as? [[String: Any]]
                let title = data?["welcomeMessage"] as? String
                AppData.shared.accessibilityLink = data?["accessabilityLink"] as? String
                
                let tags = Mapper<Tag>().mapArray(JSONArray: tagsRaw ?? [[:]])
                let shops = Mapper<ShopBasic>().mapArray(JSONArray: shopsRaw ?? [[:]])
                
                if shops.count == 0 {
                    completion(title ?? "", shops, tags)
                }else{
                    for i in 0..<shops.count {
                        if shops[i].shopLat != nil && shops[i].shopLon != nil{
                            shops[i].location = CLLocation(latitude: shops[i].shopLat!, longitude: shops[i].shopLon!)
                            if i == shops.count - 1 {
                                completion(title ?? "", shops, tags)
                            }
                        }else{
                            self.fetchAddress(with: shops[i].address) { location in
                                shops[i].location = location
                                if i == shops.count - 1 {
                                    completion(title ?? "", shops, tags)
                                }
                            }
                        }
                    }
                }
                
            case .failure(_):
                self.getShops(completion: completion)
            }
        }
        
    }
    
    //MARK: - GOOGLE API
    func fetchAddress(with address: String, completion: @escaping(CLLocation?)->()) {
        
        let params = [
            "key": GOOGLE_API_KEY,
            "address": address,
            "language": API.googleResultLanguage]
        
        self.manager.request(API.geocodingAddress, method: .get, parameters: params).responseJSON { response in
            
            switch response.result{
            
            case .success(let data):
                guard let dic = data as? [String: Any],
                    (dic["status"] as? String) == "OK",
                    let results = dic["results"] as? [[String:Any]],
                    results.count > 0,
                    let geometry = results[0]["geometry"] as? [String: Any],
                    let location = geometry["location"] as? [String: Any],
                    let lat = location["lat"] as? Double,
                    let lon = location["lng"] as? Double else{
                    completion(nil)
                        return
                }
                
                completion(CLLocation(latitude: lat, longitude: lon))
                
                
            case .failure(_):
                completion(nil)
            }
            
        }
        
    }
    func fetchAddress(with coordinates: CLLocation) -> Observable<Address?> {
        
        let params = [
            "key": GOOGLE_API_KEY,
            "latlng": "\(coordinates.coordinate.latitude),\(coordinates.coordinate.longitude)",
            "language": API.googleResultLanguage]
        
        return Observable.create { observer in
            self.manager.request(API.geocodingAddress, method: .get, parameters: params).responseJSON { response in
                RequestManager.printRequestDebugDescription(API.geocodingAddress, params: params, response: response)
                
                switch response.result{
                case .success(let data):
                    guard let dic = data as? [String: Any],
                        (dic["status"] as? String) == "OK",
                        let results = dic["results"] as? [[String:Any]],
                        results.count > 0,
                        let address = Address(addressComponents: results[0]["address_components"] as? [[String: Any]], coordinates: coordinates) else{
                        observer.onNext(nil)
                            return
                    }
                    
                    observer.onNext(address)
                    
                    
                case .failure(_):
                    observer.onNext(nil)
                }
                
            }
            
            return Disposables.create()
        }
        
    }
    
    func fetchLocation(for address: Address) -> Observable<Address>{
        
        let params = ["key": GOOGLE_API_KEY,
                      "place_id": address.placeID ?? ""]
        
        Loader.show()
        
        return Observable.create { observer in
            self.manager.request(API.geocodingAddress, method: .get, parameters: params, encoding: URLEncoding.default)
                .validate()
                .responseJSON { response in
                    //                    RequestManager.printRequestDebugDescription(API.geocodingAddress, params: params, response: response)
                    
                    Loader.dismiss()
                    
                    switch response.result{
                    case .success(let data):
                        guard let dic = data as? [String: Any],
                            (dic["status"] as? String) == "OK",
                            let results = dic["results"] as? [[String: Any]] else{
                                observer.onError(response.error ?? APIError.General.parse)
                                return
                        }
                        
                        results.forEach { (e) in
                            if let geometry = e["geometry"] as? [String: Any], let location = geometry["location"] as? [String: Any]{
                                
                                guard let lat = location["lat"] as? Double, let lon = location["lng"] as? Double else{
                                    observer.onError(response.error ?? APIError.General.parse)
                                    return
                                }
                                
                                address.lat = lat
                                address.lon = lon
                                
                                observer.onNext(address)
                                return
                            }
                            
                            observer.onError(response.error ?? APIError.General.unknown)
                            
                        }
                        
                        
                    case .failure(let error):
                        observer.onError(error)
                    }
            }
            return Disposables.create()
        }
    }
    
    func fetchAddresses(with text: String) -> Observable<[Address]>{
        
        let params = ["input": text,
                      "language": API.googleResultLanguage,
                      "key": GOOGLE_API_KEY] //"type": "(cities)"
        
        return Observable.create { observer in
            self.manager.request(API.autocompleteAddress, method: .get, parameters: params, encoding: URLEncoding.default)
                .validate()
                .responseJSON { response in
                    
                    switch response.result{
                    case .success(let data):
                        guard let dic = data as? [String: Any],
                            (dic["status"] as? String) == "OK",
                            let predictions = dic["predictions"] as? [[String:Any]] else{
                                observer.onError(response.error ?? APIError.General.parse)
                                return
                        }
                        
                        let addresses = Mapper<Address>().mapArray(JSONArray: predictions)
                        
                        observer.onNext(addresses)
                        
                    case .failure(let error):
                        observer.onError(error)
                    }
            }
            return Disposables.create()
        }
        
    }
    
    //MARK: - Z-CREDIT REQUESTS
    func zcreditJ5Transaction(_ cvv: String, deliveryPrice: Double = 0.0, payments: Int = 1) -> Observable<(referenceNum: Int?, error: Error?)> {
        
        Loader.show()
        
        let params = [
            "TerminalNumber": ZCREDIT_TERMINAL_NUM,
            "Password": ZCREDIT_PASS,
            "CardNumber": User.currentUser?.zcreditToken?.trimmingCharacters(in: .newlines) ?? "",
            "TransactionSum": AppData.shared.overallPrice.value.withCoupon + deliveryPrice,
            "CVV": cvv,
            "HolderID": User.currentUser?.passID ?? "",
            "ObeligoAction": 0,
            "CustomerName": User.currentUser?.fullName ?? "",
            "CustomerEmail": User.currentUser?.email ?? "",
            "PhoneNumber": User.currentUser?.phone ?? "",
            "J": 5,
            "NumberOfPayments": payments] as [String : Any]
        
        return Observable.create { observer in
            self.manager.request(API.j5Transaction, method: .post, parameters: params).responseJSON { response in
                RequestManager.printRequestDebugDescription(API.j5Transaction, params: params, response: response)
                
                Loader.dismiss()
                
                switch response.result{
                case .success(let data):
                    
                    guard let returnCode = (data as? [String: Any])?["ReturnCode"] as? Int else{
                        observer.onNext((referenceNum: nil, error: APIError.General.parse))
                        return
                    }
                    
                    switch returnCode {
                    case 0:
                        guard let referenceNum = (data as? [String: Any])?["ReferenceNumber"] as? Int else{
                            observer.onNext((referenceNum: nil, error: APIError.General.unknown))
                            return
                        }
                        observer.onNext((referenceNum: referenceNum, error: nil))
                        
                    default:
                        guard let message = (data as? [String: Any])?["ReturnMessage"] as? String else{
                            observer.onNext((referenceNum: nil, error: APIError.General.unknown))
                            return
                        }
                        observer.onNext((referenceNum: nil, error: APIError.General.zcredit(message)))
                    }
                    
                case .failure(let error):
                    observer.onNext((referenceNum: nil, error: error))
                    
                }
                
            }
            
            return Disposables.create()
        }
        
    }
    
    func getZCreditToken(_ cardNumber: String, expDate: String) -> Observable<(token: String?, error: Error?)> {
        
        Loader.show()
        
        let params = [
            "TerminalNumber": ZCREDIT_TERMINAL_NUM,
            "Password": ZCREDIT_PASS,
            "CardNumber": cardNumber,
            "ExpDate_MMYY": expDate]
        
        return Observable.create { observer in
            self.manager.request(API.getToken, method: .post, parameters: params).responseJSON { response in
                RequestManager.printRequestDebugDescription(API.getToken, params: params, response: response)
                
                Loader.dismiss()
                
                switch response.result{
                case .success(let data):
                    
                    guard let returnCode = (data as? [String: Any])?["ReturnCode"] as? Int else{
                        observer.onNext((token: nil, error: APIError.General.unknown))
                        return
                    }
                    
                    switch returnCode {
                    case 0:
                        guard let token = (data as? [String: Any])?["Token"] as? String else{
                            observer.onNext((token: nil, error: APIError.General.unknown))
                            return
                        }
                        observer.onNext((token: token, error: nil))
                    default:
                        guard let message = (data as? [String: Any])?["ReturnMessage"] as? String else{
                            observer.onNext((token: nil, error: APIError.General.unknown))
                            return
                        }
                        observer.onNext((token: nil, error: APIError.General.zcredit(message)))
                    }
                    
                case .failure(let error):
                    observer.onNext((token: nil, error: error))
                    
                }
                
            }
            
            return Disposables.create()
        }
        
    }
    
}

import SDWebImage
extension RequestManager {
    
    func rx_sd_image(imageUrl: String?) -> Driver<UIImage?> {
        
        return Observable.create { observer in
            
            guard let imageURL = imageUrl else{
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            
            SDWebImageManager.shared().loadImage(with: URL(string: imageURL), options: .continueInBackground, progress: nil) { (image, data, error, cache, _, url) in
                observer.onNext(image)
                observer.onCompleted()
            }
        
            return Disposables.create()
            }.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background)).asDriver(onErrorJustReturn: nil)
        
    }
    
    
}

//MARK: - HELPERS
extension Dictionary where Key == String {
    
    mutating func switchKey(fromKey: Key, toKey: Key) {
        if let entry = removeValue(forKey: fromKey) {
            self[toKey] = entry
        }
    }
    
    
    var serverResponse: (error: Error?, data: [String: Any]?) {
        
        if (self["errorCode"] as? String) == "0" {
            return (nil, self["data"] as? [String: Any])
        }
        
        if let error = self["errorCode"] as? String{
            return (RequestManager.APIError.getError(from: error, message: self["errorMessage"] as? String ?? ""), nil)
        }
        
        return (RequestManager.APIError.General.parse, nil)
        
    }
    
}

extension Dictionary {
    func toJSonString() -> String {
        
        let dict = self
        var jsonString = "";
        
        do {
            
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
            
        } catch {
            print(error.localizedDescription)
        }
        
        return jsonString;
    }
}

extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}

extension RequestManager {
    
    static func json(from object:Any) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return ""
        }
        return String(data: data, encoding: String.Encoding.utf8) ?? ""
    }
    
    static fileprivate func printRequestDebugDescription(_ request:String?, params:Any? , response: AFDataResponse<Any>){
        
        switch response.result{
        case .success(let data):
            print("--------------------SERVER REQUEST--------------------")
            print("Request=\(String(describing: request ?? "nil"))\n Params=\(String(describing: params ?? "nil"))\n Response=\(data)")
            print("------------------------------------------------------")
            
        case .failure(let error):
            print("--------------------SERVER REQUEST--------------------")
            print("Request=\(String(describing: request ?? "nil"))\n Params=\(String(describing: params ?? "nil"))\n Error=\(error)")
            print("------------------------------------------------------")
        }
    }
    
    
}

extension Error {
    
    public func toast(_ interval: Double? = nil) {
        if let error = self as? RequestManager.APIError.General{
            error.errorDescription.toast(interval)
        }else{
            self.localizedDescription.toast(interval)
        }
    }
    
    public var errorMessage: String? {
        if let error = self as? RequestManager.APIError.General{
            return error.errorDescription
        }else{
            return self.localizedDescription
        }
    }
    
}
