//
//  FeedViewController.swift
//  TheLobApp
//
//  Created by Elliot Boschwitz on 5/1/18.
//  Copyright © 2018 Elliot Boschwitz. All rights reserved.
//

import AVKit
import CoreMedia
import FirebaseAnalytics
import SDWebImage
import UIKit


class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITabBarControllerDelegate, LinkTableViewCellDelegate {
    
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var headerDateLabel: UILabel?
    @IBOutlet weak var errorView: UIView?
    
    private var videoPosts: [(Date, [VideoPost])] = []
    var league: String?
    private var notification: NSObjectProtocol?
    var videoAsset: AVAsset?
    
    // keeps track of global mute control (if users disables mute)
    private var isMute: Bool = true
    
    // keeps track of currently playing video
    private var indexPathForPlayingVideo: IndexPath?
    
    // keeps track of the indexpaths of visible rows
    private var visibleRows: [IndexPath] = [IndexPath]()
    private var allRows: [LinkTableViewCell] = [LinkTableViewCell]()
    
    // keeps track of observer used to see when video ends
    private var videoEndsObserver: NSObjectProtocol?
    
    // kep status bar visible
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView?.dataSource = self
        self.tableView?.delegate = self

        // set title: nil case means we're in hot posts view
        if let league = self.league {
            switch league {
            case "nba":
                self.title = "NBA"
            case "soccer":
                self.title = "Soccer - All Leagues"
            case "baseball":
                self.title = "Baseball - All Leagues"
            case "nfl":
                self.title = "NFL"
            default:
                break
            }
        } else {
            // if we're in hot posts view: set date header
            // date for header
            let now = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "LLLL d"
            let dateString = dateFormatter.string(from: now)
            self.headerDateLabel?.text = dateString.uppercased()
        }
        
        // analytics
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: [AnalyticsParameterItemCategory: self.title ?? ""])
        
        // let background music still play
//        _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, with: .mixWithOthers)
        
        // enables audio even if device is in silent mode
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        
        // configure refresh control
        let refreshControl = UIRefreshControl()
        self.tableView?.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(self.handleRefresh(_:)), for: .valueChanged)
        
        // load videos by specified view
        initLoadVideoPosts()
        
        // add KVO for visiblecells in table
        self.tableView?.addObserver(self, forKeyPath: "visibleCells", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
    }
    
    // hide iphone x home indicator in fullscreen mode
    func prefersHomeIndicatorAutoHidden() -> Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // show status bar and makes it dark (although function below is deprecated, nothing else is working...)
