//
//  FeedDelegate.swift
//  Lob
//
//  Created by Elliot Boschwitz on 7/14/19.
//  Copyright © 2019 Elliot Boschwitz. All rights reserved.
//

import AVKit
import FirebaseAnalytics
import UIKit


class FeedDelegate: NSObject, UITableViewDelegate {
    weak var feedVC: UIViewController?           // hold weak reference to parent VC when we need to push new view controller
    var videoLoopObserver: NSObjectProtocol?     // holds reference to videoLoopObserver so only one is created
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // sets table cell indent to 0
        cell.separatorInset = UIEdgeInsets.zero
    }
    
    // play middle(ish) video AFTER scroll drag has ended, but ONLY if user hasn't done a big swipe
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let tableView = scrollView as? UITableView else {
            return
        }
        if !decelerate, let indexPath = locateIndexToPlayVideo(tableView) {
            playVideo(tableView, forRowAt: indexPath)
        }
    }
    
    // load video if deceleration ended
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let tableView = scrollView as? UITableView else {
            return
        }
        if let indexPath = locateIndexToPlayVideo(tableView) {
            playVideo(tableView, forRowAt: indexPath)
        }
    }
    
    // set video to fullscreen on tap, unmute video, and pause all other playing videos
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let feedVC = feedVC as? FeedViewController else {
            return
        }
        
        // programmatically call segue to show video detail
        feedVC.performSegue(withIdentifier: "videoDetailSegue", sender: self)
    }
}
extension FeedDelegate {
    // MARK: play video at specified index
    func playVideo(_ tableView: UITableView, forRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? LinkTableViewCell {
            // don't reload player if already loaded
            if let player = cell.playerView?.player, player.currentItem != nil {
                if player.rate == 0 {
                    player.play()
                } else {
                    return      // SAFETY CALL, SHOULDN'T HAPPEN--don't do anything if video is already playing
                }
            } else {
                // start loading spinner
                cell.activityIndicator?.startAnimating()
                
                guard let videoPost = cell.videoPost, let mp4Url = videoPost.mp4Url else { return }
                
                // lazily instantiate asset before async call
                let player = AVPlayer(playerItem: nil)
                cell.playerView?.playerLayer.player = player
                
                DispatchQueue.global(qos: .background).async { [weak cell] in
                    // load avplayer in background thread
                    let item = AVPlayerItem(url: mp4Url)
                    
                    // main thread changes: play video player and set to mute/unmute
                    DispatchQueue.main.async { [weak cell] in
                        cell?.playerView?.playerLayer.player?.replaceCurrentItem(with: item)
                        cell?.playerView?.player?.play()
                        cell?.playerView?.fadeIn()
                        cell?.activityIndicator?.stopAnimating()
                        cell?.playerView?.player?.isMuted = cell?.playerView?.isMuted ?? false
                    }
                }
                
                Analytics.logEvent("videoLoaded", parameters: [
                    AnalyticsParameterItemID: videoPost.id,
                    AnalyticsParameterItemName: videoPost.title,
                    AnalyticsParameterItemCategory: videoPost.sport?.name ?? "",
                    AnalyticsParameterContent: "table",
                    AnalyticsParameterIndex: calculateRows(tableView, indexPath: indexPath)
                ])
            }
            pauseAllVideos(tableView, exceptAt: indexPath)
            
            // re-init video looper observer--needed to make sure previously loaded videos also don't repeat when called. maintains 1-to-1 mapping.
            if let observer = videoLoopObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            videoLoopObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: cell.playerView?.player?.currentItem, queue: .main) { _ in
                cell.playerView?.player?.seek(to: CMTime.zero)
                cell.playerView?.player?.play()
            }
        }
    }
    
    // MARK: pause all videos except specified
    // ensures all other videos are paused except the specified index path
    private func pauseAllVideos(_ tableView: UITableView, exceptAt indexPath: IndexPath) {
        guard let visibleCells = tableView.visibleCells as? [LinkTableViewCell] else { return }
        
        for cellptr in visibleCells {
            let indexPathPtr = tableView.indexPath(for: cellptr)
            
            if indexPath != indexPathPtr {
                cellptr.playerView?.player?.pause()
            }
        }
    }
    
    // MARK: identifies the index for where we play video
    private func locateIndexToPlayVideo(_ tableView: UITableView) -> IndexPath? {
        var middleIndex: IndexPath?
        
        // see if full screen mode is disabled and new cells have loaded, if yes, toggle autoplay
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
                headerHeight = tableView.safeAreaInsets.top
            }
            
            // plays top most video that isn't above the header height
            for ptrIndex in visibleCellIndexes {
                let rectOfCellInTableView = tableView.rectForRow(at: ptrIndex)
                let rectOfCellInSuperview = tableView.convert(rectOfCellInTableView, to: tableView.superview)
                
                // play video if it's not hidden at the top, OR if it's the last video
                if rectOfCellInSuperview.origin.y > headerHeight || ptrIndex == visibleCellIndexes.last {
                    // stops for loop
                    middleIndex = ptrIndex
                    break
                }
            }
        }
        return middleIndex
    }
    
    // MARK: find 1D index for the now-playing video (use this for analytics to see how far down the table people watch videos)
    public func calculateRows(_ tableView: UITableView, indexPath: IndexPath) -> Int {
        var indexCount: Int = 0

        for i in stride(from: 0, to: indexPath.section, by: 1) {
            indexCount += tableView.numberOfRows(inSection: i)
        }
        indexCount += indexPath.row + 1
        
        return indexCount
    }
    
}
