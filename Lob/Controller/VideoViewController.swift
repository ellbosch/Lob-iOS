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
    var videos: [VideoPost] = []
    var videoIndex: Int = 0
    var shouldPlay: Bool = true
    var openedFromShare: Bool = false
    var videoDidEndPlayingObserver: NSObjectProtocol?

    
    var myView: FullScreenView? {
        get { return view as? FullScreenView }
        set {
            newValue?.setupView()
            view = newValue
        }
    }
    
//    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
//        super.init(nibName: nibNameOrNil, bundle: nil)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//    }
//
//    convenience init(videos: [VideoPost], videoIndexToStart: Int, shouldPlay: Bool = true, openedFromShare: Bool = false) {
//        self.init(nibName: nil, bundle: nil)
//
//        // from params
//        self.videos = videos
//        self.videoIndex = videoIndexToStart
//        self.shouldPlay = shouldPlay
//        self.openedFromShare = openedFromShare
//
//        // other params
////        self.isVideoControlsVisible = false
//    }
//    
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
        
        // set delegate of full screen view to this VC
        myView?.delegate = self
        myView?.playerView?.delegatePlayerView = myView
        myView?.playerView?.delegateControlView = myView?.videoControlsView
        
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
        loadFullScreenVideo()
    }
    
    // hide iphone x home indicator
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    func loadFullScreenVideo(slideDirection: String = "") {
        if videoIndex >= videos.count {
            return
        }
        let videoPost: VideoPost = videos[videoIndex]
        let playerView = self.myView?.playerView
        
        guard let thumbnailUrl = URL(string: videoPost.thumbnailUrlRaw) else {
            return
        }
        
        // set alpha to 0 for video on load
        playerView?.alpha = 0
        
        // show activity indicator and video controls view
        self.myView?.activityIndicator?.isHidden = false
        self.myView?.activityIndicator?.startAnimating()
        self.myView?.showVideoControls()
        
        // set videopost to view
        self.myView?.videoPost = videoPost
        
        // load thumbnail image and animate thumbnail in direction of swipe
        self.myView?.thumbnailView?.sd_setImage(with: thumbnailUrl, placeholderImage: nil, completed: { (image, error, cacheType, url) -> Void in
            DispatchQueue.main.async { [weak self] in
                self?.myView?.thumbnailView?.slideIn(fromDirection: slideDirection)
            }
        })
        
        // load url in background thread
        playerView?.setPlayerItem(from: URL(string: videoPost.mp4UrlRaw),
          success: { [weak self] playerItem in
                DispatchQueue.main.async { [weak self] in
                    self?.replaceVideoDidEndPlayingObserver(playerItem: playerItem)
                }
            }
        )
        
        // analytics
        let league = videoPost.getSport()?.name ?? "[today view]"
        Analytics.logEvent("videoLoaded", parameters: [
            AnalyticsParameterItemID: videoPost.id,
            AnalyticsParameterItemName: videoPost.title,
            AnalyticsParameterItemCategory: league,
            AnalyticsParameterContent: "fullScreen"
        ])
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
    
    func replaceVideoDidEndPlayingObserver(playerItem: AVPlayerItem) {
        // setup video did end playing observer and remove last made one
        if let videoDidEndPlayingObserver = self.videoDidEndPlayingObserver {
            NotificationCenter.default.removeObserver(videoDidEndPlayingObserver)
        }
        
        self.videoDidEndPlayingObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { [weak self] _ in
            
            // skip to next video and remove observer
            self?.willLoadNextVideo()
        }
    }
    
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

extension VideoViewController: FullScreenViewDelegate {
    func willLoadNextVideo() {
        if videoIndex < videos.count - 1 {
            // remove skip observer of current video--THIS FIXES THE BUG THAT CAUSED MANY VIDEOS TO SKIP AT ONCE
            
            self.videoIndex += 1
            self.loadFullScreenVideo(slideDirection: "left")
        }
    }
    
    func willLoadPrevVideo() {
        if videoIndex > 0 {
            self.videoIndex -= 1
            self.loadFullScreenVideo(slideDirection: "right")
        }
    }
    
    func willExitFullScreenMode() {
        // remove videoviewcontroller
        self.navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
        
        // remove player and thumbnail from memory
        if let player = self.myView?.playerView?.playerLayer.player {
            player.replaceCurrentItem(with: nil)
            self.myView?.thumbnailView?.image = nil
        }
        
        // remove skip observer of current video--THIS FIXES THE BUG THE VIDEO TO SUDDENLY PLAY IN BACKGROUND
        if let videoDidEndPlayingObserver = self.videoDidEndPlayingObserver {
            NotificationCenter.default.removeObserver(videoDidEndPlayingObserver)
        }
        
        if let navController = self.navigationController {
            navController.isNavigationBarHidden = false     // show nav bar
        }
    }
    
}
