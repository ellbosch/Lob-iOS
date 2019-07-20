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
    
    static let shared = DataProvider()
    
    private let LOB_ROOT_URL = "https://www.lob.tv"
    
    public var sportsData: [String:Sport] = [:]
    
    // custom error types
    enum DataProviderError: Error {
        case apiError
        case dataResponseError
        case jsonParseError
    }
    
    private init() {
        self.getSportsData()
    }
    
    public func getVideoPosts(league: String?, completion: @escaping ([(Date, [VideoPost])]) -> Void)  {
        if let league = league {
            self.getVideoPostsForSport(sport: league, completion: completion)
        } else {
            getHotVideoPosts(completion: completion)
        }

    }

    private func getHotVideoPosts(completion: @escaping ([(Date, [VideoPost])]) -> Void) {
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
            }
            completion(videoPostsSorted)
        }
    }
    
    private func getVideoPostsForSport(sport: String, completion: @escaping ([(Date, [VideoPost])]) -> Void) {
        var videoPostsUnsorted = [Date: [VideoPost]]()
        var videoPostsSorted = [(Date, [VideoPost])]()
        
        
        guard let urlRequest = URL(string: LOB_ROOT_URL + "/new/\(sport)") else {
            print("ERROR: cannot create URL")
            return
        }

        let task = URLSession(configuration: .default).dataTask(with: urlRequest) { (data, response, error) in
            // check for any errors
            guard error == nil else {
                print("error calling GET on /todos/1")
                print(error!)
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            
            // parse valid responseData
            let decoder = JSONDecoder()
            do {
                guard let postData: [VideoPost] = try decoder.decode([String:[VideoPost]].self, from: responseData)["results"] else {
                    throw DataProviderError.jsonParseError
                }
                for videoPost in postData {
                    if videoPostsUnsorted[videoPost.dateShort] != nil {
                        videoPostsUnsorted[videoPost.dateShort]!.append(videoPost)
                    } else {
                        videoPostsUnsorted[videoPost.dateShort] = [videoPost]
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
                completion(videoPostsSorted)
            } catch {
                print(error)
            }
        }
        task.resume()
            
            
//            if let data: Data = data, let json: JSON = try? JSON(data: data) {
//            let decoder = JSONDecoder()
//
//            for tuple in json {
//                do {
//                    // iterate to next post if no valid data found
//                    guard let post_data = try decoder.decode([VideoPost].self, from: tuple.1.rawData()) else {
//                        continue
//                    }
//
//                    for videoPost in post_data {
//                        if videoPostsUnsorted[videoPost.dateShort] != nil {
//                            videoPostsUnsorted[videoPost.dateShort]!.append(videoPost)
//                        } else {
//                            videoPostsUnsorted[videoPost.dateShort] = [videoPost]
//                        }
//                    }
//                    // sort videos
//                    for videos in videoPostsUnsorted {
//                        let videosSorted = videos.value.sorted(by: { $0.datePosted > $1.datePosted })
//                        // overwrite old array
//                        videoPostsUnsorted[videos.key] = videosSorted
//                    }
//
//                    // sort dates
//                    let sortedKeys = Array(videoPostsUnsorted.keys).sorted(by: >)
//                    for key in sortedKeys {
//                        let tuple = (key, videoPostsUnsorted[key]!)
//                        videoPostsSorted.append(tuple)
//                    }
//                    //            }
//                    completion(videoPostsSorted)
//                } catch  {
//                    print("error trying to convert data to JSON")
//                    return
//                }
//            }
//        }
//        task.resume()
            
            
            
            
//        Alamofire.request(LOB_ROOT_URL + "/new/\(sport)").responseJSON { response in
//            if let data:Data = response.data, let json: JSON = try? JSON(data: data) {
//                let decoder = JSONDecoder()
//
//                for tuple in json {
//                    // iterate to next post if no valid data found
//                    guard let post_data = try? decoder.decode([VideoPost].self, from: tuple.1.rawData()) else {
//                        continue
//                    }
//
//                    for videoPost in post_data {
//                        if videoPostsUnsorted[videoPost.dateShort] != nil {
//                            videoPostsUnsorted[videoPost.dateShort]!.append(videoPost)
//                        } else {
//                            videoPostsUnsorted[videoPost.dateShort] = [videoPost]
//                        }
//                    }
//                }
//                // sort videos
//                for videos in videoPostsUnsorted {
//                    let videosSorted = videos.value.sorted(by: { $0.datePosted > $1.datePosted })
//                    // overwrite old array
//                    videoPostsUnsorted[videos.key] = videosSorted
//                }
//
//                // sort dates
//                let sortedKeys = Array(videoPostsUnsorted.keys).sorted(by: >)
//                for key in sortedKeys {
//                    let tuple = (key, videoPostsUnsorted[key]!)
//                    videoPostsSorted.append(tuple)
//                }
//            }
//            completion(videoPostsSorted)
//        }
    }
    
    // gets sport data from property list
    private func getSportsData() {
        if let path = Bundle.main.path(forResource: "Sports", ofType: "plist") {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                let decoder = PropertyListDecoder()
                do {
                    self.sportsData = try decoder.decode([String:Sport].self, from: data)
                } catch {
                    print(error)
                }
            }
        }
    }
}
