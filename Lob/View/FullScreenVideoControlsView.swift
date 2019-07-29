//
//  FullScreenVideoControlsView.swift
//  Lob
//
//  Created by Elliot Boschwitz on 7/27/19.
//  Copyright © 2019 Elliot Boschwitz. All rights reserved.
//

import AVKit
import FirebaseAnalytics
import UIKit

// MARK - Protocol for controls view delegate
protocol VideoControlViewDelegate: class {
    func didSelectSkipButton()
    func didSelectPrevButton()
    func didSelectBackNavButton()
    func didSelectPlayPauseButton()
    func didChangeScrubVideo(to time: CMTime)
    func didCompleteScrubVideo()
    func didStartScrubVideo()
}

class FullScreenVideoControlsView: UIView {
    var delegate: VideoControlViewDelegate?
    
    // Reference outlets
    @IBOutlet weak var exitViewButton: UIButton?
    @IBOutlet weak var prevButton: UIButton?
    @IBOutlet weak var skipButton: UIButton?
    @IBOutlet weak var playPauseButton: UIButton?
    @IBOutlet weak var videoScrubberSlider: UISlider?
    @IBOutlet weak var videoTimeLabel: UILabel?
    @IBOutlet weak var videoDurationLabel: UILabel?
    @IBOutlet weak var titleLabel: UILabel?
    
    func setupView() {
        prevButton?.titleLabel?.font = UIFont.fontAwesome(ofSize: 30, style: .solid)
        prevButton?.setTitle(String.fontAwesomeIcon(name: .stepBackward), for: .normal)
        
        skipButton?.titleLabel?.font = UIFont.fontAwesome(ofSize: 30, style: .solid)
        skipButton?.setTitle(String.fontAwesomeIcon(name: .stepForward), for: .normal)
        
        exitViewButton?.titleLabel?.font = UIFont.fontAwesome(ofSize: 30, style: .solid)
        exitViewButton?.setTitle(String.fontAwesomeIcon(name: .chevronLeft), for: .normal)
        
        playPauseButton?.titleLabel?.font = UIFont.fontAwesome(ofSize: 30, style: .solid)
        setupViewForPlayingVideo()      // instantiate play pause button with pause
        
//        videoScrubberSlider?.addTarget(self, action: #selector(onSliderValChanged(slider: videoScrubberSlider!, event: )), for: .valueChanged)
    }
    
    // MARK: - Sets up view for pause button
    func setupViewForPlayingVideo() {
        playPauseButton?.setTitle(String.fontAwesomeIcon(name: .pause), for: .normal)
    }
    
    // MARK: - Sets up view for play button
    func setupViewForPausedVideo() {
        playPauseButton?.setTitle(String.fontAwesomeIcon(name: .play), for: .normal)

        // keep video controls visible
        self.isHidden = false
    }
    
    @IBAction func skipButtonSelect(_ sender: Any) {
//        self.skipVideo()
        delegate?.didSelectSkipButton()
        
        
        Analytics.logEvent("fullScreenVideoChange", parameters: [
            AnalyticsParameterItemName: "skip",
            AnalyticsParameterContentType: "press"
        ])
    }
    
    // prev IBActions
    @IBAction func prevButtonSelect(_ sender: Any) {
//        self.prevVideo()
        delegate?.didSelectPrevButton()
        
        
        Analytics.logEvent("fullScreenVideoChange", parameters: [
            AnalyticsParameterItemName: "skip",
            AnalyticsParameterContentType: "press"
            ])
    }
    
    // IBActions to exit view
    @IBAction func exitButtonPress(_ sender: Any) {
//        dismissViewController()
        delegate?.didSelectBackNavButton()

        Analytics.logEvent("fullScreenModeExit", parameters: [
            AnalyticsParameterContentType: "press"
            ])
    }
    
    // sets actions for play button
    @IBAction func playPauseButtonSelect(_ sender: Any) {
        delegate?.didSelectPlayPauseButton()
    }
    
    // MARK: - Scrub action began
    @IBAction func scrubberTouchDragEnter(_ sender: Any) {
        // tell delegate that we've started scrubbing video
        delegate?.didStartScrubVideo()
    }
//
//    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
//        if let touchEvent = event.allTouches?.first {
//            switch touchEvent.phase {
//            case .began:
//                print("SLIDER: BEGAN")
//            // handle drag began
//            case .moved:
//            // handle drag moved
//                print("SLIDER: MOVED")
//            case .ended:
//                print("SLIDER: DONE")
//            // handle drag ended
//            default:
//                break
//            }
//        }
//    }
    
    // updates playback time if scrubber changed by user
    @IBAction func videoScrubberValueChanged(_ sender: Any) {
        let seconds: Int64 = Int64(self.videoScrubberSlider?.value ?? 0)
        let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
        
        delegate?.didChangeScrubVideo(to: targetTime)
    }
    
    @IBAction func scrubberTouchDragExit(_ sender: Any) {
        delegate?.didCompleteScrubVideo()
    }
    
    func setNewTitle(title: String) {
        self.titleLabel?.text = title
    }
}

// MARK: - Delegate for player
extension FullScreenVideoControlsView: PlayerViewControlsDelegate {
    // MARK: - Reset scrubber time labels
    func playerDidLoad(for playerView: PlayerView) {
        // set new duration for label
        let videoDurationFloat = Float(CMTimeGetSeconds(playerView.player?.currentItem?.asset.duration ?? CMTimeMake(value: 0, timescale: 1)))
        self.videoScrubberSlider?.maximumValue = videoDurationFloat
        self.videoDurationLabel?.text = self.convertSecondsToTimeString(secondsTotal: Int(videoDurationFloat))
        
        // reset video scrubber to 0
        self.videoScrubberSlider?.setValue(0, animated: false)
        self.videoTimeLabel?.text = "0:00"
    }
    
    // MARK: - Update control to play
    func playerDidPlay(for player: PlayerView) {
        setupViewForPlayingVideo()
    }
    
    // MARK: - Update control to pause
    func playerDidPause(for player: PlayerView) {
        setupViewForPausedVideo()
    }
    
    // MARK: - Responds to user scrub
    func playerIsScrubbing(for playerView: PlayerView, to time: Float64) {
        self.videoScrubberSlider?.value = Float(time)

        // also update labels in video by slider
        let seconds = Int(time)
        self.videoTimeLabel?.text = self.convertSecondsToTimeString(secondsTotal: seconds)
    }
    
    // MARK: - Player calls delegate to update scrubber as video plays
    func updateScrubber(to time: Float) {
        if time.isFinite {
            self.videoScrubberSlider?.value = time
            
            // also update labels in video by slider
            let seconds = Int(time)
            self.videoTimeLabel?.text = self.convertSecondsToTimeString(secondsTotal: seconds)            
        }
    }
    
    // MARK: - Private helper method that converts integer of seconds into string representing time (mm:ss)
    private func convertSecondsToTimeString(secondsTotal: Int) -> String {
        var timeString: String
        
        let seconds = secondsTotal % 60    // modulo to get just seconds
        let minutes = Int(secondsTotal/60)      // number of minutes played so far
        // add a "0" if seconds is under 10
        if seconds < 10 {
            timeString = "\(minutes):0\(seconds)"
        } else {
            timeString = "\(minutes):\(seconds)"
        }
        
        return timeString
    }
}
