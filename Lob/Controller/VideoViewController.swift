//
//  VideoViewController.swift
//  The Lob
//
//  Created by Elliot Boschwitz on 8/25/18.
//  Copyright © 2018 Elliot Boschwitz. All rights reserved.
//

import AVKit
import FirebaseAnalytics
import SDWebImage
import UIKit

class VideoViewController: UIViewController {
    
    @IBOutlet weak var videoControlsView: UIView?
    @IBOutlet weak var playerView: PlayerView?
    @IBOutlet weak var thumbnailView: ThumbnailImageView?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var exitFullScreenButton: UIButton?
    @IBOutlet weak var prevVideoButton: UIButton?
    @IBOutlet weak var skipVideoButton: UIButton?
    @IBOutlet weak var playButton: UIButton?
    @IBOutlet weak var videoScrubberSlider: UISlider?
    @IBOutlet weak var videoTimeLabel: UILabel?
    @IBOutlet weak var videoDurationLabel: UILabel?
    @IBOutlet weak var titleLabel: UILabel?
    
    var videos: [VideoPost]?
    var videoIndex: Int = 0
    var isVideoControlsVisible: Bool = false
    var league: String?
    var skipObserver: NSObjectProtocol?
    var videoAsset: AVAsset?
    var shouldPlay: Bool = true
    var openedFromShare: Bool = false
    
    // hides status bar
    override var prefersStatusBarHidden: Bool {
        return !openedFromShare
    }
    
    // when status bar is visible on share, make sure text is white (since against dark background)
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
 
        // instantiate player in playerView
        let player = AVPlayer(playerItem: nil)
        self.playerView?.playerLayer.player = player
        
        prevVideoButton?.titleLabel?.font = UIFont.fontAwesome(ofSize: 30, style: .solid)
        prevVideoButton?.setTitle(String.fontAwesomeIcon(name: .stepBackward), for: .normal)
        
        skipVideoButton?.titleLabel?.font = UIFont.fontAwesome(ofSize: 30, style: .solid)
        skipVideoButton?.setTitle(String.fontAwesomeIcon(name: .stepForward), for: .normal)
        
        exitFullScreenButton?.titleLabel?.font = UIFont.fontAwesome(ofSize: 30, style: .solid)
        exitFullScreenButton?.setTitle(String.fontAwesomeIcon(name: .chevronLeft), for: .normal)
        
