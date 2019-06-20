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
    var videoAsset: AVAsset?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.thumbnailView?.sd_setImage(with: nil, placeholderImage: nil)
        self.playerView?.playerLayer.player?.replaceCurrentItem(with: nil)
    }
    

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
    
    func loadVideoForCell(startTime: CMTime? = nil) {
        // start loading spinner
        activityIndicator?.startAnimating()
        
        guard let videoPost = videoPost, let mp4Url = videoPost.mp4Url else { return }
        
        // lazily instantiate asset before async call
        let player = AVPlayer(playerItem: nil)
        playerView?.playerLayer.player = player
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            // Background thread
            // Do your AVPlayer work here
            let item = AVPlayerItem(url: mp4Url)
            
            // When you need to update the UI, switch back out to the main thread
            DispatchQueue.main.async {
                // Main thread
                // Do your UI updates here
                self?.playerView?.playerLayer.player?.replaceCurrentItem(with: item)
                self?.playerView?.player?.play()
                self?.playerView?.fadeIn()
                self?.activityIndicator?.stopAnimating()
            }
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

