//
//  FullScreenView.swift
//  Lob
//
//  Created by Elliot Boschwitz on 7/27/19.
//  Copyright © 2019 Elliot Boschwitz. All rights reserved.
//

import AVKit
import FirebaseAnalytics
import UIKit

// MARK: - Protocol for full screen video view delegate
protocol FullScreenViewDelegate: class {
    func willLoadNextVideo()
    func willLoadPrevVideo()
    func willExitFullScreenMode()
}

class FullScreenView: UIView {
    @IBOutlet weak var playerView: PlayerView?
    @IBOutlet weak var thumbnailView: ThumbnailImageView?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var videoControlsView: FullScreenVideoControlsView? {
        didSet {
            // setup controls and delegate
            videoControlsView?.setupView()          // doesn't get instantiated within the video controls file unless we call here
            videoControlsView?.delegate = self
        }
    }
    
    var delegate: FullScreenViewDelegate?
    var videoPost: VideoPost? {
        didSet {
            if let videoPostNewValue = videoPost {
                // set title of video controls
                videoControlsView?.setNewTitle(title: videoPostNewValue.title)
                
                // set thumbnail image and playerview to nil
                thumbnailView?.image = nil
                playerView?.player?.replaceCurrentItem(with: nil)
            }
        }
    }
    
    // MARK: - Setup view
    func setupView() {
        setupPlayer()
        setupActivityIndicator()
        
        self.showVideoControls()
    }
    
    // MARK: - Instantiates player in playerview
    func setupPlayer() {
        let player = AVPlayer(playerItem: nil)
        self.playerView?.playerLayer.player = player
        self.playerView?.alpha = 0
        
        // set delegate of player to video controls
        self.playerView?.delegateControlView = videoControlsView
        self.playerView?.delegatePlayerView = self
    }
    
    // MARK: - Sets up activity indicator
    func setupActivityIndicator() {
        self.activityIndicator?.isHidden = false
        self.activityIndicator?.startAnimating()
    }
    
    @IBAction func skipSwipeRecognizer(_ sender: Any) {
//        self.skipVideo()
        delegate?.willLoadNextVideo()
        
        Analytics.logEvent("fullScreenVideoChange", parameters: [
            AnalyticsParameterItemName: "skip",
            AnalyticsParameterContentType: "swipe"
            ])
    }
    
    @IBAction func prevSwipeRecognizer(_ sender: Any) {
//        self.prevVideo()
        delegate?.willLoadPrevVideo()
        
        Analytics.logEvent("fullScreenVideoChange", parameters: [
            AnalyticsParameterItemName: "prev",
            AnalyticsParameterContentType: "swipe"
            ])
    }
    
    @IBAction func swipeDownToExit(_ sender: Any) {
//        dismissViewController()
        delegate?.willExitFullScreenMode()
        
        Analytics.logEvent("fullScreenModeExit", parameters: [
            AnalyticsParameterContentType: "swipeDown"
            ])
    }
    
    // shows video controls on tap
    @IBAction func tapRecognizer(_ sender: Any) {
        if let videoControlsView = self.videoControlsView {
            if videoControlsView.isHidden {
                self.showVideoControls()
            } else {
                videoControlsView.isHidden = true
            }
        }
    }
    
    func showVideoControls() {
        // show video controls briefly
        if let videoControlsView = self.videoControlsView, videoControlsView.isHidden {
            videoControlsView.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                videoControlsView.isHidden = true
            }
        }
    }
}

// MARK: - Conforms to controls delegate
extension FullScreenView: VideoControlViewDelegate {
    func didSelectSkipButton() {
        delegate?.willLoadNextVideo()
    }
    
    func didSelectPrevButton() {
        delegate?.willLoadPrevVideo()
    }
    
    func didSelectBackNavButton() {
        delegate?.willExitFullScreenMode()
    }
    
    func didSelectPlayPauseButton() {
        if let playerView = playerView {
            if playerView.isPlaying {
                playerView.player?.pause()
            } else {
                playerView.player?.play()
            }
        }
    }
    
    func didChangeScrubVideo(to time: CMTime) {
        self.playerView?.player?.seek(to: time)
    }
    
    func didCompleteScrubVideo() {
//        self.playerView?.player?.play()
    }
    
    func didStartScrubVideo() {
        self.playerView?.player?.pause()
        self.videoControlsView?.isHidden = false
    }
}

extension FullScreenView: PlayerViewPlayerDelegate {
    
    func playerDidLoad(for playerView: PlayerView) {
        self.activityIndicator?.stopAnimating()
        self.playerView?.fadeIn()
        self.playerView?.playerLayer.player?.play()
    }
    
    func playerDidFinishPlaying(for playerView: PlayerView) {
        // skip to next video and remove observer
        delegate?.willLoadNextVideo()
        
        Analytics.logEvent("fullScreenVideoChange", parameters: [
            AnalyticsParameterItemName: "skip",
            AnalyticsParameterContentType: "auto"
        ])
    }
}

// MARK: - Animations for thumbnail image
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

