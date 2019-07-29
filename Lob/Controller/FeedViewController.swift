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
        self.tableView?.delegate = autoplayManager
        autoplayManager.delegate = self
        
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
    }
    
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
        
        // start animating loading spinner
        self.activityIndicator?.startAnimating()
        
        // reload data
        self.tableView?.reloadData()
        self.initLoadVideoPosts()
    }
    
    // null table if view disappears
    override func viewWillDisappear(_ animated: Bool) {        
        self.dataSource.videoPosts.removeAll()
        self.tableView?.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    /*****************************************
     INITALIZING FOR LOADING DATA
     *****************************************/
    
    // loads video posts and scrolls to current day. if no sport is selected, the user is viewing "hot" posts.
    private func initLoadVideoPosts() {
        DataProvider.shared.getVideoPosts(sport: self.sport,
          success: { [weak self] response in
            DispatchQueue.main.async {
                self?.dataSource.videoPosts = response
                self?.tableView?.reloadData()     // necessary to load data in table view
                
                // show error view if there are no posts
                if response.isEmpty {
                    self?.errorView?.isHidden = false
                }
                
                if let tableView = self?.tableView {
                    // play first video if indexPathForPlayingVideo is null
                    let firstIndexPath = IndexPath(row: 0, section:0)
                    self?.autoplayManager.playVideo(tableView, forRowAt: firstIndexPath)
                }
                
                // hide loading indicator
                self?.activityIndicator?.stopAnimating()
            }
        }, fail: { error in
            Analytics.logEvent("networkFailed", parameters: [ AnalyticsParameterItemCategory: error ])
            print(error.localizedDescription)
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
    
        initLoadVideoPosts()
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
extension FeedViewController: AutoplayTableViewDelegate {
    // MARK: - Presents full screen VC when prompted from delegate
    func willPresentFullScreen(forVideoAt index: Int) {
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
//        let videoVC = VideoViewController(videos: videoPostsNoDate, videoIndexToStart: index)
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
