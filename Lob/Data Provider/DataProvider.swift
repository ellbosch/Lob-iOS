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
    
    private let LOB_ROOT_URL = "https://www.lob.tv/api/v1"
    
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
    public func getVideoPosts(sport: Sport?, page: Int = 1, success: (([(Date, [VideoPost])]) -> Void)? = nil, fail: ((DataProviderError) -> Void)? = nil)  {
        guard let urlRequest = buildURL(from: sport, page: page) else {
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
                let postsResponse = try self.parseJSON(for: responseData, sport: sport)
                let postsByDate = postsResponse.reduce(into: [Date:[VideoPost]](), { (postsByDate, post) in
                    if let dateShort = post.getDatePostedShort() {
                        if postsByDate[dateShort] == nil { postsByDate[dateShort] = [post] }
                        else { postsByDate[dateShort]?.append(post) }
                    }
                })
                var postsTuples = postsByDate.map( { ($0.key, $0.value) })      // gives us array of tuples to be read by table view
                postsTuples.sort(by: { $0.0 > $1.0 })

                success?(postsTuples)
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
    public func buildURL(from sport: Sport?, page: Int) -> URL? {
        guard let sport = sport else { return URL(string: LOB_ROOT_URL + "/posts?sort=trending") }
        return URL(string: LOB_ROOT_URL + "/posts?channel=\(sport.subreddit)&page=\(page)")
    }
    
    // MARK: - Parses JSON given a particular sport
    private func parseJSON(for responseData: Data, sport: Sport?) throws -> [VideoPost] {
        let decoder = JSONDecoder()
        do {
            // decode request for anything else {
            guard let videoPosts: [VideoPost] = try decoder.decode([String:[VideoPost]].self, from: responseData)["results"] else {
                throw DataProviderError.jsonDecodeError
            }
            return videoPosts
        } catch {
            print(error)
            throw DataProviderError.jsonDecodeError
        }
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
