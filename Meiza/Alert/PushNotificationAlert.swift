//
//  PushNotificationAlert.swift
//  Meiza
//
//  Created by Denis Windover on 12/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import OneSignal


class PushNotificationAlert: AlertVC {
    
    
    @IBOutlet weak var lblTitle: UILabel!
    
    
    @IBAction func btnNextTimeTapped(_ sender: UIButton) {
        self.dismiss(completion: nil)
    }
    
    @IBAction func btnYesTapped(_ sender: UIButton) {
        self.dismiss {
            OneSignal.promptForPushNotifications(userResponse: { accepted in
                RequestManager.shared.setOnesignal()
            })
        }
    }
    
    
}