        // enable audio even if silent mode
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        } catch {
            print(error)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if videos != nil{
            self.showVideoControls()
            loadFullScreenVideo()
        }
    }
    
    // hide iphone x home indicator
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    func loadFullScreenVideo(slideDirection: String = "") {
        guard let videoPost: VideoPost = videos?[videoIndex],
            let thumbnailUrl = URL(string: videoPost.thumbnailUrlRaw),
            let mp4Url = URL(string: videoPost.mp4UrlRaw) else {
                return
        }
        
        // set alpha to 0 for video on load
        self.playerView?.alpha = 0
        
        // show activity indicator and video controls view
        self.activityIndicator?.isHidden = false
        self.activityIndicator?.startAnimating()
        self.showVideoControls()
        
        // load play button (placing logic here ensures a new video will always present with the pause button, UNLESS shouldPlay is false)
        playButton?.titleLabel?.font = UIFont.fontAwesome(ofSize: 30, style: .solid)
        if shouldPlay {
            playButton?.setTitle(String.fontAwesomeIcon(name: .pause), for: .normal)
        } else {
            playButton?.setTitle(String.fontAwesomeIcon(name: .play), for: .normal)
        }
        
        // reset video scrubber to 0
        self.videoScrubberSlider?.setValue(0, animated: false)
        self.videoTimeLabel?.text = "0:00"
        
        // make video controls visible briefly
        self.showVideoControls()
        
        // set title label
        self.titleLabel?.text = videoPost.title
        
        // set thumbnail image and playerview to nil
        self.thumbnailView?.image = nil
        self.playerView?.playerLayer.player?.replaceCurrentItem(with: nil)
        
        // load thumbnail image and animate thumbnail in direction of swipe
        self.thumbnailView?.sd_setImage(with: thumbnailUrl, placeholderImage: nil, completed: { (image, error, cacheType, url) -> Void in
            DispatchQueue.main.async { [weak self] in
                self?.thumbnailView?.slideIn(fromDirection: slideDirection)
            }
        })
        
        // load new player
        self.videoAsset = AVAsset(url: mp4Url)
        let playableKey = "playable"
        
        // don't proceed if videoAsset not valid
        guard let videoAsset = self.videoAsset else { return }
        
        // load url in background thread
        videoAsset.loadValuesAsynchronously(forKeys: [playableKey]) {
            var error: NSError? = nil
            let status = self.videoAsset?.statusOfValue(forKey: playableKey, error: &error)
            switch status {
            case .loaded?:
                
                let league = self.league ?? "[today view]"

                // configure video scrubber to update with video playback (labels for UISlider have to be updated on main thread
                DispatchQueue.main.async {
                    Analytics.logEvent("videoLoaded", parameters: [
                        AnalyticsParameterItemID: videoPost.id,
                        AnalyticsParameterItemName: videoPost.title,
                        AnalyticsParameterItemCategory: league,
                        AnalyticsParameterContent: "fullScreen"
                        ])
                    
                    // Sucessfully loaded. Continue processing.
                    let item = AVPlayerItem(asset: videoAsset)
                    self.playerView?.playerLayer.player?.replaceCurrentItem(with: item)
                    
                    // KVO for removing thumbnail and playing video (?)
                    self.playerView?.playerLayer.player?.currentItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
                    
                    // set video scrubber
                    let videoDurationFloat = Float(CMTimeGetSeconds(self.playerView?.player?.currentItem?.asset.duration ?? CMTimeMake(value: 0, timescale: 1)))
                    self.videoScrubberSlider?.maximumValue = videoDurationFloat
                    self.videoDurationLabel?.text = self.convertSecondsToTimeString(secondsTotal: Int(videoDurationFloat))        // updates label for full duration of video

                    // updates player scrubber slider as video plays
                    self.playerView?.playerLayer.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main) { (CMTime) -> Void in
                        if self.playerView?.playerLayer.player?.currentItem?.status == .readyToPlay {
                            let time: Float64 = CMTimeGetSeconds((self.playerView?.playerLayer.player?.currentTime() ?? CMTimeMake(value: 0, timescale: 1)))
                            self.videoScrubberSlider?.value = Float(time)

                            // also update labels in video by slider
                            let seconds = Int(time)
                            self.videoTimeLabel?.text = self.convertSecondsToTimeString(secondsTotal: seconds)
                        }
                    }
                }
                break
            case .failed?:
                // Handle error
                print("URL LOAD FAILED!")
            case .cancelled?:
                // Terminate processing
                print("URL LOAD CANCELLED!")
            default:
                // Handle all other cases
                print("DEFAULT HAPPENED?")
            }
        }
        

        // KVO to skip to next video
        self.skipObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.playerView?.playerLayer.player?.currentItem, queue: .main) { _ in

            // skip to next video and remove observer
            self.skipVideo()
            
            Analytics.logEvent("fullScreenVideoChange", parameters: [
                AnalyticsParameterItemName: "skip",
                AnalyticsParameterContentType: "auto"
                ])
        }
    }
    
    // THIS NEW OBSERVER WILL READ STATUS AND SHOW AVPLAYER
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let item: AVPlayerItem = object as? AVPlayerItem {
            if keyPath == "status" {
                let status = item.status
                if status == AVPlayerItem.Status.readyToPlay {
                    self.activityIndicator?.stopAnimating()
                    self.playerView?.fadeIn()
                    if shouldPlay {
                        self.playerView?.playerLayer.player?.play()
                    }
                }
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
    
    // fades objects in and out (used for video controls)
    func fadeViewInThenOut(view: UIView) {
        let animationDuration = 0.25
        
        // Fade in the view
        UIView.animate(withDuration: animationDuration, delay: 0.0, options:.allowUserInteraction, animations: { () -> Void in
            view.alpha = 1
        }) { (Bool) -> Void in
            // After the animation completes, fade out the view after a delay
            let delay = TimeInterval(exactly: 5) ?? 0
            
            UIView.animate(withDuration: animationDuration, delay: delay, options: [.curveEaseOut, .allowUserInteraction], animations: { () -> Void in
                view.alpha = 0
            }, completion: nil)
        }
    }
    
    // navigation
    func skipVideo() {
        guard let videosCount = self.videos?.count else {
            return
        }
        
        if videoIndex < videosCount - 1 {
            // remove skip observer of current video--THIS FIXES THE BUG THAT CAUSED MANY VIDEOS TO SKIP AT ONCE
            if let skipObserver = self.skipObserver {
                NotificationCenter.default.removeObserver(skipObserver)
            }
            
            self.videoIndex += 1
            self.loadFullScreenVideo(slideDirection: "left")
        }
    }
    
    func prevVideo() {
        if videoIndex > 0 {
            self.videoIndex -= 1
            self.loadFullScreenVideo(slideDirection: "right")
        }
    }
    
    // converts integer of seconds into string representing time (mm:ss)
    func convertSecondsToTimeString(secondsTotal: Int) -> String {
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
    
    func dismissViewController() {
        // remove videoviewcontroller
        self.navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)

        // remove player and thumbnail from memory
        if let player = self.playerView?.playerLayer.player {
            player.replaceCurrentItem(with: nil)
            self.thumbnailView?.image = nil
            self.videoAsset = nil
        }
        
        // remove skip observer of current video--THIS FIXES THE BUG THE VIDEO TO SUDDENLY PLAY IN BACKGROUND
        if let skipObserver = self.skipObserver {
            NotificationCenter.default.removeObserver(skipObserver)
        }
        
        if let navController = self.navigationController {
            navController.isNavigationBarHidden = false     // show nav bar
        }
    }
    
    // skip IBActions
    @IBAction func skipSwipeRecognizer(_ sender: Any) {
        self.skipVideo()
        
        Analytics.logEvent("fullScreenVideoChange", parameters: [
            AnalyticsParameterItemName: "skip",
            AnalyticsParameterContentType: "swipe"
            ])
    }
    @IBAction func skipButtonSelect(_ sender: Any) {
        self.skipVideo()
        
        Analytics.logEvent("fullScreenVideoChange", parameters: [
            AnalyticsParameterItemName: "skip",
            AnalyticsParameterContentType: "press"
            ])
    }
    
    // prev IBActions
    @IBAction func prevSwipeRecognizer(_ sender: Any) {
        self.prevVideo()
        
        Analytics.logEvent("fullScreenVideoChange", parameters: [
            AnalyticsParameterItemName: "prev",
            AnalyticsParameterContentType: "swipe"
            ])
    }
    @IBAction func prevButtonSelect(_ sender: Any) {
        self.prevVideo()
        
        Analytics.logEvent("fullScreenVideoChange", parameters: [
            AnalyticsParameterItemName: "skip",
            AnalyticsParameterContentType: "press"
            ])
    }
    
    // IBActions to exit view
    @IBAction func exitButtonPress(_ sender: Any) {
        dismissViewController()
        
        Analytics.logEvent("fullScreenModeExit", parameters: [
            AnalyticsParameterContentType: "press"
            ])
    }
    @IBAction func swipeDownToExit(_ sender: Any) {
        dismissViewController()
        
        Analytics.logEvent("fullScreenModeExit", parameters: [
            AnalyticsParameterContentType: "swipeDown"
            ])
    }
    
//  DISABLING DUE TO LIKELIHOOD OF MISSED SWIPE TO SKIP VIDEO
//    @IBAction func swipeEdgeScreenToExit(_ sender: Any) {
//        dismissViewController()
//
//        Analytics.logEvent("fullScreenModeExit", parameters: [
//            AnalyticsParameterContentType: "swipeEdge"
//            ])
//    }
    
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
    
    // sets actions for play button
    @IBAction func playButtonSelect(_ sender: Any) {
        if let player = self.playerView?.player {
            if player.rate > Float(0) {
                player.pause()
                playButton?.setTitle(String.fontAwesomeIcon(name: .play), for: .normal)
                
                // keep video controls visible on pause
                self.videoControlsView?.isHidden = false
            } else {
                player.play()
                playButton?.setTitle(String.fontAwesomeIcon(name: .pause), for: .normal)
                self.shouldPlay = true      // toggle back shouldPlay so videos always play (used for when videos are opened from a share so that the video doesn't start with blasting audio)
            }
        }
    }
    
    // updates playback time if scrubber changed by user
    @IBAction func videoScrubberValueChanged(_ sender: Any) {
        let seconds: Int64 = Int64(self.videoScrubberSlider?.value ?? 0)
        let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
        
        if let player = self.playerView?.player {
            player.seek(to: targetTime)
        }
    }
    
    // keeps video paused during drag
    @IBAction func scrubberTouchDragEnter(_ sender: Any) {
        self.playerView?.playerLayer.player?.pause()
    }

    // keeps video controls visible during drag (and keeps video paused)
    @IBAction func scrubberTouchDragInside(_ sender: Any) {
        self.playerView?.player?.pause()
        playButton?.setTitle(String.fontAwesomeIcon(name: .play), for: .normal)
        self.videoControlsView?.isHidden = false
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // special init when user opens video from link
    func initFromLink(videoId: String) {        
        // make status bar background black
        if let statusBarView = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView {
            statusBarView.backgroundColor = UIColor.black
        }
        
        // load other videos for identified league and identify the video we want to play in the full lsit
//        let videoPosts = DataProvider.shared.getVideoPosts(league: nil, completion: { [weak self] in
//            // create 1d array of videos
//            var videoPostsNoDate: [VideoPost] = []
//            for videosForDate in DataProvider.videoPosts {
//                let videoPosts = videosForDate.1
//                videoPostsNoDate.append(contentsOf: videoPosts)
//            }
//
//            // remove instance of video we want to play from the array so a dupe isn't played
//            var indexToRemove: Int?
//            var videoPost: VideoPost?
//            for (index, v) in videoPostsNoDate.enumerated() {
//                if v.id == videoId {
//                    indexToRemove = index
//                    videoPost = v
//                }
//            }
//
//            // if we have a valid index, play the video, else we display an error that no video was found
//            if let indexToRemove = indexToRemove, let videoPost = videoPost {
//                // remove video want to play from array and pop it to top
//                videoPostsNoDate.remove(at: indexToRemove)
//                videoPostsNoDate.insert(videoPost, at: 0)
//
//                // analytics
//                Analytics.logEvent(AnalyticsEventShare, parameters: [AnalyticsParameterItemID: videoId, AnalyticsParameterContentType: "incoming_link"])
//
//                // send index and videos array to destination VC
//                self?.videoIndex = 0
//                self?.videos = videoPostsNoDate
//
//                // set videoVC by default to play (used for when videos are opened from a share so that the video doesn't start with blasting audio if set to false)
//                self?.shouldPlay = true
//                self?.showVideoControls()
//                self?.loadFullScreenVideo()
//            }
//        })
    }

}
