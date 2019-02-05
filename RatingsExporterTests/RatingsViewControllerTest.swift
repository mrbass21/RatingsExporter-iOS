//
//  NetflixRatingsTest.swift
//  RatingsExporterTests
//
//  Created by Jason Beck on 2/4/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

import XCTest
@testable import RatingsExporter

class RatingsViewControllerTest: XCTestCase {
	
	var controllerUnderTest: RatingsViewController = (UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Common.Identifiers.Storyboard.RatingsViewController) as! RatingsViewController)
	var bundle: Bundle = Bundle.init(for: NetflixLoginViewControllerTests.classForCoder())
	
	private var hasLoaded = false

    override func setUp() {
		super.setUp()
		if !hasLoaded {
			_ = controllerUnderTest.view
		}
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
