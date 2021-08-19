//
//  InfoVC.swift
//  Meiza
//
//  Created by Denis Windover on 19/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

//MARK: - VIEWMODEL
class InfoViewModel {
    
    let disposeBag = DisposeBag()
    var type:        InfoType
    var title:       Observable<String>
    var content:     Observable<String?>
    
    init(_ type: InfoType){
        
        self.type = type
        
        func getTitle(_ type: InfoType) -> Observable<String> {
            switch type {
            case .aboutShop: return Observable.just("אודות".localized)
            case .aboutUs: return Observable.just("מי אנחנו".localized)
            case .privacy: return Observable.just("מדיניות פרטיות".localized)
            case .returnPrivacy: return Observable.just("מדיניות ביטולים".localized)
            case .terms: return Observable.just("תקנון".localized)
            
            }
        }
        func getContent(_ type: InfoType) -> Observable<String?> {
            switch type {
            case .aboutShop: return Observable.just(AppData.shared.shop.about)
            case .aboutUs: return Observable.just(AppData.shared.aboutUs)
            case .privacy: return Observable.just(AppData.shared.privacy)
            case .returnPrivacy: return Observable.just(AppData.shared.returnPolicy)
            case .terms: return Observable.just(AppData.shared.terms)
            
            }
        }
        
        title = getTitle(type)
        content = getContent(type)
        
    }
    
}

enum InfoType {
    case aboutUs, terms, privacy, returnPrivacy, aboutShop
}

//MARK: - VIEW
class InfoVC: BaseVC {
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var txtViewContent: UITextView!
    
    
    var viewModel: InfoViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        //MARK: - INPUTS
        viewModel.title.bind(to: lblTitle.rx.text).disposed(by: disposeBag)
        viewModel.content.subscribe(txtViewContent.rx.text).disposed(by: disposeBag)
    }


}
