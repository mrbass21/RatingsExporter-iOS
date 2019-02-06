//
//  RatingsDetailViewControllerTest.swift
//  RatingsExporterTests
//
//  Created by Jason Beck on 2/6/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

import XCTest
@testable import RatingsExporter

class RatingsDetailViewControllerTest: XCTestCase {

    override func setUp() {
		super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
		super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

	func testInitsWithRating() {
		//given
		let rating = NetflixRating(date: "1/1/2019", intRating: 5,  title: "TestTitle", yourRating: 5.0)
		
		let controller: RatingsDetailViewController = (UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Common.Identifiers.Storyboard.RatingsDetailViewController) as! RatingsDetailViewController)
		
		//when
		controller.movie = rating
		controller.loadViewIfNeeded()
		
		//then
		XCTAssertNotNil(controller.movieTitle.text)
		XCTAssertNotNil(controller.dateRated.text)
		XCTAssertEqual(controller.movieTitle.text!, "TestTitle")
		XCTAssertEqual(controller.dateRated.text!, "1/1/2019")
		XCTAssertEqual(controller.rating.text!, "5")
	}

}
