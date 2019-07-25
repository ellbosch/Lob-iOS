//
//  UnitTesting.swift
//  TheLobAppTests
//
//  Created by Elliot Boschwitz on 4/27/19.
//  Copyright © 2019 Elliot Boschwitz. All rights reserved.
//

import XCTest
@testable import Lob

class UnitTesting: XCTestCase {
    // MARK - Contants for unit tests
    struct constant {
        static let videoPostValid = VideoPost(id: "0", title: "Test", subreddit: "nba", datePostedRaw: "Wed, 24 Jul 2019 23:48:41 GMT", author: "user", redditScore: 5, redditCommentsUrlRaw: "https://reddit.com/r/baseball/comments/ch2qs2", urlRaw: "https://streamable.com/y3on6", mp4UrlRaw: "https://cdn-b-east.streamable.com/video/mp4/0shx7.mp4?token=GDCxhvl0HfI8ZGVF-aBnWQ&expires=1564025520", thumbnailUrlRaw: "https://cdn-b-east.streamable.com/image/0shx7_first.jpg?token=m_BGt9EyRuIE-jvwctqwzg&expires=1564025520", height: 5, width: 9, hotScore: 100.5)
    }

    override func setUp() {
        
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - Tests valid VideoPost class
    func testValidVideoPost() {
        let videoPost = constant.videoPostValid
        XCTAssertNotNil(videoPost.getDatePostedLong())
        XCTAssertNotNil(videoPost.getDatePostedShort())
        XCTAssertNotNil(videoPost.getSport())
        XCTAssertNotNil(videoPost.hotScore)
    }
    
    // MARK: - Tests edge cases for datetime
    func testVideoPostDate() {
        var videoPost = constant.videoPostValid
        
        // remove day of week from date
        videoPost.datePostedRaw = "24 Jul 2019 23:48:41 GMT"
        XCTAssertNil(videoPost.getDatePostedLong())
        XCTAssertNil(videoPost.getDatePostedShort())
        
        // remove timezone
        videoPost.datePostedRaw = "Wed, 24 Jul 2019 23:48:41"
        XCTAssertNil(videoPost.getDatePostedLong())
        XCTAssertNil(videoPost.getDatePostedShort())
    }
    
    // MARK - Tests invalid sport in VideoPost class
    func testVideoPostInvalidSport() {
        var videoPost = constant.videoPostValid
        
        videoPost.subreddit = "asdoifja"
        XCTAssertNil(videoPost.getSport())
    }

    // MARK: - DataProvider helper call
//    func testBuildUrl() {
//        let url = DataProvider.shared.buildURL(nil)
//        print(url)
//    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
