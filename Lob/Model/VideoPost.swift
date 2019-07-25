//
//  VideoPost.swift
//  TheLobApp
//
//  Created by Elliot Boschwitz on 5/9/18.
//  Copyright © 2018 Elliot Boschwitz. All rights reserved.
//

import UIKit


// MARK: - VideoPost Class
struct VideoPost: Codable {
    var id: String
    var title: String
    var subreddit: String
    var datePostedRaw: String
    var author: String
    var redditScore: Int
    var redditCommentsUrlRaw: String
    var urlRaw: String
    var mp4UrlRaw : String
    var thumbnailUrlRaw: String
    var height: Int
    var width: Int
    var hotScore: Float?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case subreddit = "league"
        case datePostedRaw = "date_posted"
        case author
        case redditScore = "reddit_score"
        case redditCommentsUrlRaw = "reddit_comments_url"
        case urlRaw = "url"
        case mp4UrlRaw = "mp4_url"
        case thumbnailUrlRaw = "thumbnail_url"
        case height
        case width
        case hotScore = "hot_score"
    }

    // MARK: - Long Datetime for Posted Date
    func getDatePostedLong() -> Date? {
        let formatterRawString = DateFormatter()
        formatterRawString.locale = Locale(identifier: "en_US_POSIX")
        formatterRawString.dateFormat = "EEE, d MMM yyyy HH:mm:ss ZZZ"
        formatterRawString.timeZone = TimeZone.current
        return formatterRawString.date(from: self.datePostedRaw)
    }

    // MARK: - Short datetime for posted date
    func getDatePostedShort() -> Date? {
        guard let datePosted = getDatePostedLong() else {
            return nil
        }

        // set dateShort
        let calendar = Calendar.current
        let year = calendar.component(.year, from: datePosted)
        let month = calendar.component(.month, from: datePosted)
        let day = calendar.component(.day, from: datePosted)

        let formatterShort = DateFormatter()
        formatterShort.locale = Locale(identifier: "en_US_POSIX")
        formatterShort.dateFormat = "yyyy M d"
        return formatterShort.date(from: "\(year) \(month) \(day)")
    }

    // MARK: - Returns Sport class for VideoPost
    func getSport() -> Sport? {
        return DataProvider.shared.sportsData[subreddit]
    }
}
