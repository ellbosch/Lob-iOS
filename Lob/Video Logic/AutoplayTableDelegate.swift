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

// MARK: - Protocol for autoplay manager
protocol AutoplayTableViewDelegate: class {
    // MARK - signals to delegate to go to fullscreen mode
    func willPresentFullScreen(forVideoAt index: Int)
}

class AutoplayTableDelegate: NSObject {
    private weak var playerCurrentlyPlaying: AVPlayer?
    
    // MARK: Play video at specified index
    func playVideo(_ tableView: UITableView) {
        guard let indexPath = locateIndexToPlayVideo(tableView) else {
            print("No index path identified for autoplaying table.")
            return
        }
        
        if let cell = tableView.cellForRow(at: indexPath) as? LinkTableViewCell {
            // don't reload player if already loaded
            if let player = cell.playerView?.player, player.currentItem != nil {
                player.play()
                pauseAllVideos(tableView, exceptAt: indexPath)
            } else {
                // start loading spinner
                cell.activityIndicator?.startAnimating()
                
                guard let videoPost = cell.videoPost else { return }
                
                cell.playerView?.setPlayerItem(from: URL(string: videoPost.mp4UrlRaw),
                    success: { [weak self] player in
                        DispatchQueue.main.async { [weak self] in
                            // handle view and AV
                            cell.playerView?.player?.play()
                            cell.playerView?.fadeIn()
                            cell.activityIndicator?.stopAnimating()
                            cell.playerView?.player?.isMuted = cell.playerView?.isMuted ?? false
                            self?.pauseAllVideos(tableView, exceptAt: indexPath)
                        }
                        Analytics.logEvent("videoLoaded", parameters: [
                            AnalyticsParameterItemID: videoPost.id,
                            AnalyticsParameterItemName: videoPost.title,
                            AnalyticsParameterItemCategory: videoPost.getSport() ?? "",
                            AnalyticsParameterContent: "table",
                            AnalyticsParameterIndex: self?.calculateRows(tableView, indexPath: indexPath) ?? -1
                            ]
                        )
                    }
                )
            }
            // save pointer
            self.playerCurrentlyPlaying = cell.playerView?.player
        }
    }
    
    // MARK: - Pause current playing video
    func pauseCurrentVideo() {
        self.playerCurrentlyPlaying?.pause()
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
        // play first cell if we haven't loaded anything yet
        if self.playerCurrentlyPlaying == nil {
            return IndexPath(row: 0, section: 0)
        }
        
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

// MARK: - Replay current video if it reaches end
extension AutoplayTableDelegate: PlayerNotifierDelegate {
    func playerItemDidReachEndTime(for player: AVPlayer) {
        player.seek(to: CMTime.zero)
        player.play()
    }
}
