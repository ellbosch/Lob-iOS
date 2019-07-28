//
//  VideoLoader.swift
//  Lob
//
//  Created by Elliot Boschwitz on 7/28/19.
//  Copyright © 2019 Elliot Boschwitz. All rights reserved.
//

import AVKit
import UIKit

extension DataProvider {
  
    func loadVideo(for url: URL?, success: ((AVPlayerItem) -> ())? = nil) {
        // load avplayer in background thread
        guard let url = url else {
            // need errors here
            
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            let item = AVPlayerItem(url: url)
            
            success?(item)
        }
    }
}
