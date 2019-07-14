//
//  VideoPost.swift
//  TheLobApp
//
//  Created by Elliot Boschwitz on 5/9/18.
//  Copyright © 2018 Elliot Boschwitz. All rights reserved.
//

import AVKit
import UIKit

public struct VideoPost: Decodable {
    var id: String
    var title: String
    var league: String
    var datePostedRaw: String
    var datePosted: Date
    var dateShort: Date
    var author: String
    var redditScore: Int
    var redditCommentsUrl: URL?
    var url: URL?
    var mp4Url : URL?
    var thumbnailUrl: URL?
    var height: Int
    var width: Int
    var hotScore: Float
    
    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case league = "league"
        case datePostedRaw = "date_posted"
        case author = "author"
        case redditScore = "reddit_score"
        case redditCommentsUrlRaw = "reddit_comments_url"
        case urlRaw = "url"
        case mp4UrlRaw = "mp4_url"
        case thumbnailUrlRaw = "thumbnail_url"
        case height = "height"
        case width = "width"
        case hotScore = "hot_score"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.league = try container.decode(String.self, forKey: .league)
        self.datePostedRaw = try container.decode(String.self, forKey: .datePostedRaw)
        self.author = try container.decode(String.self, forKey: .author)
        self.redditScore = try container.decode(Int.self, forKey: .redditScore)
        self.redditCommentsUrl = URL(string: try container.decode(String.self, forKey: .redditCommentsUrlRaw))
        self.url = URL(string: try container.decode(String.self, forKey: .urlRaw))
        self.mp4Url = URL(string: try container.decode(String.self, forKey: .mp4UrlRaw))
        self.thumbnailUrl = URL(string: try container.decode(String.self, forKey: .thumbnailUrlRaw))
        self.height = try container.decode(Int.self, forKey: .height)
        self.width = try container.decode(Int.self, forKey: .width)
        self.hotScore = try container.decodeIfPresent(Float.self, forKey: .hotScore) ?? 0
        
        // set datePosted
        let formatterRawString = DateFormatter()
        formatterRawString.locale = Locale(identifier: "en_US_POSIX")
        formatterRawString.dateFormat = "EEE, d MMM yyyy HH:mm:ss ZZZ"
        formatterRawString.timeZone = TimeZone.current
        self.datePosted = formatterRawString.date(from: datePostedRaw) ?? Date()
        
        // set dateShort
        let calendar = Calendar.current
        let year = calendar.component(.year, from: datePosted)
        let month = calendar.component(.month, from: datePosted)
        let day = calendar.component(.day, from: datePosted)
        
        let formatterShort = DateFormatter()
        formatterShort.locale = Locale(identifier: "en_US_POSIX")
        formatterShort.dateFormat = "yyyy M d"
        self.dateShort = formatterShort.date(from: "\(year) \(month) \(day)") ?? Date()
    }
    
}
