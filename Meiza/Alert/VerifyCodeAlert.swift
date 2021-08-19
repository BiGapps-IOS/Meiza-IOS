//
//  VerifyCodeAlert.swift
//  Meiza
//
//  Created by Denis Windover on 17/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxAnimated

class VerifyCodeViewModel {
    
    let disposeBag = DisposeBag()
    var code = BehaviorRelay<String>(value: "")
    var isCodeValid = BehaviorRelay<Bool>(value: false)
    var okDidTap = PublishSubject<Void>()
    var userID = PublishSubject<Int>()
    
    init(_ phone: String){
        
        code.map({ $0.count == 4 }).bind(to: isCodeValid).disposed(by: disposeBag)
        
        okDidTap
            .withLatestFrom(code)
            .flatMap { RequestManager.shared.verifyPhone(phone, code: $0) }
            .map({ $0.userID != nil ? $0.userID! : 0 }).bind(to: userID).disposed(by: disposeBag)
        
    }
    
}


class VerifyCodeAlert: AlertVC {
    
    
    @IBOutlet weak var lblTitle: UILabel!{
        didSet{ lblTitle.textColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var btnOk: UIButton!{
        didSet{ btnOk.setTitleColor(AppData.shared.mainColor, for: .normal) }
    }
    @IBOutlet weak var viewCode: UIView!
    @IBOutlet weak var btnCancel: UIButton!{
        didSet{ btnCancel.setTitleColor(AppData.shared.mainColor, for: .normal) }
    }
    @IBOutlet weak var txt1: UITextField!
    @IBOutlet weak var txt2: UITextField!
    @IBOutlet weak var txt3: UITextField!
    @IBOutlet weak var txt4: UITextField!
    
    
    
    var userID: (Int)->() = { _ in }
    var viewModel: VerifyCodeViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        txt1.becomeFirstResponder()

        //MARK: - OUTPUTS
        btnOk.rx.tap.bind(to: viewModel.okDidTap).disposed(by: disposeBag)
        btnOk.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.view.endEditing(true)
        }).disposed(by: disposeBag)
        btnCancel.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: nil)
        }).disposed(by: disposeBag)
        
        //MARK: - INPUTS
        viewModel.isCodeValid.bind(to: btnOk.rx.animated.fade(duration: 0.5).isEnabled).disposed(by: disposeBag)
        viewModel.userID.subscribe(onNext: { [weak self] userID in
            if userID == 0 {
                UIView.animate(withDuration: 0.2, animations: {
                    self?.viewCode.borderColor = .red
                    self?.viewCode.borderWidth = 1
                })
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    UIView.animate(withDuration: 0.2, animations: {
                        self?.viewCode.borderColor = .clear
                        self?.viewCode.borderWidth = 0
                    })
                }
            }else{
                self?.dismiss(completion: { [weak self] in
                    self?.userID(userID)
                })
            }
            
        }).disposed(by: disposeBag)
        
    }
    
}


//MARK: - TEXTFIELD DELEGATE -
extension VerifyCodeAlert: UITextFieldDelegate {
     func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField.text!.isEmpty && string.count > 0{
            textField.text = string
            if txt1.text != "" && txt2.text != "" && txt3.text != "" && txt4.text != ""{
                viewModel.code.accept("\(txt1.text ?? "")\(txt2.text ?? "")\(txt3.text ?? "")\(txt4.text ?? "")")
            }else{
                viewModel.code.accept("")
            }
            return false
        }else if (textField.text?.count)! == 1 && string.count == 0{
            switch textField{
            case txt2:
                txt1.becomeFirstResponder()
            case txt3:
                txt2.becomeFirstResponder()
            case txt4:
                txt3.becomeFirstResponder()
            default: break
            }
            textField.text = ""
            return false
        }else if (textField.text?.count)! == 1{
            switch textField{
            case txt1:
                txt2.text = string
                txt2.becomeFirstResponder()
            case txt2:
                txt3.text = string
                txt3.becomeFirstResponder()
            case txt3:
                txt4.text = string
                txt4.becomeFirstResponder()
            default: break
            }
            if txt1.text != "" && txt2.text != "" && txt3.text != "" && txt4.text != ""{
                viewModel.code.accept("\(txt1.text ?? "")\(txt2.text ?? "")\(txt3.text ?? "")\(txt4.text ?? "")")
            }else{
                viewModel.code.accept("")
            }
            return false
        }
        return true
    }
}
