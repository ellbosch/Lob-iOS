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
        case noHotScoreError = "Error: no hot score was determined."
        case noDatetimeError = "Error: no datetime was determined."
        case uknownDataProcessingError = "Error: occured either with JSON decode or sort." // THIS SHOULDN'T HAPPEN
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
                let videoPostsSorted = try self.getVideoPostsSorted(videoPosts, for: sport)
                
                // request was successful
                success?(videoPostsSorted)
            } catch {
                guard let dataProviderError = error as? DataProviderError else {
                    fail?(DataProviderError.uknownDataProcessingError)
                    return
                }
                fail?(dataProviderError)
            }
        }
        task.resume()
    }
    
    // MARK: - Builds URL for get requests depending on whether we have nil sport
    public func buildURL(from sport: Sport?) -> URL? {
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
    private func getVideoPostsSorted(_ videoPosts: [VideoPost], for sport: Sport?) throws -> [(Date, [VideoPost])] {
        var videoPostsByDate: [Date: [VideoPost]] = [:]
        var videoPostsSorted: [(Date, [VideoPost])] = []
        
        // determine sort key
        let getter = determineSortKey(for: sport)
        
        for videoPost in videoPosts {
            if let dateShort = videoPost.getDatePostedShort() {
                if videoPostsByDate[dateShort] != nil {
                    videoPostsByDate[dateShort]?.append(videoPost)
                } else {
                    videoPostsByDate[dateShort] = [videoPost]
                }
            }
        }
        // sort videos
        for videos in videoPostsByDate {
            do {
                let videosSorted = try videos.value.sorted(by: getter)
                // overwrite old array
                videoPostsByDate[videos.key] = videosSorted

                // sort dates
                let sortedKeys = Array(videoPostsByDate.keys).sorted(by: >)
                for key in sortedKeys {
                    let tuple = (key, videoPostsByDate[key]!)
                    videoPostsSorted.append(tuple)
                }
            } catch { throw error }
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
    
    // MARK: - Determines sort key given a sport's VC
    private func determineSortKey(for sport: Sport?) -> (VideoPost, VideoPost) throws -> Bool {
        if sport != nil {
            // sort by date if view is for specific sport
            return {
                if let datePosted0 = $0.getDatePostedLong(), let datePosted1 = $1.getDatePostedLong() {
                    return datePosted0 > datePosted1
                } else {
                    throw DataProviderError.noDatetimeError
                }
            }
        } else {
            // sort by hot score if home view
            return {
                if let hotScore0 = $0.hotScore, let hotScore1 = $1.hotScore {
                    return hotScore0 > hotScore1
                } else {
                    throw DataProviderError.noHotScoreError
                }
            }
        }
    }
}
