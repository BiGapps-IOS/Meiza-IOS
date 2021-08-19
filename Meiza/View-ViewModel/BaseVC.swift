//
//  BaseVC.swift
//  Meiza
//
//  Created by Denis Windover on 05/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SDWebImage

class BaseVC: UIViewController {
    
    @IBOutlet weak var btnBack: UIButton! = nil
    @IBOutlet weak var btnMenu: UIButton! = nil
    @IBOutlet weak var btnSearch: UIButton! = nil
    @IBOutlet weak var ivBg: UIImageView! = nil {
        didSet{ ivBg.image = AppData.shared.bg }
    }
    
    let disposeBag = DisposeBag()
    
    
    //MARK: - LIFECYCLE
    deinit {
        
        NotificationCenter.default.removeObserver(self)
        
        print("-------DEINIT---------")
        print(self)
        print("-------DEINIT---------")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnBack?.rx.tap.subscribe(onNext: { [weak self] _ in
            if let main = self as? MainVC {
                main.viewMain.alpha = 0
            }
            Coordinator.shared.goBack()
        }).disposed(by: disposeBag)
        
        btnMenu?.rx.tap.subscribe(onNext: { [weak self] _ in
            if self is SearchVC || self is CreditCartDetailsVC || self is CVVConfirmationVC {
                self?.btnMenu?.isHighlighted = false
                self?.btnMenu?.imageView?.image = UIImage(named: "menu")?.withRenderingMode(.alwaysTemplate)
                self?.btnMenu?.imageView?.tintColor = AppData.shared.mainColor
            }
            
            Coordinator.shared.openMenuVC()
        }).disposed(by: disposeBag)
        
        btnSearch?.rx.tap.subscribe(onNext: { [weak self] _ in
            if self is CreditCartDetailsVC{
                self?.btnSearch?.isHighlighted = false
                self?.btnSearch?.imageView?.image = UIImage(named: "search")?.withRenderingMode(.alwaysTemplate)
                self?.btnSearch?.imageView?.tintColor = AppData.shared.mainColor
            }
            Coordinator.shared.pushSearch()
        }).disposed(by: disposeBag)
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if self is MainVC || self is CheckoutVC || self is SummaryVC || self is SearchVC || self is OrdersVC || self is OrderVC {
            return .lightContent
        }else{
            if #available(iOS 13.0, *) {
                return .darkContent
            } else {
                return .default
            }
        }
        
    }
    
    
    var isNeedToClearPack = true
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        if self is MainVC || self is SearchVC || self is CartVC {
            if AppData.shared.currentPack.value != nil && isNeedToClearPack{
                AppData.shared.currentPack.accept(nil)
            }
            if AppData.shared.editingPack.value != nil {
                AppData.shared.editingPack.accept(nil)
            }
            isNeedToClearPack = true
        }
    }
    
}

