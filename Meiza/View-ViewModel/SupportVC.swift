//
//  SupportVC.swift
//  Meiza
//
//  Created by Denis Windover on 20/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

//MARK: - VIEWMODEL
class SupportViewModel {
    
    let disposeBag     = DisposeBag()
    var contentTop:      Observable<NSAttributedString>
    var contentDays:     Observable<NSAttributedString>
    var contentHours:    Observable<NSAttributedString>
    var contentBottom:   Observable<String>
    var thanksDidTap   = PublishSubject<Void>()
    
    init(){
        
        let top = NSMutableAttributedString()
        top
            .normal("\(AppData.shared.shop.name ?? "")\n", isMedium: true, fontSize: 20, color: AppData.shared.mainColor)
            .normal("\(AppData.shared.shop.address ?? "")\n", isMedium: true, fontSize: 20, color: AppData.shared.mainColor)
            .normal("\("טלפון".localized): \(AppData.shared.shop.phone2 ?? "")\n", fontSize: 18, color: .black)
        
//        let bottom = NSMutableAttributedString()
//        bottom
//            .normal("לשינוי או ביטול, צרו איתנו קשר".localized)
        
        let days = NSMutableAttributedString()
        days
            .normal("\(AppData.shared.shop.workingDaysStr)\n", fontSize: 18, alignment: .right)
        
        let hours = NSMutableAttributedString()
        hours
            .normal("\(AppData.shared.shop.workingHoursStr)\n", fontSize: 18, alignment: .right)
        
        contentTop = Observable.just(top)
        contentBottom = Observable.just("לשינוי או ביטול, צרו איתנו קשר".localized)
        contentDays = Observable.just(days)
        contentHours = Observable.just(hours)
        
        thanksDidTap.subscribe(onNext: { _ in
            Coordinator.shared.goBack()
        }).disposed(by: disposeBag)
        
    }
    
}

//MARK: - VIEW
class SupportVC: BaseVC {
    
    @IBOutlet weak var btnThanks: UIButton!{
        didSet{ btnThanks.setTitleColor(AppData.shared.mainColor, for: .normal) }
    }
    @IBOutlet weak var txtViewTop: UITextView!
    @IBOutlet weak var txtViewDays: UITextView!
    @IBOutlet weak var txtViewHours: UITextView!
    @IBOutlet weak var txtViewBottom: UITextView!
    
    
    @IBOutlet weak var viewMain: UIView!
    
    var viewModel = SupportViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        //MARK: - OUTPUTS
        btnThanks.rx.tap.bind(to: viewModel.thanksDidTap).disposed(by: disposeBag)
        
        //MARK: - INPUTS
        viewModel.contentTop.bind(to: txtViewTop.rx.attributedText).disposed(by: disposeBag)
        viewModel.contentBottom.bind(to: txtViewBottom.rx.text).disposed(by: disposeBag)
        viewModel.contentDays.bind(to: txtViewDays.rx.attributedText).disposed(by: disposeBag)
        viewModel.contentHours.bind(to: txtViewHours.rx.attributedText).disposed(by: disposeBag)
    
    }


}
