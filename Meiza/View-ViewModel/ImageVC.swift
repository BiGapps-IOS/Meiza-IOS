//
//  ImageVC.swift
//  Meiza
//
//  Created by Denis Windover on 08/09/2020.
//  Copyright © 2020 BigApps. All rights reserved.
//

import UIKit
import EFImageViewZoom


class ImageVC: BaseVC,  EFImageViewZoomDelegate{
    
    
   
    @IBOutlet weak var imageViewZoom: EFImageViewZoom!

    
    var image: UIImage!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageViewZoom._delegate = self
        self.imageViewZoom.image = image
        self.imageViewZoom.contentMode = .left
        
//        iv.image = image
//
//        scrollView.minimumZoomScale = 1.0
//        scrollView.maximumZoomScale = 6.0
        
        
//        iv.isUserInteractionEnabled = true
//        let pinchMethod = UIPinchGestureRecognizer(target: self, action: #selector(pinchImage(sender:)))
//        iv.addGestureRecognizer(pinchMethod)

        
    }
    
//    @objc func pinchImage(sender: UIPinchGestureRecognizer) {
//        guard sender.view != nil else { return }
//
//        if let scale = (sender.view?.transform.scaledBy(x: sender.scale, y: sender.scale)) {
//            guard scale.a > 1.0 else { return }
//            guard scale.d > 1.0 else { return }
//            sender.view?.transform = scale
//            sender.scale = 1.0
//        }
//    }

}

//extension ImageVC: UIScrollViewDelegate {
//    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        return iv
//    }
//}
