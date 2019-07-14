//
//  FeedViewController.swift
//  TheLobApp
//
//  Created by Elliot Boschwitz on 5/1/18.
//  Copyright © 2018 Elliot Boschwitz. All rights reserved.
//

import AVKit
import FirebaseAnalytics
import SDWebImage
import UIKit


class FeedViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var headerDateLabel: UILabel?
    @IBOutlet weak var errorView: UIView?
    
    var sport: Sport?
    var videoPosts: [(Date, [VideoPost])] = []
    
    private var notification: NSObjectProtocol?
    
    // keeps track of global mute control (if users disables mute)
    var isMute: Bool = true
    
    // keeps track of currently playing video
    var indexPathForPlayingVideo: IndexPath?
    
    // keeps track of the indexpaths of visible rows
    var visibleRows: [IndexPath] = [IndexPath]()
    var allRows: [LinkTableViewCell] = [LinkTableViewCell]()
    
    // keeps track of observer used to see when video ends
    var videoEndsObserver: NSObjectProtocol?

    
    // keep status bar visible
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView?.dataSource = self
        self.tableView?.delegate = self

        // set title: nil case means we're in hot posts view
        if let sport = self.sport {
            self.title = sport.name
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
        // if we're in hot posts view: make status bar solid white
        guard let statusBarView = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else {
            return
        }
        
        // TODO: separate this into new VC
        if self.sport != nil {
            statusBarView.backgroundColor = nil
        } else {
            statusBarView.backgroundColor = UIColor.white
        }
    
        // start animating loading spinner
        self.activityIndicator?.startAnimating()
        
        // reload data
        self.tableView?.reloadData()
        self.initLoadVideoPosts()
    }
    
    // null table if view disappears
    override func viewWillDisappear(_ animated: Bool) {       
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
        DataProvider.getVideoPosts(league: self.sport?.subreddit, completion: { [weak self] in
            self?.videoPosts = DataProvider.videoPosts
            self?.tableView?.reloadData()     // necessary to load data in table view
            
            // show error view if there are no posts
            if DataProvider.videoPosts.isEmpty {
                self?.errorView?.isHidden = false
            }
            
            // play first video if indexPathForPlayingVideo is null
            let firstIndexPath = IndexPath(row: 0, section:0)
            let indexPathToPlay = self?.indexPathForPlayingVideo ?? firstIndexPath
            
            // scroll tableView to video cell if it exists and isn't the first row (which would hide the header if so)
            if let cell = self?.tableView?.cellForRow(at: indexPathToPlay) as? LinkTableViewCell {
                if indexPathToPlay != firstIndexPath {
                    self?.tableView?.scrollToRow(at: indexPathToPlay, at: .top, animated: false)
                }
                
                let indexCount = self?.calculateRows(indexPath: indexPathToPlay) ?? -1
                let leaguePage = self?.sport?.name ?? "[today view]"
                cell.loadVideoForCell(isMute: self?.isMute ?? true, indexCount: indexCount, leaguePage: leaguePage)
            }
            
            // hide loading indicator
            self?.activityIndicator?.stopAnimating()
        })
    }
    
    func calculateRows(indexPath: IndexPath) -> Int {
        // find 1D index for the now-playing video (use this for analytics to see how far down the table people watch videos)
        var indexCount: Int = 0
        if let tableView = self.tableView {
            for i in stride(from: 0, to: indexPath.section, by: 1) {
                indexCount += tableView.numberOfRows(inSection: i)
            }
            indexCount += indexPath.row + 1
        }
        return indexCount
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
                cell.updateMuteControls(isMute: self.isMute)
            }
        }
    }
}


// MARK-- UITableViewDelegate
extension FeedViewController: UITableViewDelegate {
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
            cell.thumbnailView?.sd_setImage(with: videoPost.thumbnailUrl, placeholderImage: nil)
            cell.label?.text = videoPost.title
            
            // set label for time delta
            cell.timeLabel?.text = videoPost.datePosted.timeAgoDisplay()
            
            // sets dimensions for each cell
            setDimensionsForTableView(cell: cell)
            
            
            // TODO: separate code into new VC
            // if NOT hot posts view, show section header for cell; else set league label
            if self.sport != nil {
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
            cell.updateMuteControls(isMute: self.isMute)
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

}


// MARK-- UITableViewDataSource
extension FeedViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.videoPosts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.videoPosts[section].1.count
    }
    
    // TODO: separate into new VC
    // give the table a section header only if we're NOT viewing hot posts
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.sport == nil {
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
    
    
    // necessary for loading videos in full screen
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}


// MARK-- UITabBarControllerDelegate
extension FeedViewController: UITabBarControllerDelegate {
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
                    videoVC.league = self.sport?.name
                }
            }
        }
    }
}


// MARK--ScrollViewController calls
extension FeedViewController {
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
}


// MARK--LinkTableViewCellDelegate
extension FeedViewController: LinkTableViewCellDelegate {
    // user selects share button (taken from https://stackoverflow.com/questions/35931946/basic-example-for-sharing-text-or-image-with-uiactivityviewcontroller-in-swift)
    func shareVideo(videoPost: VideoPost) {
        // TODO: separate into new VC
        // analytics
        let league = self.sport?.name ?? "[today view]"
        
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
