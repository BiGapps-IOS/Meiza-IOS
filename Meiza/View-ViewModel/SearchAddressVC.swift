//
//  FindAddressVC.swift
//  Wolf
//
//  Created by Denis Windover on 08/11/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import CoreLocation


class SearchAddressViewModel {
    
    let disposeBag       = DisposeBag()
    var addressSearch    = BehaviorRelay<String>(value: "")
    var addresses        = BehaviorRelay<[Address]>(value: [])
    var addressDidSelect = PublishSubject<IndexPath>()
    var deleteAddress    = PublishSubject<Void>()
    var goBack           = PublishSubject<Void>()
    var chosenAddress    = PublishSubject<Address>()
    
    init(){
        
        addressDidSelect.map({ [weak self] in
            self?.addresses.value[$0.row]
        }).subscribe(onNext: { [weak self] address in
            guard let address = address else{ return }
            self?.fetchLocation(for: address)
        }).disposed(by: disposeBag)
        
        addressSearch
            .filter({ [weak self] text in
                self?.addresses.accept([])
                return text != ""
            })
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] text in
                self?.fetchAddresses(with: text)
            }).disposed(by: disposeBag)
        
        deleteAddress.subscribe(onNext: { [weak self] _ in
            self?.addressSearch.accept("")
        }).disposed(by: disposeBag)
        
        goBack.subscribe(onNext: { _ in
            NAV.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        
    }
    
    private func fetchLocation(for address: Address){
        
        RequestManager.shared.fetchLocation(for: address).subscribe(onNext: { [weak self] add in
            self?.chosenAddress.onNext(add)
        }, onError: { (error) in
            print(error.localizedDescription)
        }).disposed(by: disposeBag)
        
    }
    
    private func fetchAddresses(with text: String){
        
        RequestManager.shared.fetchAddresses(with: text).subscribe(onNext: { [weak self] addresses in
            self?.addresses.accept(addresses)
        }, onError: { (error) in
            print(error.localizedDescription)
        }).disposed(by: disposeBag)
        
    }
    
}

typealias SearchResult = ((lat: Double, lon: Double, address: String))->()

class SearchAddressVC: BaseVC {
    

    @IBOutlet weak var viewSearch: UIView!
    @IBOutlet weak var btnDelete: UIButton!
    @IBOutlet weak var txtSearch: UITextField!
    @IBOutlet weak var tbl: UITableView!
    
    let viewModel = SearchAddressViewModel()
    var didLoad = false
    var order: NewOrder!
//    var didGetAddress: SearchResult?
    
//MARK: - LIFECYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtSearch.becomeFirstResponder()

        txtSearch.rx.text.orEmpty.bind(to: viewModel.addressSearch).disposed(by: disposeBag)
        txtSearch.rx.text.orEmpty
        .scan("") { prev, new -> String in
            if new.containsEmoji{
                return prev ?? ""
            }else{
                return new
            }
        }.subscribe(txtSearch.rx.text).disposed(by: disposeBag)
        
        tbl.rx.itemSelected.bind(to: viewModel.addressDidSelect).disposed(by: disposeBag)
        
        btnDelete.rx.tap.map({ return "" }).bind(to: txtSearch.rx.text.orEmpty).disposed(by: disposeBag)
        
        btnDelete.rx.tap.bind(to: viewModel.deleteAddress).disposed(by: disposeBag)
        
        btnBack.rx.tap.bind(to: viewModel.goBack).disposed(by: disposeBag)
        
        viewModel.addresses
            .bind(to: tbl.rx.items(cellIdentifier: "AddressCell", cellType: AddressCell.self)){ row, address, cell in
                cell.viewModel = AddressCellViewModel(address: address)
        }.disposed(by: disposeBag)
        
        
        viewModel.chosenAddress.subscribe(onNext: { [weak self] address in
            if address.lat != nil && address.lon != nil {
                User.currentUser?.lat = address.lat
                User.currentUser?.lon = address.lon
                User.currentUser?.isNeedRemoveTempLocation = true

                if AppData.shared.shop.isAreaDelivery {
                    RequestManager.shared.getDeliveryPrice(CLLocation(latitude: address.lat!, longitude: address.lon!)).bind { _deliveryCost in
                        if let deliveryCost = _deliveryCost, AppData.shared.shop.isAreaDelivery {
                            AppData.shared.polygonsDeliveryCost = deliveryCost
                        }else{ AppData.shared.polygonsDeliveryCost = nil }
                        self?.checkIfNeedDeliveryCostAlert(self?.order)
                    }.disposed(by: self!.disposeBag)
                }else{
                    self?.checkIfNeedDeliveryCostAlert(self?.order)
                }
                    
//                self?.dismiss(animated: true, completion: {
//                    self?.didGetAddress?((lat: address.lat!, lon: address.lon!, address: address.address))
//                })
            }
        }).disposed(by: disposeBag)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !didLoad {
            didLoad = true
            viewSearch.dropShadow(color: .lightGray, raduis: 2, opacity: 1)
        }
        
        
    }

}

extension SearchAddressVC {
    
    private func checkIfNeedDeliveryCostAlert(_ order: NewOrder?){
        
        guard let order = order else { return }
        
        
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