//        UIApplication.shared.statusBarStyle = .default
    
        
        // if we're in hot posts view: make status bar solid white
        guard let statusBarView = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else {
            return
        }
        if self.league == nil {
            statusBarView.backgroundColor = UIColor.white
        } else {
            statusBarView.backgroundColor = nil
        }
    
        // start animating loading spinner
        self.activityIndicator?.startAnimating()
        
        // reload data
        self.tableView?.reloadData()
        self.initLoadVideoPosts()
    }
    
    // null table if view disappears
    override func viewWillDisappear(_ animated: Bool) {
        self.videoAsset = nil
        
        // remove all thumbnails and videos from memory
        for cell in allRows {
            if cell.playerView != nil {
                // video and pic will get recycled or take up space, so get rid of them
                cell.playerView?.player?.replaceCurrentItem(with: nil)
            }
            cell.thumbnailView?.image = nil
        }
        
        self.visibleRows.removeAll()
        self.videoPosts.removeAll()
        self.tableView?.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*****************************************
     TABLEVIEW FUNCTIONS
     *****************************************/
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.videoPosts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.videoPosts[section].1.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "LinkTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? LinkTableViewCell else {
            fatalError("The dequeued cell is not an instance of LinkTableViewCell")
        }
        
        cell.delegate = self
        
        let section = indexPath.section
        
        if !self.videoPosts.isEmpty {
            let videoPost = self.videoPosts[section].1[indexPath.row]
            cell.videoPost = videoPost
            
            // set cell attributes
//            if let thumbnailUrl = videoPost.thumbnailUrl {
//                cell.thumbnailView?.load(url: thumbnailUrl)
//            }
            cell.thumbnailView?.sd_setImage(with: videoPost.thumbnailUrl, placeholderImage: nil)
//            cell.loadVideoForCell()
            cell.label?.text = videoPost.title
            
            // set label for time delta
            cell.timeLabel?.text = videoPost.datePosted.timeAgoDisplay()
            
            // sets dimensions for each cell
            setDimensionsForTableView(cell: cell)
            
            // if NOT hot posts view, show section header for cell; else set league label
            if self.league != nil {
                self.tableView?.headerView(forSection: indexPath.section)?.isHidden = false
            } else {
                // label text and icon
                var leagueLabel = ""
                if videoPost.league == "nba" {
                    leagueLabel = "NBA"
                    cell.leagueLabelIcon?.image = UIImage(named: "basketball")?.withRenderingMode(.alwaysTemplate)
                } else if videoPost.league == "nfl" {
                    leagueLabel = "NFL"
                    cell.leagueLabelIcon?.image = UIImage(named: "footballAmerican")?.withRenderingMode(.alwaysTemplate)
                } else if videoPost.league == "baseball" {
                    leagueLabel = "MLB"
                }
                cell.leagueLabel?.text = leagueLabel
            }
            
            // set author button
            cell.authorButton?.setTitle(videoPost.author, for: .normal)
            
            // allows icon for clock to have a dark gray tint (rather than default black
            cell.timeLabelIcon?.image = UIImage(named: "clock")?.withRenderingMode(.alwaysTemplate)
            
            // show mute button and update volume toggle
            cell.muteToggleButton?.isHidden = false
            self.updateMuteControls(cell: cell)
        }
        if let playerView = cell.playerView {
            playerView.playerLayer.frame = playerView.bounds
        }
        
        // we hold a global array of all created cells to release the thumbnail images from memory, since there were leaks
        if !allRows.contains(cell) {
            allRows.append(cell)
        }
        
        return cell
    }
        
    // give the table a section header only if we're NOT viewing hot posts
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.league == nil {
            return nil
        } else {
            // sets header indent
            let headerInset: CGFloat = 15
            tableView.separatorInset = UIEdgeInsets.init(top: 0, left: headerInset, bottom: 0, right: 0)
            
            let date = self.videoPosts[section].0
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "MMMM d, YYYY"
            return dateFormatter.string(from: date)
        }
    }
    
    // if cell disappears, remove player from memory--APPEARS UNNECESSARY SINCE LATEST FIXES
