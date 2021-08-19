//
//  MapVC.swift
//  Meiza
//
//  Created by Denis Windover on 08/11/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import GoogleMaps
import RxCocoa
import RxSwift


class MapViewModel {
    //default loc - 32.0768296, 34.7903317
    let disposeBag = DisposeBag()
    var location = BehaviorRelay<CLLocation>(value: CLLocation(latitude: 32.0768296, longitude: 34.7903317))
    var address = BehaviorRelay<Address?>(value: nil)
    
    init(){
        
        location.flatMap({ RequestManager.shared.fetchAddress(with: $0) }).bind(to: address).disposed(by: disposeBag)
        
    }
    
}

let MAX_ZOOM:Float = 18
let MIN_ZOOM:Float = 5
let DEFAULT_ZOOM:Float = 15

class MapVC: BaseVC {
    
    @IBOutlet weak var btnFindMe: UIButton!
    @IBOutlet weak var lblCurrentAddress: UILabel!
    @IBOutlet weak var btnEditAddress: UIButton!
    @IBOutlet weak var btnUpdateAddress: UIButton!{
        didSet{ btnUpdateAddress.backgroundColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet weak var ivCenterMap: UIImageView!{
        didSet{ ivCenterMap.imageColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var ivFindMe: UIImageView!{
        didSet{ ivFindMe.imageColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var line: UIView!{
        didSet{ line.backgroundColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var ivPen: UIImageView!{
        didSet{ ivPen.imageColor = AppData.shared.mainColor }
    }
    
    var order: NewOrder!
    
    private let locationManager:CLLocationManager = CLLocationManager()
    var viewModel = MapViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        mapView.setMinZoom(MIN_ZOOM, maxZoom: MAX_ZOOM)
        mapView.delegate = self
        mapView.isMyLocationEnabled = true
        
        
        btnBack.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
        btnFindMe.rx.tap
            .map({ [unowned self] _ in return self.mapView.myLocation })
            .filter({ $0 != nil })
            .map({ [unowned self] in GMSCameraPosition(latitude: $0!.coordinate.latitude, longitude: $0!.coordinate.longitude, zoom: self.mapView.camera.zoom) })
            .subscribe(onNext: { position in
                DispatchQueue.main.async {
                    self.mapView.animate(to: position)
                }
            })
            .disposed(by: disposeBag)
        
        btnEditAddress.rx.tap.subscribe(onNext: { [unowned self] _ in
            Coordinator.shared.searchAddress(order)
        }).disposed(by: disposeBag)
        
        btnUpdateAddress.rx.tap.withLatestFrom(viewModel.location).map { location -> CLLocation in
            User.currentUser?.lat = location.coordinate.latitude
            User.currentUser?.lon = location.coordinate.longitude
            User.currentUser?.isNeedRemoveTempLocation = true
            return location
        }.flatMap({ AppData.shared.shop.isAreaDelivery ? RequestManager.shared.getDeliveryPrice($0) : Observable.just(nil) }).subscribe(onNext: { [unowned self] _deliveryCost in
            if let deliveryCost = _deliveryCost, AppData.shared.shop.isAreaDelivery {
                AppData.shared.polygonsDeliveryCost = deliveryCost
            }else{ AppData.shared.polygonsDeliveryCost = nil }
            checkIfNeedDeliveryCostAlert(order)
        }).disposed(by: disposeBag)
        
        viewModel.address.map({ $0?.address }).debug().bind(to: lblCurrentAddress.rx.text).disposed(by: disposeBag)
        
        viewModel.location.take(3).subscribe(onNext: { [unowned self] _location in
            
            DispatchQueue.main.async {
                self.mapView.camera = GMSCameraPosition(latitude: _location.coordinate.latitude, longitude: _location.coordinate.longitude, zoom: DEFAULT_ZOOM)
            }
            
        }).disposed(by: disposeBag)
        
    }
    
    var didLoad = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !didLoad {
            didLoad = true
            checkLocationPermission { [unowned self] in
                Observable.just(self.locationManager.location).filter({ $0 != nil }).map({ $0! }).bind(to: self.viewModel.location).disposed(by: self.disposeBag)
            }
        }
        
    }
    
    private func checkLocationPermission(completion: @escaping()->()) {
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.checkLocationPermission(completion: completion)
                return
            }
        }else if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            completion()
        }
        
    }

    private func checkIfNeedDeliveryCostAlert(_ order: NewOrder){
        
        if order.orderType == "delivery" && (User.currentUser?.lat == nil || User.currentUser?.lon == nil) {
            
            return
        }
        
        if order.orderType == "delivery" && !AppData.shared.shop.isDistanceOk && AppData.shared.shop.isAreaDelivery == false || AppData.shared.shop.isAreaDelivery && AppData.shared.polygonsDeliveryCost == nil {
            AlertCoordinator.shared.radiusErrorOrder()
            return
        }
        
        if (AppData.shared.shop.isAreaDelivery || AppData.shared.shop.deliveryZones.count > 0) && order.orderType == "delivery" {
            AlertCoordinator.shared.deliveryCost { [weak self] in
                self?.goNext(order)
            }
        }else{
            goNext(order)
        }
    }
    
    private func goNext(_ order: NewOrder){
        
        if order.paymentType == "credit" {
            if User.currentUser?.creditCartLast4Digits == nil {
                Coordinator.shared.pushCreditCardDetails(order)
            }else{
                Coordinator.shared.pushCVVConfirmation(order)
            }
        }else if order.paymentType == "cash" {
            
            RequestManager.shared.makeOrder(order).subscribe(onNext: { response in
                if let error = response.error {
                    if let type = (error as? RequestManager.APIError.General)?.type {
                        if type == .dateError {
                            AlertCoordinator.shared.dateError(order.orderType) {
                                if !((order.orderType == "delivery" && AppData.shared.shop.withoutFutureDelivery) || (order.orderType == "pickup" && AppData.shared.shop.withoutFuturePickup)) {
                                    Coordinator.shared.popToSummaryVCAfterOrderDateError()
                                }
                            }
                            return
                        }
                    }
                    error.toast(3)
                }
                else if let id = response.orderID {
                    CartProduct.deleteAllCartProducts()
                    AlertCoordinator.shared.orderSuccess(order.paymentType ?? "", orderID: id)
                }
            }).disposed(by: disposeBag)
            
        }
    }
    
}

extension MapVC: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        Observable.just(CLLocation(latitude: position.target.latitude, longitude: position.target.longitude)).bind(to: viewModel.location).disposed(by: disposeBag)
    }
}
