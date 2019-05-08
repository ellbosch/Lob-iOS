//
//  VideoDetailViewController.swift
//  The Lob
//
//  Created by Elliot Boschwitz on 12/25/18.
//  Copyright © 2018 Elliot Boschwitz. All rights reserved.
//

import UIKit
import AVKit

class VideoDetailViewController: UIViewController {
    @IBOutlet weak var videoView: UIView!
    
    var videos: [VideoPost]?
    var videoIndex: Int?
    var queue = AVQueuePlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let playerViewController = AVPlayerViewController()

        if videos != nil || videoIndex != nil {
            // play video
            self.queue.insert(AVPlayerItem(url: videos[1]!.mp4Url), after: nil)
            
            playerViewController.player = queue
            videoView.present(playerViewController, animated: true) {
                playerViewController.player!.play()
            }
        }
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
