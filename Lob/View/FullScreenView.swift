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
    var delegate: FullScreenViewDelegate?
    var videoPost: VideoPost? {
        didSet {
            if let videoPostNewValue = videoPost {
                videoControlsView?.setNewTitle(title: videoPostNewValue.title)
            }
        }
    }
    var isVideoControlsVisible = false
    var isVideoPaused = false {
        didSet {
            if !isVideoPaused {
                self.playerView?.player?.play()
            } else {
                self.playerView?.player?.pause()
            }
        }
    }

    // Reference outlets
    @IBOutlet weak var playerView: PlayerView?
    @IBOutlet weak var thumbnailView: ThumbnailImageView?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var videoControlsView: FullScreenVideoControlsView?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    // MARK: - Setup view
    func setupView() {
        // set delegates
        videoControlsView?.delegate = self
        
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
        self.playerView?.delegateControls = videoControlsView
        self.playerView?.delegatePlayer = self
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
        self.videoControlsView?.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.videoControlsView?.isHidden = true
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
        self.isVideoPaused.toggle()
    }
    
    func didCompleteScrubVideo(to time: CMTime) {
        self.playerView?.player?.seek(to: time)
    }
    
    func didStartScrubVideo() {
        self.playerView?.player?.pause()
        self.videoControlsView?.isHidden = false
    }
}

extension FullScreenView: PlayerViewPlayerDelegate {
    
    func playerWillLoad(for playerView: PlayerView) {
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
