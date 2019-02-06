//
//  NetflixRatingsTest.swift
//  RatingsExporterTests
//
//  Created by Jason Beck on 2/4/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

import XCTest
@testable import RatingsExporter

class mockRatingsFetcher: RatingsFetcherProtocol {
	public var ratings: [NetflixRating]
	
	init() {}
	
	func fetchRatings(page: UInt) {
		<#code#>
	}
}

class RatingsViewControllerTest: XCTestCase {
	
	var controllerUnderTest: RatingsViewController = (UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Common.Identifiers.Storyboard.RatingsViewController) as! RatingsViewController)
	var bundle: Bundle = Bundle.init(for: NetflixLoginViewControllerTests.classForCoder())
	
	private var hasLoaded = false

    override func setUp() {
		super.setUp()
		controllerUnderTest.loadViewIfNeeded()
    }
	
	override func tearDown() {
		super.tearDown()
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}

	func testPrepareForSegue() {
		//given
		let detailVC: RatingsDetailViewController = (UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Common.Identifiers.Storyboard.RatingsDetailViewController) as! RatingsDetailViewController)
		let segue = UIStoryboardSegue(identifier: Common.Identifiers.Segue.MovieDetailsSegue, source: controllerUnderTest, destination: detailVC)
		let rating = NetflixRating()
		
		//when
		controllerUnderTest.prepare(for: segue, sender: rating)
		
		//then
		XCTAssertNotNil(detailVC.movie)
		XCTAssertEqual(rating, detailVC.movie)
	}

	func testPrepareForSegueNilRating() {
		//given
		let detailVC: RatingsDetailViewController = (UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Common.Identifiers.Storyboard.RatingsDetailViewController) as! RatingsDetailViewController)
		let segue = UIStoryboardSegue(identifier: Common.Identifiers.Segue.MovieDetailsSegue, source: controllerUnderTest, destination: detailVC)
		
		//when
		controllerUnderTest.prepare(for: segue, sender: nil)
		
		//then
		XCTAssertNil(detailVC.movie)
	}
}
