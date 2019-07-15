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

//protocol FeedProtocol: class {
//    func feed(_ feed: Feed, shouldPlayVideoAt indexPath: IndexPath)
//}

class FeedDelegate: NSObject, UITableViewDelegate {
    // keeps track of currently playing video
//    var indexPathForPlayingVideo: IndexPath?
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // sets table cell indent to 0
        cell.separatorInset = UIEdgeInsets.zero
    }
    
    // play middle(ish) video AFTER scroll drag has ended, but ONLY if user hasn't done a big swipe
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let tableView = scrollView as? UITableView else {
            return
        }
        if !decelerate {
            autoplayVideo(tableView)
        }
    }
    
    // load video if deceleration ended
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let tableView = scrollView as? UITableView else {
            return
        }
        
        autoplayVideo(tableView)
    }
    
    // set video to fullscreen on tap, unmute video, and pause all other playing videos
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        self.indexPathForPlayingVideo = indexPath
//
//        // programmatically call segue to show video detail
//        self.performSegue(withIdentifier: "videoDetailSegue", sender: self)
//    }
}
extension FeedDelegate {
    // MARK: checks if video is in correct part of view to play
    private func autoplayVideo(_ tableView: UITableView) {
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
                    return playVideo(tableView, forRowAt: ptrIndex)
                }
            }
        }
    }
    
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
//                        cell?.updateMuteControls(isMute: isMute)
                        cell?.playerView?.player?.play()
                        cell?.playerView?.fadeIn()
                        cell?.activityIndicator?.stopAnimating()
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
            
            // KVO to keep video in loop
//            self.videoEndsObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: cell.playerView?.player?.currentItem, queue: .main) { [weak self] _ in
//                // replay video just for one that's currently playing
//                if let indexPathForPlayingVideo = self?.indexPathForPlayingVideo,
//                    let cell = tableView.cellForRow(at: indexPathForPlayingVideo) as? LinkTableViewCell {
//                    cell.playerView?.player?.seek(to: CMTime.zero)
//                    cell.playerView?.player?.play()
//                }
//            }
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
    
    // MARK: find 1D index for the now-playing video (use this for analytics to see how far down the table people watch videos)
    private func calculateRows(_ tableView: UITableView, indexPath: IndexPath) -> Int {
        var indexCount: Int = 0

        for i in stride(from: 0, to: indexPath.section, by: 1) {
            indexCount += tableView.numberOfRows(inSection: i)
        }
        indexCount += indexPath.row + 1
        
        return indexCount
    }
    
}