//    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        if let cell: LinkTableViewCell = cell as? LinkTableViewCell {
//            if let playerView = cell.playerView {
//                // video and pic will get recycled or take up space, so get rid of them
//                playerView.player?.replaceCurrentItem(with: nil)
//                cell.thumbnailView?.image = nil
//            }
//        }
//    }
    
    // necessary for loading videos in full screen
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // sets table cell indent to 0
        cell.separatorInset = UIEdgeInsets.zero
    }
    
    // set video to fullscreen on tap, unmute video, and pause all other playing videos
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.indexPathForPlayingVideo = indexPath
        
        // programmatically call segue to show video detail
        self.performSegue(withIdentifier: "videoDetailSegue", sender: self)
    }

    /*****************************************
     AUTOPLAY LOGIC
     *****************************************/
    
    // play middle(ish) video AFTER scroll drag has ended, but ONLY if user hasn't done a big swipe
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.autoplayVideoInTable()
        }
    }
    
    // load video if deceleration ended
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.autoplayVideoInTable()
    }
    
    func autoplayVideoInTable() {
        // see if full screen mode is disabled and new cells have loaded, if yes, toggle autoplay
        guard let tableView = self.tableView else { return }
        let visibleCells = tableView.visibleCells
        
        if !visibleCells.isEmpty {
            var visibleCellIndexes = [IndexPath]()
            
            // get list of visible indexes
            for cell in visibleCells {
                if let indexPath = tableView.indexPath(for: cell) {
                    visibleCellIndexes.append(indexPath)
                }
            }
            
            // calculate height of header above first cell
            var headerHeight: CGFloat = 64
            // add height of iphone x inset (if there is any)
            if #available(iOS 11.0, *) {
                headerHeight = view.safeAreaInsets.top
            }
            
            // plays top most video that isn't above the header height
            for ptrIndex in visibleCellIndexes {
                let rectOfCellInTableView = tableView.rectForRow(at: ptrIndex)
                let rectOfCellInSuperview = tableView.convert(rectOfCellInTableView, to: self.tableView?.superview)
                
                // play video if it's not hidden at the top, OR if it's the last video
                if rectOfCellInSuperview.origin.y > headerHeight || ptrIndex == visibleCellIndexes.last {
//                    loadVideoForCell(indexPath: ptrIndex)
                    if let cell = self.tableView?.cellForRow(at: ptrIndex) as? LinkTableViewCell{
                        cell.loadVideoForCell()
                        pauseAllVideosExcept(indexPath: ptrIndex)
                    }
                    break
                }
            }
        }
    }

    // ensures all other videos are paused except the specified index path
    func pauseAllVideosExcept(indexPath: IndexPath) {
        guard let visibleCells = (self.tableView?.visibleCells as? [LinkTableViewCell]) else { return }
        
        for cellptr in visibleCells {
            let indexPathPtr = self.tableView?.indexPath(for: cellptr)
            
            if indexPath != indexPathPtr {
                cellptr.playerView?.player?.pause()
            }
        }
    }
    
    // loads AVPlayer in cell
    func loadVideoForCell(indexPath: IndexPath, startTime: CMTime? = nil) {
//        // pause other videos
//        pauseAllVideosExcept(indexPath: indexPath)
//
//        // remove observer
//        if let observer = self.videoEndsObserver {
//            NotificationCenter.default.removeObserver(observer)
//        }
//
//        if let cell: LinkTableViewCell = self.tableView?.cellForRow(at: indexPath) as? LinkTableViewCell {
//            // play video if it's already loaded, else load it
//            if cell.playerView?.playerLayer.player?.currentItem != nil {
//                cell.playerView?.playerLayer.player?.playImmediately(atRate: Float(1))
//            } else {
//                // keep track of playing video
//                self.indexPathForPlayingVideo = indexPath
//
//                // start loading spinner
//                cell.activityIndicator?.startAnimating()
//
//                guard let videoPost = cell.videoPost, let mp4Url = videoPost.mp4Url else { return }
//
//                // lazily instantiate asset before async call
//                self.videoAsset = AVAsset(url: mp4Url)
//                let playableKey = "playable"
//                let player = AVPlayer(playerItem: nil)
//                cell.playerView?.playerLayer.player = player
//
//                // load url in background thread
//                if let videoAsset = self.videoAsset {
//                    videoAsset.loadValuesAsynchronously(forKeys: [playableKey]) { [weak self] in
//                        var error: NSError? = nil
//
//                        let status = videoAsset.statusOfValue(forKey: playableKey, error: &error)
//                        switch status {
//                        case .loaded:
//                            // configure video scrubber to update with video playback (labels for UISlider have to be updated on main thread
//                            DispatchQueue.main.async { [weak self ] in
//                                // analytics
//                                let league_page = self?.league ?? "[today view]"
//
//                                // find 1D index for the now-playing video (use this for analytics to see how far down the table people watch videos)
//                                var indexCount: Int = 0
//                                if let tableView = self?.tableView,
//                                    let lastIndex = self?.indexPathForPlayingVideo,
//                                    lastIndex.section > 0 {
//                                    for i in stride(from: 0, to: lastIndex.section, by: 1) {
//                                        indexCount += tableView.numberOfRows(inSection: i)
//                                    }
//                                    indexCount += lastIndex.row + 1
//                                }
//
//                                Analytics.logEvent("videoLoaded", parameters: [
//                                    AnalyticsParameterItemID: videoPost.id,
//                                    AnalyticsParameterItemName: videoPost.title,
//                                    AnalyticsParameterItemCategory: league_page,
//                                    AnalyticsParameterContent: "table",
//                                    AnalyticsParameterIndex: indexCount
//                                    ])
//
//                                // Sucessfully loaded. Continue processing.
//                                if let videoAsset = self?.videoAsset {
//                                    let item = AVPlayerItem(asset: videoAsset)
//                                    cell.playerView?.playerLayer.player?.replaceCurrentItem(with: item)
//
//                                    // fast-forward start time, if specified
//                                    cell.playerView?.player?.seek(to: startTime ?? CMTimeMake(value: 0, timescale: 1))
//
//                                    // play and set to mute/unmute
//                                    cell.playerView?.player?.play()
//                                    self?.updateMuteControls(cell: cell)
//                                }
//                            }
//                            break
//                        case .failed:
//                            // Handle error
//                            print("URL LOAD FAILED!")
//                        case .cancelled:
//                            // Terminate processing
//                            print("URL LOAD CANCELLED!")
//                        default:
//                            // Handle all other cases
//                            print("DEFAULT HAPPENED?")
//                        }
//                    }
//                }
//
//                // track perf for time it takes to load video
//                //        cell.videoPerfTrace = Performance.startTrace(name: "Video Load in TableView")
//
//                // hacky KVO solution to stop loading spinner, hide thumbnail image
//                NotificationCenter.default.addObserver(forName: Notification.Name.AVPlayerItemTimeJumped, object: player.currentItem, queue: .main) { _ in
//                    cell.activityIndicator?.stopAnimating()
//                    cell.playerView?.fadeIn()
//                }
//
//                // video plays faster but this might cause buffering...
//                cell.playerView?.player?.automaticallyWaitsToMinimizeStalling = false
//
//                // KVO to find videos that failed to load (and attempt to reload
//                cell.playerView?.player?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
//
//                // KVO to keep video in loop
//                self.videoEndsObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
//                    // replay video
//                    player.seek(to: CMTime.zero)
//                    player.play()
//                }
//            }
//            // set mute as specified by user
//            updateMuteControls(cell: cell)
//
//            // keep tracking of playing video
//            self.indexPathForPlayingVideo = indexPath
//        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let player: AVPlayer = object as? AVPlayer {
            if keyPath == "status" {
                let status = player.currentItem?.status
                if status == AVPlayerItem.Status.failed {
                    Analytics.logEvent("videoLoadFail", parameters: nil)
                    
                }
            }

        }
    }
    
    /*****************************************
     SETTING CELL DIMENSIONS
     *****************************************/
    
    // sets dimensions for elements in cell for table view
    func setDimensionsForTableView(cell: LinkTableViewCell) {
        // sets dimensions for AVPlayerLayer
        if let videoPost = cell.videoPost {
            let aspectRatio = CGFloat(videoPost.height) / CGFloat(videoPost.width)
    
            // set width of video based on device orientation
            var width = CGFloat(UIScreen.main.bounds.size.width)
            if UIDevice.current.orientation.isLandscape {
                width = CGFloat(UIScreen.main.bounds.size.height)
            }
            var height = aspectRatio * width
            // resize video of height is too high
            if (height > 400) {
                width = 400 / aspectRatio
                height = 400
            }
            cell.playerViewHeight?.constant = height
            cell.playerViewWidth?.constant = width
        }


        // show labels
        cell.label?.isHidden = false
        cell.timeLabel?.isHidden = false

        // set background to white
        cell.backgroundColor = .white
    }
    
    
    func updateMuteControls(cell: LinkTableViewCell) {
        if self.isMute {
            cell.muteToggleButton?.titleLabel?.font = UIFont.fontAwesome(ofSize: 30, style: .solid)
            cell.muteToggleButton?.setTitle(String.fontAwesomeIcon(name: .volumeOff), for: .normal)
        } else {
            cell.muteToggleButton?.titleLabel?.font = UIFont.fontAwesome(ofSize: 30, style: .solid)
            cell.muteToggleButton?.setTitle(String.fontAwesomeIcon(name: .volumeUp), for: .normal)
        }
        
        // this actually mutes or unmutes the video
        cell.playerView?.player?.isMuted = self.isMute
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
    
    /*****************************************
     VIDEOPOSTS LOADING
     *****************************************/
    
    // loads video posts and scrolls to current day. if no sport is selected, the user is viewing "hot" posts.
    private func initLoadVideoPosts() {
        DataProvider.getVideoPosts(league: self.league, completion: { [weak self] in
            self?.videoPosts = DataProvider.videoPosts
            self?.tableView?.reloadData()     // necessary to load data in table view
            
            // show error view if there are no posts
            if DataProvider.videoPosts.isEmpty {
                self?.errorView?.isHidden = false
            }
            
            // play first video if indexPathForPlayingVideo is null
            let firstIndexPath = IndexPath(row: 0, section:0)
            let indexPathToPlay = self?.indexPathForPlayingVideo ?? firstIndexPath
            
            // scroll to tableView to video cell if it exists and isn't the first row (which would hide the header if so)
            if self?.tableView?.cellForRow(at: indexPathToPlay) != nil && indexPathToPlay != firstIndexPath{
                self?.tableView?.scrollToRow(at: indexPathToPlay, at: .top, animated: false)
            }
            self?.loadVideoForCell(indexPath: indexPathToPlay)
            
            // hide loading indicator
            self?.activityIndicator?.stopAnimating()
        })
    }

    
    /********************************
     REFRESH FUNCTIONALITY
     *********************************/
    
    @objc func handleRefresh(_ sender: Any) {
        // remove table before refresh sequence begins (makes the experience feel nicer since everything gets reloaded anyways
        self.videoPosts.removeAll()
        self.tableView?.reloadData()
        
        // set index path of last playing video to first so that we don't scroll back on refresh
        indexPathForPlayingVideo = IndexPath(row: 0, section:0)
    
        initLoadVideoPosts()
        self.tableView?.refreshControl?.endRefreshing()
        
        // log analytics
        Analytics.logEvent("refreshEvent", parameters: nil)
    }
    
    /********************************
     NAVIGATION
     *********************************/
    
    // toggles mute on current video and changes icons
    @IBAction func muteToggleSelect(_ sender: Any) {
        if self.isMute {
            self.isMute = false
        } else {
            self.isMute = true
        }
        
        // update cells that have already loaded
        if let visibleCells = (self.tableView?.visibleCells as? [LinkTableViewCell]) {
            for cell in visibleCells {
                self.updateMuteControls(cell: cell)
            }
        }
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier == "videoDetailSegue" {
            if let videoVC = segue.destination as? VideoViewController {
                if self.indexPathForPlayingVideo != nil {
                    // send array of videoposts and current index to segue vc
                    var videoPostsNoDate: [VideoPost] = [VideoPost]()

                    for videosForDate in self.videoPosts {
                        let videoPosts = videosForDate.1
                        videoPostsNoDate.append(contentsOf: videoPosts)
                    }
                    videoVC.videos = videoPostsNoDate

                    // send index of currently viewed video (index = row + rowsInSection(section-1)
                    if let videoIndex = self.indexPathForPlayingVideo, let tableView = self.tableView {
                        videoVC.videoIndex = videoIndex.row
                        var sectionPtr = 0
                        while sectionPtr < videoIndex.section {
                            videoVC.videoIndex += tableView.numberOfRows(inSection: sectionPtr)
                            sectionPtr += 1
                        }
                    }
                    videoVC.league = self.league
                }
            }
        }
    }
    
    /********************************
     SHARE BUTTON
     *********************************/
    // user selects share button (taken from https://stackoverflow.com/questions/35931946/basic-example-for-sharing-text-or-image-with-uiactivityviewcontroller-in-swift)
    func shareVideo(videoPost: VideoPost) {
        // analytics
        let league = self.league ?? "[today view]"

        Analytics.logEvent(AnalyticsEventShare, parameters: [
                            AnalyticsParameterItemCategory: league,
                            AnalyticsParameterItemID: videoPost.id,
                            AnalyticsParameterContentType: "outgoing_link"])
        
        // construct url to lob.tv
        let videoUrl = URL(string: "https://lob.tv/video/\(videoPost.id)/")
        
        // set up activity view controller
        let linkToShare = [videoUrl]
        let activityViewController = UIActivityViewController(activityItems: linkToShare as [Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
//        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
}

// this extension helps us get the time back from the video post (source: https://stackoverflow.com/questions/44086555/swift-display-time-ago-from-date-nsdate)
extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        
        guard let minuteAgo = calendar.date(byAdding: .minute, value: -1, to: Date()),
            let hourAgo = calendar.date(byAdding: .hour, value: -1, to: Date()),
            let dayAgo = calendar.date(byAdding: .day, value: -1, to: Date()),
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()),
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: Date()) else { return "" }
        
        if minuteAgo < self {
            let diff = Calendar.current.dateComponents([.second], from: self, to: Date()).second ?? 0
            return "\(diff)s"
        } else if hourAgo < self {
            let diff = Calendar.current.dateComponents([.minute], from: self, to: Date()).minute ?? 0
            return "\(diff)m"
        } else if dayAgo < self {
            let diff = Calendar.current.dateComponents([.hour], from: self, to: Date()).hour ?? 0
            return "\(diff)h"
        } else if monthAgo < self {
            let diff = Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
            return "\(diff)d"
        } else if yearAgo < self {
            let diff = Calendar.current.dateComponents([.month], from: self, to: Date()).month ?? 0
            return "\(diff)m"
        }
        let diff = Calendar.current.dateComponents([.year], from: self, to: Date()).year ?? 0
        return "\(diff)y"
    }
}
