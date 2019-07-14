//
//  VideoAutoplay.swift
//  Lob
//
//  Created by Elliot Boschwitz on 7/13/19.
//  Copyright © 2019 Elliot Boschwitz. All rights reserved.
//

import CoreMedia
import Foundation
import UIKit

// MARK-- video autoplay logic for feed vc
extension FeedViewController {
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
                    if self.indexPathForPlayingVideo != ptrIndex {
                        self.indexPathForPlayingVideo = ptrIndex
                        if let cell = self.tableView?.cellForRow(at: ptrIndex) as? LinkTableViewCell {
                            // don't reload player if already loaded
                            if let player = cell.playerView?.player, player.currentItem != nil {
                                if player.rate == 0 {
                                    player.play()
                                } else {
                                    return      // SAFETY CALL, SHOULDN'T HAPPEN--don't do anything if video is already playing
                                }
                            } else {
                                let indexCount = self.calculateRows(indexPath: ptrIndex)
                                let leaguePage = self.sport?.name ?? "[today view]"
                                cell.loadVideoForCell(isMute: self.isMute, indexCount: indexCount, leaguePage: leaguePage)
                            }
                            pauseAllVideosExcept(indexPath: ptrIndex)
                            
                            // KVO to keep video in loop
                            self.videoEndsObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: cell.playerView?.player?.currentItem, queue: .main) { [weak self] _ in
                                // replay video just for one that's currently playing
                                if let indexPathForPlayingVideo = self?.indexPathForPlayingVideo,
                                    let cell = tableView.cellForRow(at: indexPathForPlayingVideo) as? LinkTableViewCell {
                                    cell.playerView?.player?.seek(to: CMTime.zero)
                                    cell.playerView?.player?.play()
                                }
                            }
                        }
                    }
                    return
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
    
    
    // sets dimensions for elements in cell for table view
    func setPlayerDimensionsForTableView(width: Int, height: Int) -> (CGFloat, CGFloat) {
        // sets dimensions for AVPlayerLayer
        let aspectRatio = CGFloat(height) / CGFloat(width)
        
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
        return (width, height)
    }
}
