//
//  FeedDelegate.swift
//  Lob
//
//  Created by Elliot Boschwitz on 7/14/19.
//  Copyright © 2019 Elliot Boschwitz. All rights reserved.
//

import UIKit


class FeedDataSource: NSObject, UITableViewDataSource {
    var videoPosts: [(Date, [VideoPost])] = []
    var allRows: [LinkTableViewCell] = []           // we REALLY need to get rid of this
    var sport: Sport?
    var isMuted: Bool = true
    
    weak var cellDelegate: FeedCellDelegate?

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "LinkTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? LinkTableViewCell else {
            fatalError("The dequeued cell is not an instance of LinkTableViewCell")
        }
        
        cell.delegate = cellDelegate
        
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
            let dimensions = setPlayerDimensionsForTableView(width: videoPost.width, height: videoPost.height)
            cell.playerViewWidth?.constant = dimensions.0
            cell.playerViewHeight?.constant = dimensions.1
            
            if let sport = videoPost.sport {
                cell.leagueLabelIcon?.image = UIImage(named: sport.iconLabel)
                cell.leagueLabel?.text = sport.name
            }
            
            // set author button
            cell.authorButton?.setTitle(videoPost.author, for: .normal)
            
            // allows icon for clock to have a dark gray tint (rather than default black
            cell.timeLabelIcon?.image = UIImage(named: "clock")?.withRenderingMode(.alwaysTemplate)
            
            // show mute button and update volume toggle
            cell.muteToggleButton?.isHidden = false
            cell.updateMuteControls(isMuted: self.isMuted)
            cell.playerView?.isMuted = isMuted
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.videoPosts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.videoPosts[section].1.count
    }
    
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
    
    // sets dimensions for elements in cell for table view
    private func setPlayerDimensionsForTableView(width: Int, height: Int) -> (CGFloat, CGFloat) {
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


