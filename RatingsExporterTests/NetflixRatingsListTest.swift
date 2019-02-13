//
//  NetflixRatingsList.swift
//  RatingsExporterTests
//
//  Created by Jason Beck on 2/7/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

import XCTest
@testable import RatingsExporter

class NetflixRatingsListTest: XCTestCase {
	
	private struct TestData {
		static let validJSONRatingsString = """
							{"codeName":"S-Icarus-6.Demitasse-5","ratingItems":[{"ratingType":"star","title":"Prisoners","movieID":70273235,"yourRating":4.0,"intRating":40,"date":"1/4/15","timestamp":1420420307158,"comparableDate":1420420307},{"ratingType":"star","title":"Enough Said","movieID":70288428,"yourRating":3.0,"intRating":30,"date":"1/4/15","timestamp":1420420242591,"comparableDate":1420420242},{"ratingType":"star","title":"Nebraska","movieID":70275595,"yourRating":3.0,"intRating":30,"date":"1/4/15","timestamp":1420420222036,"comparableDate":1420420222}],"totalRatings":2188,"page":3,"size":100,"trkid":200250784,"tz":"CST"}
							"""
		
		static let invalidJSONRatingsString = """
							{"codeName":"S-Icarus-6.Demitasse-5","ratingItems":[{"ratingType":"star","title":"Prisoners","movieID":70273235,"yourRating":4.0,"intRating":40,"date":"1/4/15","timestamp":1420420307158,"comparableDate":1420420307},{"ratingType":"star","title":"Enough Said","movieID":70288428,"yourRating":3.0,"intRating":30,"date":"1/4/15","timestamp":1420420242591,"comparableDate":1420420242},{"ratingType":"star","title":"Nebraska","movieID":70275595,"yourRating":3.0,"intRating":30,"date":"1/4/15","timestamp":1420420222036,"comparableDate":1420420222}]}
							"""
	}

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
		super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
    }

	func testJsonInit() {
		//given
		guard let JSONData = TestData.validJSONRatingsString.data(using: .utf8),
			let JSONObject = try? JSONSerialization.jsonObject(with: JSONData, options:[]) as! [String: Any] else {
				XCTFail()
				return
		}
		
		let firstRating = NetflixRating(comparableDate: Date(timeIntervalSince1970: 1420420307), date: "1/4/15", intRating: 40, movieID: 70273235, ratingType: .star, timestamp: 1420420307158, title: "Prisoners", yourRating: 4.0)
		let secondRating = NetflixRating(comparableDate: Date(timeIntervalSince1970: 1420420242), date: "1/4/15", intRating: 30, movieID: 70288428, ratingType: .star, timestamp: 1420420242591, title: "Enough Said", yourRating: 3.0)
		let thirdRating = NetflixRating(comparableDate: Date(timeIntervalSince1970: 1420420222), date: "1/4/15", intRating: 30, movieID: 70275595, ratingType: .star, timestamp: 1420420222036, title: "Nebraska", yourRating: 3.0)
		
		//when
		let ratingsList = NetflixRatingsList(json: JSONObject)
		
		//then
		XCTAssertNotNil(ratingsList)
		XCTAssertEqual(ratingsList!.codeName, "S-Icarus-6.Demitasse-5")
		XCTAssertEqual(ratingsList!.numberOfRequestedItems, 100)
		XCTAssertEqual(ratingsList!.page, 3)
		XCTAssertEqual(ratingsList!.timeZoneAbbrev, "CST")
		XCTAssertEqual(ratingsList!.totalRatings, 2188)
		XCTAssertEqual(ratingsList!.trackId, 200250784)
		XCTAssertEqual(ratingsList!.ratingItems.count, 3)
		
		XCTAssertEqual(ratingsList!.ratingItems[0], firstRating)
		XCTAssertEqual(ratingsList!.ratingItems[1], secondRating)
		XCTAssertEqual(ratingsList!.ratingItems[2], thirdRating)
	}
	
	func testInvlaidJSONInit() {
		//given
		guard let JSONData = TestData.invalidJSONRatingsString.data(using: .utf8),
			let JSONObject = try? JSONSerialization.jsonObject(with: JSONData, options:[]) as! [String: Any] else {
				XCTFail()
				return
		}
		
		//when
		let ratingsList = NetflixRatingsList(json: JSONObject)
		
		//then
		XCTAssertNil(ratingsList)
	}
	
	func testInit() {
		//given
		let ratings = [
			NetflixRating(comparableDate: Date(timeIntervalSince1970: 0), date: "1/1/1970", intRating: 10, movieID: 00010101, ratingType: .star, timestamp: 0, title: "rating1", yourRating: 1.0),
			NetflixRating(comparableDate: Date(timeIntervalSince1970: 0), date: "1/1/1970", intRating: 20, movieID: 00010101, ratingType: .star, timestamp: 0, title: "rating2", yourRating: 2.0),
			NetflixRating(comparableDate: Date(timeIntervalSince1970: 0), date: "1/1/1970", intRating: 30, movieID: 00010103, ratingType: .star, timestamp: 0, title: "rating3", yourRating: 3.0)
		]
		
		
		//when
		let ratingList = NetflixRatingsList(codeName: "CODENAME", ratingItems: ratings, totalRatings: 3, page: 1, numberOfRequestedItems: 100, trackId: 1, timeZoneAbbrev: "CST")
		
		//then
		XCTAssertEqual(ratingList.codeName, "CODENAME")
		XCTAssertEqual(ratingList.ratingItems, ratings)
		XCTAssertEqual(ratingList.totalRatings, 3)
		XCTAssertEqual(ratingList.page, 1)
		XCTAssertEqual(ratingList.numberOfRequestedItems, 100)
		XCTAssertEqual(ratingList.trackId, 1)
		XCTAssertEqual(ratingList.timeZoneAbbrev, "CST")
	}
}
