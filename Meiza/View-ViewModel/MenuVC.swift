//
//  MenuVC.swift
//  Meiza
//
//  Created by Denis Windover on 19/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

//MARK: - VIEWMODEL
class MenuViewModel {
    
    let disposeBag     = DisposeBag()
    var menuItemDidTap = PublishSubject<String>()
    var user           = BehaviorRelay<User?>(value: User.currentUser)
    
    init(){
        
        menuItemDidTap.subscribe(onNext: { navigate in
            switch navigate{
            case "myOrders": Coordinator.shared.pushOrders()
            case "editProfile": Coordinator.shared.pushAddressDetails(nil)
            case "support": Coordinator.shared.pushSupport()
            case "aboutUs": Coordinator.shared.pushInfo(.aboutUs)
            case "aboutShop": Coordinator.shared.pushInfo(.aboutShop)
            case "terms": Coordinator.shared.pushInfo(.terms)
            case "privacy": Coordinator.shared.pushInfo(.privacy)
            case "returnPolicy": Coordinator.shared.pushInfo(.returnPrivacy)
            case "logout":
                User.logout()
                Coordinator.shared.logout()
                
            default: break
            }
        }).disposed(by: disposeBag)
        
    }
    
}


//MARK: - VIEW
class MenuVC: BaseVC {
    
    
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblPhone: UILabel!
    @IBOutlet weak var btnEditProfile: UIButton!
    @IBOutlet weak var btnSupport: UIButton!
    @IBOutlet weak var btnMyOrders: UIButton!
    @IBOutlet weak var btnPrivacy: UIButton!
    @IBOutlet weak var btnReturnPolicy: UIButton!
    @IBOutlet weak var btnTerms: UIButton!
    
    @IBOutlet weak var btnAboutShop: UIButton!
    @IBOutlet weak var constrWidthMenu: NSLayoutConstraint!
    @IBOutlet weak var constrTrailingMenu: NSLayoutConstraint!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet var views: [UIView]!{
        didSet{ views?.forEach({ view in
            guard view is UIImageView else{ view.backgroundColor = AppData.shared.mainColor; return }
            (view as? UIImageView)?.imageColor = AppData.shared.mainColor
        }) }
    }
    @IBOutlet weak var btnAccessibility:UIButton!{
        didSet{ self.btnAccessibility.alpha = AppData.shared.accessibilityLink != nil && AppData.shared.accessibilityLink?.isEmpty == false ? 1 : 0 }
    }
    
    
    var viewModel = MenuViewModel()

    var didLoad = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didLoad {
            didLoad = true
            constrWidthMenu.constant = WIDTH - 87
            constrTrailingMenu.constant = WIDTH - 87
            self.view.layoutIfNeeded()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.5) {
            self.constrTrailingMenu.constant = 0
            self.btnClose.alpha = 0.5
            self.view.layoutIfNeeded()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnAboutShop.setTitle("אודות".localized, for: .normal)

        //MARK: - OUTPUTS
        btnMyOrders.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.closeMenu("myOrders")
        }).disposed(by: disposeBag)
        btnEditProfile.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.closeMenu("editProfile")
        }).disposed(by: disposeBag)
        btnSupport.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.closeMenu("support")
        }).disposed(by: disposeBag)
        btnTerms.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.closeMenu("terms")
        }).disposed(by: disposeBag)
        btnPrivacy.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.closeMenu("privacy")
        }).disposed(by: disposeBag)
        btnReturnPolicy.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.closeMenu("returnPolicy")
        }).disposed(by: disposeBag)
        btnClose.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.closeMenu(nil)
        }).disposed(by: disposeBag)
        btnAboutShop.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.closeMenu("aboutShop")
        }).disposed(by: disposeBag)
        btnAccessibility.rx.tap.subscribe(onNext: { _ in
            if let url = URL(string: AppData.shared.accessibilityLink ?? ""){
                UIApplication.shared.open(url)
            }
        }).disposed(by: disposeBag)
        
        //MARK: - INPUTS
        viewModel.user.map({ $0?.fullName ?? "אורח".localized }).bind(to: lblName.rx.text).disposed(by: disposeBag)
        viewModel.user.map({ $0?.phone }).bind(to: lblPhone.rx.text).disposed(by: disposeBag)
        viewModel.user.map({ $0?.id == nil }).bind(to: btnMyOrders.rx.isHidden).disposed(by: disposeBag)
        
        
    }
    
    //MARK: - HELPERS
    private func closeMenu(_ navigateTo: String?){
        
        UIView.animate(withDuration: 0.5, animations: {
            self.constrTrailingMenu.constant = WIDTH - 87
            self.btnClose.alpha = 0
            self.view.layoutIfNeeded()
        }) { (_) in
            self.dismiss(animated: false, completion: { [weak self] in
                if let navigate = navigateTo {
                    self?.viewModel.menuItemDidTap.onNext(navigate)
                }
            })
        }
        
    }

}
