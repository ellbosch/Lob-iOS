//
//  Sport.swift
//  Lob
//
//  Created by Elliot Boschwitz on 7/13/19.
//  Copyright © 2019 Elliot Boschwitz. All rights reserved.
//

import UIKit


public struct Sport: Codable {
    var name: String?
    var iconLabel: String?
    var subreddit: String?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case iconLabel
        case subreddit
    }
}
