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
	
	weak var delegate: NetflixRatingsManagerDelegate? = nil
	
	var fetcher: RatingsFetcher! {
		get {
			return nil
		}
		
		set {
			return
		}
	}
	
	var totalPages: Int {
		get {
			return (storedItems?.count ?? 0) / self.itemsPerPage
		}
	}
	var itemsPerPage: Int {
		get {
			return 100
		}
	}
	var totalRatings: Int {
		get {
			return storedItems?.count ?? 0
		}
	}
	
	private var storedItems: [NetflixRating]? = nil
	
	subscript(index: Int) -> NetflixRating? {
		
		guard storedItems != nil, let itemCount = storedItems?.count, index < itemCount else {
			return nil
		}
		
		return storedItems![index]
	}
	
	init(withRatings: [NetflixRating]? = nil, usingFetchMode: NetflixRatingsManager.FetchMode = .sequential) {
		storedItems = withRatings
		fetchMode = usingFetchMode
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
	
	func testRatingCellDidDequeue() {
		//givem
		let indexPath = IndexPath(row: 0, section: 0)
		let rating = NetflixRating(movieID: 5)
		controllerUnderTest.ratingsLists = mockNetflixRatingsManager(withRatings: [rating])
		
		//when
		let cell = controllerUnderTest.tableView(controllerUnderTest.tableView, cellForRowAt: indexPath)
		
		//then
		XCTAssert(cell.reuseIdentifier == Common.Identifiers.TableViewCell.NetflixRatingsCell)
	}
	
	func testDidReloadNewData() {
		//given
		XCTAssert(controllerUnderTest.tableView.numberOfRows(inSection: 0) == 0, "Table view must not contain any data at the start of this test")
		
		let rating = NetflixRating(movieID: 5)
		controllerUnderTest.ratingsLists = mockNetflixRatingsManager(withRatings: [rating])
		
		//when
		XCTAssertNotNil(controllerUnderTest.ratingsLists, "Ratings manager cannot be nil")
		controllerUnderTest.NetflixRatingsManagerDelegate(controllerUnderTest.ratingsLists!, didLoadRatingIndexes: 0...0)
		
		//then
		XCTAssertEqual(controllerUnderTest.tableView.numberOfRows(inSection: 0), 1)
	}
}
