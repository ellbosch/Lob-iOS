//
//  ThumbnailImageView.swift
//  The Lob
//
//  Created by Elliot Boschwitz on 8/3/18.
//  Copyright © 2018 Elliot Boschwitz. All rights reserved.
//

import UIKit

class ThumbnailImageView: UIImageView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

extension UIImageView {
//    func load(url: URL, slideDirection: String = "") {
//        DispatchQueue.global().async { [weak self] in
//            if let data = try? Data(contentsOf: url) {
//                if let image = UIImage(data: data) {
//                    DispatchQueue.main.async {
//                        self?.image = image
//                        
//                        if slideDirection != "" {
//                            self?.slideIn(fromDirection: slideDirection)
//                        }
//                    }
//                }
//            }
//        }
//    }
    
//    // slides in imageview from right
//    func slideInFromRight(duration: TimeInterval = 0.3, completionDelegate: AnyObject? = nil) {
//        // Create a CATransition animation
//        let slideInFromRightTransition = CATransition()
//
//        // Set its callback delegate to the completionDelegate that was provided (if any)
//        if let delegate: AnyObject = completionDelegate {
//            slideInFromRightTransition.delegate = delegate as? CAAnimationDelegate
//        }
//
//        // Customize the animation's properties
//        slideInFromRightTransition.type = kCATransitionPush
//        slideInFromRightTransition.subtype = kCATransitionFromRight
//        slideInFromRightTransition.duration = duration
//        slideInFromRightTransition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
//        slideInFromRightTransition.fillMode = kCAFillModeRemoved
//
//        // Add the animation to the View's layer
//        self.layer.add(slideInFromRightTransition, forKey: "slideInFromRightTransition")
//    }
}
