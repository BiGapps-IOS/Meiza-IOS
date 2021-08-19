//
//  LogoutAlert.swift
//  Meiza
//
//  Created by Denis Windover on 20/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit

class LogoutAlert: AlertVC {
    
    var logout: ()->() = {}

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func btnLogoutTapped(_ sender: UIButton) {
        dismiss { [weak self] in
            self?.logout()
        }
    }
    
    
    @IBAction func btnCancelTapped(_ sender: UIButton) {
        dismiss(completion: nil)
    }
    
}
