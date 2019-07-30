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
    
    var dataSource = AutoplayTableDataSource()
    var autoplayManager = AutoplayTableDelegate()

    var sport: Sport?
    var page = 1                    // pagination counter
    var isPaginationOk = true       // protects us from multiple pagination calls
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(sport: Sport?) {
        self.init(nibName: nil, bundle: nil)
        self.sport = sport
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource.sport = self.sport
        dataSource.cellDelegate = self
        
        // set tableview delegates
        self.tableView?.dataSource = dataSource
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
    
        // Set playernotifier delegate each time this view loads
        PlayerNotifier.shared.delegate = autoplayManager
        
        // load videos by specified view
        processPostsResponse()
    }
    
    // reset table if view disappears
    override func viewWillDisappear(_ animated: Bool) {
        self.dataSource.videoPosts.removeAll()
        self.tableView?.reloadData()
    }
    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
    
    // hide iphone x home indicator in fullscreen mode
    func prefersHomeIndicatorAutoHidden() -> Bool {
        return false
    }
    
    // keep status bar visible
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    
    /*****************************************
     INITALIZING FOR LOADING DATA
     *****************************************/
    
    // loads video posts and scrolls to current day. if no sport is selected, the user is viewing "hot" posts.
    private func processPostsResponse() {
        DataProvider.shared.getVideoPosts(sport: self.sport, page: self.page,
          success: { [weak self] response in
            DispatchQueue.main.async {
                self?.dataSource.videoPosts += response
                
                // show error view if there are no posts
                if self?.page == 1 && response.isEmpty {
                    self?.errorView?.isHidden = false
                } else {
                    // play first video if this is first call
                    if let tableView = self?.tableView, self?.page == 1 {
                        let firstIndexPath = IndexPath(row: 0, section:0)
                        self?.autoplayManager.playVideo(tableView, forRowAt: firstIndexPath)
                    }
                    self?.page += 1     // increment page
                }

                // hide loading indicator
                self?.activityIndicator?.stopAnimating()
                self?.tableView?.reloadData()
            }
            self?.isPaginationOk = true
        }, fail: { [weak self] error in
            Analytics.logEvent("networkFailed", parameters: [ AnalyticsParameterItemCategory: error ])
            print(error)
            
            // show error message and hide activity indicator
            DispatchQueue.main.async {
                self?.errorView?.isHidden = false
                self?.activityIndicator?.stopAnimating()
            }
            
            self?.isPaginationOk = true
        }
      )
    }

    
    /********************************
     REFRESH FUNCTIONALITY
     *********************************/
    
    @objc func handleRefresh(_ sender: Any) {
        // remove table before refresh sequence begins (makes the experience feel nicer since everything gets reloaded anyways
        self.dataSource.videoPosts.removeAll()
        self.tableView?.reloadData()
    
        self.page = 1       // reset pagination
        
        processPostsResponse()
        self.tableView?.refreshControl?.endRefreshing()
        
        // log analytics
        Analytics.logEvent("refreshEvent", parameters: nil)
    }
    
    /********************************
     MUTE TOGGLE
     *********************************/
    
    // toggles mute on current video and changes icons
    @IBAction func muteToggleSelect(_ sender: Any) {
        // ensures future loaded videos will have mute toggled
        self.dataSource.isMuted.toggle()
        
        // update cells that have already loaded
        if let visibleCells = (self.tableView?.visibleCells as? [LinkTableViewCell]) {
            for cell in visibleCells {
                cell.updateMuteControls(isMuted: self.dataSource.isMuted)
                cell.playerView?.isMuted = self.dataSource.isMuted
            }
        }
    }
}

// MARK: - AutoplayDelegate implementation
extension FeedViewController: UITableViewDelegate {
    // MARK: - Set pagination if we reach last element
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if self.isPaginationOk {
            let lastSection = tableView.numberOfSections - 1
            let lastRow = IndexPath(row: tableView.numberOfRows(inSection: lastSection) - 1, section: lastSection)
            if indexPath == lastRow {
                self.isPaginationOk = false
                processPostsResponse()
            }
        }
    }
    
    // MARK: - Set video to fullscreen on tap, unmute video, and pause all other playing videos
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = autoplayManager.calculateRows(tableView, indexPath: indexPath) - 1
        willPresentFullScreen(forVideoAt: index)
    }
    
    // MARK: - Play middle(ish) video AFTER scroll drag has ended, but ONLY if user hasn't done a big swipe
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let tableView = scrollView as? UITableView else {
            return
        }
        if !decelerate, let indexPath = autoplayManager.locateIndexToPlayVideo(tableView) {
            autoplayManager.playVideo(tableView, forRowAt: indexPath)
        }
    }
    
    // MARK: - load video if deceleration ended
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let tableView = scrollView as? UITableView else {
            return
        }
        if let indexPath = autoplayManager.locateIndexToPlayVideo(tableView) {
            autoplayManager.playVideo(tableView, forRowAt: indexPath)
        }
    }
    
    
    
    // MARK: - Presents full screen VC when prompted from delegate
    private func willPresentFullScreen(forVideoAt index: Int) {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let videoVC: VideoViewController = storyboard.instantiateViewController(withIdentifier: "VideoViewController") as? VideoViewController else {
            return
        }
        // send array of videoposts and current index to segue vc
        var videoPostsNoDate: [VideoPost] = [VideoPost]()
        
        for videosForDate in self.dataSource.videoPosts {
            let videoPosts = videosForDate.1
            videoPostsNoDate.append(contentsOf: videoPosts)
        }
        videoVC.videos = videoPostsNoDate
        
        // send index of currently viewed video (index = row + rowsInSection(section-1)
        videoVC.videoIndex = index
        
        self.present(videoVC, animated: true, completion: nil)
    }
}

extension FeedViewController: FeedCellDelegate {
    func willShareVideo(videoPost: VideoPost) {
        // TODO: separate into new VC
        // analytics
        let league = self.sport?.name ?? "[today view]"
        
        Analytics.logEvent(AnalyticsEventShare, parameters: [
            AnalyticsParameterItemCategory: league,
            AnalyticsParameterItemID: videoPost.id,
            AnalyticsParameterContentType: "outgoing_link"]
        )
        
        // construct url to lob.tv
        let videoUrl = URL(string: "https://lob.tv/video/\(videoPost.id)/")
        
        // set up activity view controller
        let linkToShare = [videoUrl]
        let activityViewController = UIActivityViewController(activityItems: linkToShare as [Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
}
