//
//  RatingsFetcherTest.swift
//  RatingsExporterTests
//
//  Created by Jason Beck on 2/13/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

import XCTest
@testable import RatingsExporter

class RatingsFetcherTest: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSessionStateEquatable() {
		//given
		let invalid: RatingsFetcher.SessionState = .invalidated
		let willInvalidate: RatingsFetcher.SessionState = .willInvalidate
		let active: RatingsFetcher.SessionState = .active(nil)
		
		//then
		//Assert truths
		XCTAssertTrue(invalid == .invalidated)
		XCTAssertTrue(willInvalidate == .willInvalidate)
		XCTAssertTrue(active == .active(nil))
		
		//Assert falses
		XCTAssertFalse(invalid == .willInvalidate)
		XCTAssertFalse(invalid == .active(nil))
		XCTAssertFalse(willInvalidate == .active(nil))
		
    }

	func testSomething() {
		//given
		//let credential = NetflixCredential(netflixID: "fakeID", secureNetflixID: "FakeSecureID")
		//let ratingsFetcher = RatingsFetcher(forCredential: credential, with: nil)
		
		//when
		//then
	}
}
