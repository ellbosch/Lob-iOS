//
//  PlayerView.swift
//  The Lob
//
//  Created by Elliot Boschwitz on 6/30/18.
//  Copyright © 2018 Elliot Boschwitz. All rights reserved.
//

import AVKit
import UIKit

class PlayerView: UIView {
    
//    weak var cell: LinkTableViewCell?

    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    // Override UIView property
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    

    
}

extension UIView {
    /// Fade in a view with a duration
    ///
    /// Parameter duration: custom animation duration
    func fadeIn(withDuration duration: TimeInterval = 1.0) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1.0
        })
    }
    
    /// Fade out a view with a duration
    ///
    /// - Parameter duration: custom animation duration
    func fadeOut(withDuration duration: TimeInterval = 1.0) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.0
        })
    }
    
    // slides in imageview from right
    func slideIn(fromDirection: String, duration: TimeInterval = 0.3, completionDelegate: AnyObject? = nil) {
        // Create a CATransition animation
        let slideInFromTransition = CATransition()
        
        // Set its callback delegate to the completionDelegate that was provided (if any)
        if let delegate: AnyObject = completionDelegate {
            slideInFromTransition.delegate = delegate as? CAAnimationDelegate
        }
        
        // Customize the animation's properties
        slideInFromTransition.type = CATransitionType.push
//        slideInFromTransition.subtype = kCATransitionFromRight
        slideInFromTransition.duration = duration
        slideInFromTransition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        slideInFromTransition.fillMode = CAMediaTimingFillMode.removed
        
        // Add the animation to the View's layer
        if fromDirection == "right" {
            slideInFromTransition.subtype = CATransitionSubtype.fromLeft
            self.layer.add(slideInFromTransition, forKey: "slideInFromRightTransition")
        } else if fromDirection == "left" {
            slideInFromTransition.subtype = CATransitionSubtype.fromRight
            self.layer.add(slideInFromTransition, forKey: "slideInFromLeftTransition")
        }
    }
}
