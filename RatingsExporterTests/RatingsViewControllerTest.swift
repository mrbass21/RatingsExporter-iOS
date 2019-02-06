//
//  NetflixRatingsTest.swift
//  RatingsExporterTests
//
//  Created by Jason Beck on 2/4/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

import XCTest
@testable import RatingsExporter

class mockNetflixRatingsManager: NetflixRatingsManagerProtocol {
	var fetchMode: NetflixRatingsManager.FetchMode
	
	public weak var delegate: NetflixRatingsManagerDelegate? = nil
	
	var fetcher: RatingsFetcher! {
		get {
			return nil
		}
		
		set {
			return
		}
	}
	
	var totalPages: Int
	var itemsPerPage: Int
	var totalRatings: Int
	
	private var storedItems: [NetflixRating]? = nil
	
	subscript(index: Int) -> NetflixRating? {
		
		guard storedItems == nil, let itemCount = storedItems?.count, index > itemCount else {
			return nil
		}
		
		return storedItems![index]
	}
	
	init(withRatings: [NetflixRating]? = nil, usingFetchMode: NetflixRatingsManager.FetchMode = .sequential) {
		storedItems = withRatings
		fetchMode = usingFetchMode
		totalPages = 0
		itemsPerPage = 0
		totalRatings = 0
	}
	
}

class RatingsViewControllerTest: XCTestCase {
	
	var controllerUnderTest: RatingsViewController = {
		let controller: RatingsViewController = (UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Common.Identifiers.Storyboard.RatingsViewController)) as! RatingsViewController
		
		//We never need a "real" ratings manager to unit test the VC.
		controller.ratingsLists = mockNetflixRatingsManager()
		
		return controller
	}()
	var bundle: Bundle = Bundle.init(for: NetflixLoginViewControllerTests.classForCoder())

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
	
	func testLoadingCellDidDequeue() {
		//given
		let firstItem = IndexPath(row: 0, section: 0)
		
		//when
		let cell = controllerUnderTest.tableView(controllerUnderTest.tableView, cellForRowAt: firstItem)
		
		//then
		XCTAssert(cell.reuseIdentifier == Common.Identifiers.TableViewCell.LoadingRatingCell)
	}
}
