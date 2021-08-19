//
//  ConnectionManager.swift
//  Meiza
//
//  Created by Denis Windover on 07/02/2021.
//  Copyright © 2021 BigApps. All rights reserved.
//

import Foundation
import Reachability

class ConnectionManager {
    
    static let shared = ConnectionManager()
    private var reachability: Reachability?
    
    func start(){
        print("Reachability has started!")
    }
    
    init(){
        
        reachability = try! Reachability()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do{
            try reachability?.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
        
    }
    
    @objc func reachabilityChanged(note: Notification) {

      let reachability = note.object as! Reachability

      switch reachability.connection {
      case .wifi:
          print("Reachable via WiFi")
      case .cellular:
          print("Reachable via Cellular")
      case .unavailable:
        print("Network not reachable")
      case .none:
        print("Reachable via None")
      }
    }
    
}
