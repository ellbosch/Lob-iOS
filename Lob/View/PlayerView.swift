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
    func playerDidLoad(for playerView: PlayerView)
    func playerIsScrubbing(for playerView: PlayerView, to time: Float64)
    func updateScrubber(to time: Float)
}

// MARK: - Protocol for player item
protocol PlayerViewPlayerDelegate: class {
    func playerDidFinishPlaying(for playerView: PlayerView)
    func playerDidLoad(for playerView: PlayerView)
    func playerFailedToLoad(for playerView: PlayerView)
}

class PlayerView: UIView {
    var delegateControlView: PlayerViewControlsDelegate?
    var delegatePlayerView: PlayerViewPlayerDelegate?
    
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
    
    var isMuted: Bool? {
        didSet {
            player?.isMuted = isMuted ?? true
        }
    }
    
    var isPlaying: Bool = false
    
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
                self.delegateControlView?.playerIsScrubbing(for: self, to: time)
            }
        }
    }
    
    // MARK: - Calls data provider to load video from URL
    func setPlayerItem(from url: URL?, success: ((AVPlayerItem) -> ())? = nil, fail: (() -> ())? = nil) {
        // instantiate playerview if not made
        if player == nil {
            player = AVPlayer(playerItem: nil)
        }
        
        // load url in background thread
        DataProvider.shared.loadVideo(for: url,
            success: { [weak self] response in
                DispatchQueue.main.async { [weak self] in
                    if let player = self?.player {
                        player.replaceCurrentItem(with: response)
                        success?(response)
                        
                        // set time observer on player
                        self?.setTimeObserver(for: player)
                        
                        // inform notifier class of new video
                        PlayerNotifier.shared.addPlayerObserver(for: player)
    
                        // observers for video load response, and play/pause
                        response.addObserver(self!, forKeyPath: "status", options: [.old, .new], context: nil)
                        player.addObserver(self!, forKeyPath: "rate", options: [.old, .new], context: nil)
                    }
                }
            },
            fail: { fail?() }
        )
    }
    
    func setTimeObserver(for player: AVPlayer) {
        // updates player scrubber slider as video plays
        player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main) { [weak self] _ in
            let time: Float64 = CMTimeGetSeconds(player.currentTime())
            self?.delegateControlView?.updateScrubber(to: Float(time))
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
                    Analytics.logEvent("videoLoadResponse", parameters: [ AnalyticsParameterItemCategory: "success" ])
                    delegateControlView?.playerDidLoad(for: self)
                    delegatePlayerView?.playerDidLoad(for: self)
                case .failed:
                    Analytics.logEvent("videoLoadResponse", parameters: [ AnalyticsParameterItemCategory: "failed" ])
                    delegatePlayerView?.playerFailedToLoad(for: self)
                case .unknown:
                    Analytics.logEvent("videoLoadResponse", parameters: [ AnalyticsParameterItemCategory: "unknown" ])
                default:
                    return
                }
            }
        case "rate":
            // tell delegate that player paused or played
            if let player = self.player {
                if player.rate > 0 {
                    self.isPlaying = true
                    delegateControlView?.playerDidPlay(for: self)
                } else {
                    self.isPlaying = false
                    delegateControlView?.playerDidPause(for: self)
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
