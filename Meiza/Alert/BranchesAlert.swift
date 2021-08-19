//
//  BranchesAlert.swift
//  Meiza
//
//  Created by Denis Windover on 02/11/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


class BranchesViewModel {
    
    let disposeBag = DisposeBag()
    var branches = BehaviorRelay<[Branch]>(value: [])
    var chosenBranch = BehaviorRelay<Branch?>(value: nil)
    var branchDidSelect = PublishSubject<IndexPath>()
    
    
    init(_ branches: [Branch]){
        
        Observable.just(branches).bind(to: self.branches).disposed(by: disposeBag)
        
        branchDidSelect.withLatestFrom(self.branches) { _indexPath, _branches -> Branch in
            return _branches[_indexPath.row]
        }.bind(to: chosenBranch).disposed(by: disposeBag)
        
        chosenBranch.skip(1).subscribe(onNext: { [weak self] _ in
            self?.branches.accept(self?.branches.value ?? [])
        }).disposed(by: disposeBag)
        
    }
    
    
}



class BranchesAlert: AlertVC {
    
    
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnContinue: UIButton!{
        didSet{ btnContinue.backgroundColor = AppData.shared.mainColor }
    }
    @IBOutlet weak var tblViewBranches: UITableView!
    
    var viewModel: BranchesViewModel!
    var actionContinue: (Branch)->() = { _ in }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        btnClose.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.dismiss(completion: nil)
        }).disposed(by: disposeBag)
        
        btnContinue.rx.tap.subscribe(onNext: { [weak self] _ in
            
            guard let branch = self?.viewModel.chosenBranch.value else{ return }
            
            self?.dismiss(completion: {
                self?.actionContinue(branch)
            })
        }).disposed(by: disposeBag)
        
        tblViewBranches.rx.itemSelected.bind(to: viewModel.branchDidSelect).disposed(by: disposeBag)
        
        
        tblViewBranches.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        viewModel.branches.bind(to: tblViewBranches.rx.items(cellIdentifier: "cell", cellType: UITableViewCell.self)){
            [unowned self] row, branch, cell in
            
            cell.textLabel?.text = branch.name
            cell.textLabel?.textColor = self.viewModel.chosenBranch.value?.id == branch.id ? .red : .black
            cell.textLabel?.textAlignment = .right
            cell.textLabel?.font = UIFont(name: "Heebo-Regular", size: 18)
            
        }.disposed(by: disposeBag)
        
        
        viewModel.chosenBranch.map({ $0 != nil }).bind(to: btnContinue.rx.isEnabled).disposed(by: disposeBag)
        
    }


}
