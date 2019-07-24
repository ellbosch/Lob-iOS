//
//  DataProvider.swift
//  The Lob
//
//  Created by Elliot Boschwitz on 5/4/19.
//  Copyright © 2019 Elliot Boschwitz. All rights reserved.
//

import Foundation
import UIKit


// MARK: - Network singleton layer
class DataProvider {
    
    static let shared = DataProvider()
    
    private let LOB_ROOT_URL = "https://www.lob.tv"
    
    public var sportsData: [String:Sport] = [:]
    
    // MARK: - DataProviderError enum
    enum DataProviderError: String, Error {
        case missingUrl = "Error: no URL found."
        case requestFailed = "Error: API call failed."
        case missingData = "Error: no data found."
        case jsonDecodeError = "Error: JSON couldn't be decoded for network call."
    }

    // MARK: - When DataProvider class is initialized, load sport data
    private init() {
        self.getSportsData()
    }
    
    // MARK: - API to FeedVC
    public func getVideoPosts(sport: Sport?, success: (([(Date, [VideoPost])]) -> Void)? = nil, fail: ((DataProviderError) -> Void)? = nil)  {
        guard let urlRequest = buildURL(from: sport) else {
            fail?(DataProviderError.missingUrl)
            return
        }
        makeRequest(urlRequest: urlRequest, sport: sport, success: success, fail: fail)
    }
    
    // MARK: - Request call.
    private func makeRequest(urlRequest: URL, sport: Sport? = nil, success: (([(Date, [VideoPost])]) -> Void)? = nil, fail: ((DataProviderError) -> Void)? = nil) {
        let task = URLSession(configuration: .default).dataTask(with: urlRequest) { (data, response, error) in
            // make sure no error was returned
            guard error == nil else {
                print(error!)
                fail?(DataProviderError.requestFailed)
                return
            }
            // make sure we got valid response data
            guard let responseData: Data = data else {
                fail?(DataProviderError.missingData)
                return
            }
            
            do {
                let videoPosts = try self.parseJSON(for: responseData, sport: sport)
                let videoPostsSorted = self.videoPostsSorted(videoPosts, sortKey: { $0.hotScore > $1.hotScore })
                
                // request was successful
                success?(videoPostsSorted)
            } catch {
                fail?(DataProviderError.jsonDecodeError)
            }
        }
        task.resume()
    }
    
    // MARK: - Builds URL for get requests depending on whether we have nil sport
    private func buildURL(from sport: Sport?) -> URL? {
        guard let sport = sport else { return URL(string: LOB_ROOT_URL + "/hot_posts") }
        return URL(string: LOB_ROOT_URL + "/new/\(sport.subreddit)")
    }
    
    // MARK: - Parses JSON given a particular sport
    private func parseJSON(for responseData: Data, sport: Sport?) throws -> [VideoPost] {
        let decoder = JSONDecoder()
        do {
            if sport == nil {
                // decode requests for hot posts
                guard let postDataPerSport = try decoder.decode([String:[String:[VideoPost]]].self, from: responseData)["results"] else {
                    throw DataProviderError.jsonDecodeError
                }
                
                // extract videopost data and put in dictionary by date
                var videoPosts: [VideoPost] = []
                for postData in postDataPerSport.values {
                    videoPosts = videoPosts + postData
                }
                return videoPosts
            } else {
                // decode request for anything else {
                guard let videoPosts: [VideoPost] = try decoder.decode([String:[VideoPost]].self, from: responseData)["results"] else {
                    throw DataProviderError.jsonDecodeError
                }
                return videoPosts
            }
        } catch {
            print(error)
            throw DataProviderError.jsonDecodeError
        }
    }
    
    // MARK: - Sorts video posts by specified sort key
    private func videoPostsSorted(_ videoPosts: [VideoPost], sortKey getter: (VideoPost, VideoPost) -> Bool) -> [(Date, [VideoPost])] {
        var videoPostsByDate: [Date: [VideoPost]] = [:]
        var videoPostsSorted: [(Date, [VideoPost])] = []
        
        for videoPost in videoPosts {
            if videoPostsByDate[videoPost.dateShort] != nil {
                videoPostsByDate[videoPost.dateShort]?.append(videoPost)
            } else {
                videoPostsByDate[videoPost.dateShort] = [videoPost]
            }
        }
        // sort videos
        for videos in videoPostsByDate {
            let videosSorted = videos.value.sorted(by: getter)
            // overwrite old array
            videoPostsByDate[videos.key] = videosSorted
        }
        
        // sort dates
        let sortedKeys = Array(videoPostsByDate.keys).sorted(by: >)
        for key in sortedKeys {
            let tuple = (key, videoPostsByDate[key]!)
            videoPostsSorted.append(tuple)
        }
        
        return videoPostsSorted
    }
    
    // MARK: - Gets sport data from property list
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
