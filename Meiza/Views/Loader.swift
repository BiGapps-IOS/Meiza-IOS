//
//  Loader.swift
//  Meiza
//
//  Created by Denis Windover on 05/05/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView

class Loader{
    
    private static var progressIndicator:NVActivityIndicatorView?
    private static var progressHoldView:UIView?
    private static var isAlreadyShown:Bool = false
    
    
    class func show(){
        
        if isAlreadyShown{
            return
        }
        
        if progressIndicator == nil{
            progressIndicator = Loader.getProgressIndicatorView(withFrame: CGRect.init(x: (WIDTH/2)-30, y: (HEIGHT/2)-30, width: 60, height: 60), color: AppData.shared.mainColor)
        }
        
        if progressHoldView == nil{
            progressHoldView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: WIDTH, height: HEIGHT))
            progressHoldView!.backgroundColor = .black
            progressHoldView!.alpha = 0.7
        }
        
        DispatchQueue.main.async {
            AppDelegate.getMainDelegate().window?.addSubview(progressHoldView!)
            AppDelegate.getMainDelegate().window?.addSubview(progressIndicator!)
        }
        
        isAlreadyShown = true
    }
    
    class func dismiss(){
        DispatchQueue.main.async {
            progressHoldView?.removeFromSuperview()
            progressIndicator?.removeFromSuperview()
        }
        isAlreadyShown = false
    }
    
    class func getProgressIndicatorView(withFrame frame:CGRect, color:UIColor)->NVActivityIndicatorView{
        let progressIndicator = NVActivityIndicatorView.init(frame: frame)
        progressIndicator.color = color
        progressIndicator.type = .ballScaleRippleMultiple
        progressIndicator.startAnimating()
        
        return progressIndicator
    }
    
}
