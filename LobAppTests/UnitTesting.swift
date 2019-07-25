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

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - Tests VideoPost class
    func testVideoPostClass() {
        let videoPost = VideoPost(id: "0", title: "Test", subreddit: "nba", datePostedRaw: "Wed, 24 Jul 2019 23:48:41 GMT", author: "user", redditScore: 5, redditCommentsUrlRaw: "https://reddit.com/r/baseball/comments/ch2qs2", urlRaw: "https://streamable.com/y3on6", mp4UrlRaw: "https://cdn-b-east.streamable.com/video/mp4/0shx7.mp4?token=GDCxhvl0HfI8ZGVF-aBnWQ&expires=1564025520", thumbnailUrlRaw: "https://cdn-b-east.streamable.com/image/0shx7_first.jpg?token=m_BGt9EyRuIE-jvwctqwzg&expires=1564025520", height: 5, width: 9, hotScore: 100.5)
        
        // test all valid cases
        XCTAssertNotNil(videoPost.getDatePostedLong())
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
