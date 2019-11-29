//
//  String+deencodeHexToUTF8Test.swift
//  RatingsExporterTests
//
//  Created by Jason Beck on 11/29/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

import XCTest

class String_deencodeHexToUTF8Test: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDeencode() {
        let testString = "\\x20\\x2F\\x2A\\x2B\\x3D\\x26\\x3B\\x24\\x27\\x40\\x28\\x3C\\x3E\\x29\\x23\\x3F\\x7C\\x21"
        let expectedResult = " /*+=&;$'@(<>)#?|!"
        
        let convertedString = testString.deencodeHexToUTF8()

        XCTAssertEqual(convertedString, expectedResult)
    }

}
