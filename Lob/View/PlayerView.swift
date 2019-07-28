//
//  PlayerView.swift
//  The Lob
//
//  Created by Elliot Boschwitz on 6/30/18.
//  Copyright © 2018 Elliot Boschwitz. All rights reserved.
//

import AVKit
import FirebaseAnalytics
import UIKit

// MARK: - Protocol for Player View controls
protocol PlayerViewControlsDelegate: class {
    func playerDidPlay(for playerView: PlayerView)
    func playerDidPause(for playerView: PlayerView)
    func playerWillStart(for playerView: PlayerView)
    func playerDidLoad(for playerView: PlayerView)
    func playerIsScrubbing(for playerView: PlayerView, to time: Float64)
}

// MARK: - Protocol for player item
protocol PlayerViewPlayerDelegate: class {
    func playerDidFinishPlaying(for playerView: PlayerView)
    func playerWillLoad(for playerView: PlayerView)
}

class PlayerView: UIView {
    var delegateControls: PlayerViewControlsDelegate?
    var delegatePlayer: PlayerViewPlayerDelegate?
    
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            newValue?.addObserver(self, forKeyPath: "rate", options: [.old, .new], context: nil)
            playerLayer.player = newValue
        }
    }

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    // create observers when current item is set
//    var playerItem: AVPlayerItem? {
//        get {
//            return playerLayer.player?.currentItem
//        }
//        set {
//            // play/pause observer
//            newValue?.addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
//
//            // setup video did end playing observer and remove last made one
//            if let videoDidEndPlayingObserver = self.videoDidEndPlayingObserver {
//                NotificationCenter.default.removeObserver(videoDidEndPlayingObserver)
//            }
//
//            self.videoDidEndPlayingObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: newValue, queue: .main) { [weak self] _ in
//
//                // skip to next video and remove observer
//                if let myView = self {
//                    self?.delegatePlayer?.playerDidFinishPlaying(for: myView)
//                }
//            }
//
//            // tell delegate that new video loaded
//            delegateControls?.playerDidLoad(for: self)
//        }
//    }
    
    var isMuted: Bool? {
        didSet {
            player?.isMuted = isMuted ?? true
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    // MARK: - Sets up player view
    func setupView() {
        // updates player scrubber slider as video plays
        self.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main) { (CMTime) -> Void in
            if self.player?.currentItem?.status == .readyToPlay {
                let time: Float64 = CMTimeGetSeconds((self.player?.currentTime() ?? CMTimeMake(value: 0, timescale: 1)))
                self.delegateControls?.playerIsScrubbing(for: self, to: time)
            }
        }
    }
    
    // MARK: - Observers for player
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case "status":
            if let playerItem = player?.currentItem {
                let status = playerItem.status
                // send error to analytics if video failed and tell delegate that player will start if successful
                switch status {
                case .readyToPlay:
                    Analytics.logEvent("videoLoadSuccess", parameters: nil)
                    delegateControls?.playerWillStart(for: self)
                    delegatePlayer?.playerWillLoad(for: self)
                case .failed:
                    Analytics.logEvent("videoLoadFail", parameters: nil)
                case .unknown:
                    Analytics.logEvent("videoLoadUnknown", parameters: nil)
                default:
                    return
                }
            }
        case "rate":
            // tell delegate that player paused or played
            if let player = self.player {
                if player.rate > 0 {
                    delegateControls?.playerDidPlay(for: self)
                } else {
                    delegateControls?.playerDidPause(for: self)
                }
            }
        default:
            return
        }
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
