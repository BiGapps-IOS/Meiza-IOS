//
//  BillVC.swift
//  Meiza
//
//  Created by Denis Windover on 17/11/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import WebKit

class BillVC: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    
    
    var link: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        loader.startAnimating()
        
    }
    
    override func viewDidAppear(_ animated:Bool){
        super.viewDidAppear(animated)
      
        guard let url = URL(string: link) else{ loader.stopAnimating(); return }
        
        webView?.navigationDelegate = self
        webView?.scrollView.bounces = false
        
        let urlRequest:URLRequest = URLRequest(url: url)
        webView?.load(urlRequest)
        
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loader.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loader.stopAnimating()
    }

}
