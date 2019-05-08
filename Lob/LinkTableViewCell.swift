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

    var delegate: LinkTableViewCellDelegate?
    var videoPost: VideoPost?
    var play_on: Bool = false
    var isVideoControlsVisible: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        
//        thumbnailView //.af_cancelImageRequest() // NOTE: - Using AlamofireImage
//        mainImageView.image = nil
//    }
//    
    // user selects share button (taken from https://stackoverflow.com/questions/35931946/basic-example-for-sharing-text-or-image-with-uiactivityviewcontroller-in-swift)
    @IBAction func shareButton(_ sender: Any) {
        // reference delegate to launch share sheet on parent view
        if let delegate = self.delegate, let videoPost = self.videoPost {
            delegate.shareVideo(videoPost: videoPost)
        }
    }
    
    // button for opening reddit page
    @IBAction func authorButtonSelect(_ sender: Any) {
        if let url = videoPost?.redditCommentsUrl {
            UIApplication.shared.open(url, options: [:])            
        }
    }
}

// protocol to call share sheet in parent view
protocol LinkTableViewCellDelegate {
    func shareVideo(videoPost: VideoPost)
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

