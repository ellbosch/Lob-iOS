//
//  PlayerNotifier.swift
//  Lob
//
//  Created by Elliot Boschwitz on 7/28/19.
//  Copyright © 2019 Elliot Boschwitz. All rights reserved.
//

import AVKit
import UIKit

// MARK: - Protocol for Player Notifier delegate
protocol PlayerNotifierDelegate: class {
    func playerItemDidReachEndTime(for item: AVPlayerItem)
}

// MARK: - Notifier class that signals to delegate that a video has reached the end
class PlayerNotifier: NSObject {
    static let shared = PlayerNotifier()
    
    var videoDidEndPlayingObserver: NSObjectProtocol?
    var delegate: PlayerNotifierDelegate?
    
    // MARK: - Adds player observer to listen to new object
    func addPlayerObserver(for item: AVPlayerItem) {
        // setup video did end playing observer and remove last made one
        if let videoDidEndPlayingObserver = self.videoDidEndPlayingObserver {
            NotificationCenter.default.removeObserver(videoDidEndPlayingObserver)
        }
        
        self.videoDidEndPlayingObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            
            // signal to delegate that playe reached end
            self?.delegate?.playerItemDidReachEndTime(for: item)
        }
    }
    
    // MARK: - Removes observer--recommended to use when view is closed
    func removePlayerObserver() {
        // remove skip observer of current video--THIS FIXES THE BUG THE VIDEO TO SUDDENLY PLAY IN BACKGROUND
        if let videoDidEndPlayingObserver = self.videoDidEndPlayingObserver {
            NotificationCenter.default.removeObserver(videoDidEndPlayingObserver)
        }
    }
}
