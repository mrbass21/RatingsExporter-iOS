//
//  ShaktiTest.swift
//  RatingsExporterTests
//
//  Created by Jason Beck on 11/29/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

import XCTest
@testable import RatingsExporter

class ShaktiTest: XCTestCase {
    
    var bundle: Bundle = Bundle.init(for: ShaktiTest.classForCoder())
    
    enum Resources: String {
        case validJSON = "ShaktiJson"
        case noRootAPIJSON = "ShaktiJsonNoAPIRoot"
        case noVersionJSON = "ShaktiJsonNoVersion"
    }

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testShaktiInitialization() {
        let shaktiJsonURL = bundle.url(forResource: Resources.validJSON.rawValue, withExtension: "json")!
        let shaktiJson = try! Data(contentsOf: shaktiJsonURL)
     
        let decoder = JSONDecoder()
        do {
            let shakti = try decoder.decode(Shakti.self, from: shaktiJson)
            XCTAssertNotNil(shakti)
            XCTAssertEqual(shakti.streamingBaseURL, URL(string: "https://www.netflix.com/api/shakti/v619c00fc"))
        } catch {
            XCTFail("Unable to decode JSON")
        }
    }
    
    func testShaktiMissingRootAPI() {
        let shaktiJsonURL = bundle.url(forResource: Resources.noRootAPIJSON.rawValue, withExtension: "json")!
        let shaktiJson = try! Data(contentsOf: shaktiJsonURL)
        
        let decoder = JSONDecoder()
        do {
            let _ = try decoder.decode(Shakti.self, from: shaktiJson)
            XCTFail("Found API_ROOT when API_ROOT is expected missing!")
        } catch (DecodingError.keyNotFound(let key, _)){
            if key.stringValue != "API_ROOT" {
                XCTFail("Unexpected missing key: \(key.stringValue)")
            }
        } catch {
            XCTFail("Unexpected error when parsing Shakti JSON")
        }
    }
    
    func testShaktiMissingVersion() {
        let shaktiJsonURL = bundle.url(forResource: Resources.noVersionJSON.rawValue, withExtension: "json")!
               let shaktiJson = try! Data(contentsOf: shaktiJsonURL)
               
               let decoder = JSONDecoder()
               do {
                   let _ = try decoder.decode(Shakti.self, from: shaktiJson)
                   XCTFail("Found BUILD_IDENTIFIER when API_ROOT is expected missing!")
               } catch (DecodingError.keyNotFound(let key, _)){
                   if key.stringValue != "BUILD_IDENTIFIER" {
                       XCTFail("Unexpected missing key: \(key.stringValue)")
                   }
               } catch {
                   XCTFail("Unexpected error when parsing Shakti JSON")
               }
    }

}
