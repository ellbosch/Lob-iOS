//
//  DataProvider.swift
//  The Lob
//
//  Created by Elliot Boschwitz on 5/4/19.
//  Copyright © 2019 Elliot Boschwitz. All rights reserved.
//

import Alamofire
import Foundation
import SwiftyJSON
import UIKit

class DataProvider {
    private static let LOB_ROOT_URL = "https://www.lob.tv"
    
    static var videoPosts: [(Date, [VideoPost])] = []
    
    static func getVideoPosts(league: String?, completion: @escaping () -> ()) {
        if let league = league {
            self.getVideoPostsForSport(sport: league, completion: { completion() })
        }
        else {
            self.getHotVideoPosts(completion: { completion() })
        }
    }

    static private func getHotVideoPosts(completion: @escaping () -> ()) {
        var videoPostsUnsorted = [Date: [VideoPost]]()
        var videoPostsSorted = [(Date, [VideoPost])]()
        
        Alamofire.request(LOB_ROOT_URL + "/hot_posts").responseJSON { response in
            // TODO: CREATE NEW JSON DECODER
            if let data: Data = response.data, let json: JSON = try? JSON(data: data) {
                for tuple in json {
                    let all_league_posts = tuple.1
                    let decoder = JSONDecoder()
                    
                    for league_posts in all_league_posts {
                        
                        // iterate to next post if no valid data found
                        guard let post_data = try? decoder.decode([VideoPost].self, from: league_posts.1.rawData()) else { continue }
                        
                        for videoPost in post_data {
                            if videoPostsUnsorted[videoPost.dateShort] != nil {
                                videoPostsUnsorted[videoPost.dateShort]?.append(videoPost)
                            } else {
                                videoPostsUnsorted[videoPost.dateShort] = [videoPost]
                            }
                        }
                    }
                }
                
                // sort videos
                for videos in videoPostsUnsorted {
                    let videosSorted = videos.value.sorted(by: { $0.hotScore > $1.hotScore })
                    // overwrite old array
                    videoPostsUnsorted[videos.key] = videosSorted
                }
                
                // sort dates
                let sortedKeys = Array(videoPostsUnsorted.keys).sorted(by: >)
                for key in sortedKeys {
                    let tuple = (key, videoPostsUnsorted[key]!)
                    videoPostsSorted.append(tuple)
                }
                self.videoPosts = videoPostsSorted
            }
            completion()
        }
    }
    
    static private func getVideoPostsForSport(sport: String, completion: @escaping () -> ()) {
        var videoPostsUnsorted = [Date: [VideoPost]]()
        var videoPostsSorted = [(Date, [VideoPost])]()
        
        Alamofire.request(LOB_ROOT_URL + "/new/\(sport)").responseJSON { response in
            if let data:Data = response.data, let json: JSON = try? JSON(data: data) {
                let decoder = JSONDecoder()
                
                for tuple in json {
                    // iterate to next post if no valid data found
                    guard let post_data = try? decoder.decode([VideoPost].self, from: tuple.1.rawData()) else {
                        continue
                    }
                    
                    for videoPost in post_data {
                        if videoPostsUnsorted[videoPost.dateShort] != nil {
                            videoPostsUnsorted[videoPost.dateShort]!.append(videoPost)
                        } else {
                            videoPostsUnsorted[videoPost.dateShort] = [videoPost]
                        }
                    }
                }
                // sort videos
                for videos in videoPostsUnsorted {
                    let videosSorted = videos.value.sorted(by: { $0.datePosted > $1.datePosted })
                    // overwrite old array
                    videoPostsUnsorted[videos.key] = videosSorted
                }
                
                // sort dates
                let sortedKeys = Array(videoPostsUnsorted.keys).sorted(by: >)
                for key in sortedKeys {
                    let tuple = (key, videoPostsUnsorted[key]!)
                    videoPostsSorted.append(tuple)
                }
                self.videoPosts = videoPostsSorted
            }
            completion()
        }
    }
    
    // gets sport data from property list
    static func getSportsData() -> [Sport] {
        var sports: [Sport]?
        
        if let path = Bundle.main.path(forResource: "Sports", ofType: "plist") {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                let decoder = PropertyListDecoder()
                sports = try? decoder.decode([Sport].self, from: data)
            }
        }
        
        return sports ?? []
    }
}
