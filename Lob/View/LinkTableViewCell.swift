//
//  LinkTableViewCell.swift
//  TheLobApp
//
//  Created by Elliot Boschwitz on 5/1/18.
//  Copyright © 2018 Elliot Boschwitz. All rights reserved.
//

import UIKit
import AVKit
import FirebaseAnalytics
import FontAwesome_swift

protocol FeedCellDelegate: class {
    func willShareVideo(videoPost: VideoPost)
}


class LinkTableViewCell: UITableViewCell {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var playerViewWidth: NSLayoutConstraint?
    @IBOutlet weak var playerViewHeight: NSLayoutConstraint?
    @IBOutlet weak var label: UILabel?
    @IBOutlet weak var playerView: PlayerView?
    @IBOutlet weak var timeLabel: UILabel?
    @IBOutlet weak var timeLabelIcon: UIImageView?
    @IBOutlet weak var thumbnailView: ThumbnailImageView?
    @IBOutlet weak var muteToggleButton: UIButton?
    @IBOutlet weak var leagueLabel: UILabel?
    @IBOutlet weak var leagueLabelIcon: UIImageView?
    @IBOutlet weak var authorButton: RedditAuthorButton?

    var delegate: FeedCellDelegate?
    var videoPost: VideoPost?
    var isVideoControlsVisible: Bool = false
    var videoAsset: AVAsset?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.thumbnailView?.sd_setImage(with: nil, placeholderImage: nil)
        self.playerView?.playerLayer.player?.replaceCurrentItem(with: nil)
    }
    
    func updateMuteControls(isMuted: Bool) {
        if isMuted {
            self.muteToggleButton?.titleLabel?.font = UIFont.fontAwesome(ofSize: 30, style: .solid)
            self.muteToggleButton?.setTitle(String.fontAwesomeIcon(name: .volumeOff), for: .normal)
        } else {
            self.muteToggleButton?.titleLabel?.font = UIFont.fontAwesome(ofSize: 30, style: .solid)
            self.muteToggleButton?.setTitle(String.fontAwesomeIcon(name: .volumeUp), for: .normal)
        }
    }
    

    // user selects share button (taken from https://stackoverflow.com/questions/35931946/basic-example-for-sharing-text-or-image-with-uiactivityviewcontroller-in-swift)
    @IBAction func shareButton(_ sender: Any) {
        // reference delegate to launch share sheet on parent view
        if let delegate = self.delegate, let videoPost = self.videoPost {
            delegate.willShareVideo(videoPost: videoPost)
        }
    }

    // button for opening reddit page
    @IBAction func authorButtonSelect(_ sender: Any) {
        if let videoPost = videoPost, let url = URL(string: videoPost.redditCommentsUrlRaw) {
            UIApplication.shared.open(url, options: [:])            
        }
    }
}

// custom classes influenced from https://medium.com/@harmittaa/uibutton-with-label-text-and-right-aligned-image-a9d0f590bba1
class ShareButton: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if imageView != nil {
            imageView?.frame = CGRect(x: 0, y: (frame.size.height-15)/2, width: 15, height: 15)
            imageView?.image = UIImage(named: "share")?.withRenderingMode(.alwaysTemplate)
        }
    }
}

class RedditAuthorButton: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if imageView != nil {
            imageView?.frame = CGRect(x: 0, y: (frame.size.height-15)/2, width: 15, height: 15)
            imageView?.image = UIImage(named: "reddit")?.withRenderingMode(.alwaysTemplate)
        }
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

