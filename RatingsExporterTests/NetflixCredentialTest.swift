//
//  NetflixCredentialTest.swift
//  RatingsExporterTests
//
//  Created by Jason Beck on 12/26/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import XCTest
@testable import RatingsExporter

class NetflixCredentialTest: XCTestCase {
    
    struct Values {
        static let NetflixIdValue = "FAKE_NETFLIX_ID_VALUE"
        static let SecureNetflicIDValue = "FAKE_SECURE_NETFLIX_ID_VALUE"
    }

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    //Generates valid cookies for testing
    func generateValidCookies() -> [HTTPCookie] {
        let cookieNetflixIDProps: [HTTPCookiePropertyKey: Any] = [
            .path: "/",
            .name: NetflixCredential.RequiredIDs.Cookie.netflixID.rawValue,
            .value: Values.NetflixIdValue,
            .domain: "test"
        ]
        let cookieSecureNetflixIDProps: [HTTPCookiePropertyKey: Any] = [
            .path: "/",
            .name: NetflixCredential.RequiredIDs.Cookie.secureNetflixID.rawValue,
            .value: Values.SecureNetflicIDValue,
            .domain: "test"
        ]
        
        var cookies: [HTTPCookie] = []

        cookies.append(HTTPCookie(properties: cookieNetflixIDProps)!)
        cookies.append(HTTPCookie(properties: cookieSecureNetflixIDProps)!)
        
        return cookies
    }
    
    //Generate invalid cookies for testing
    func generateInvalidCookies() -> [HTTPCookie] {
        let cookieNetflixIDProps: [HTTPCookiePropertyKey: Any] = [
            .path: "/",
            .name: "NotValidName",
            .value: Values.NetflixIdValue,
            .domain: "test"
        ]
        let cookieSecureNetflixIDProps: [HTTPCookiePropertyKey: Any] = [
            .path: "/",
            .name: "StillNotValidName",
            .value: Values.SecureNetflicIDValue,
            .domain: "test"
        ]
        
        var cookies: [HTTPCookie] = []
        
        cookies.append(HTTPCookie(properties: cookieNetflixIDProps)!)
        cookies.append(HTTPCookie(properties: cookieSecureNetflixIDProps)!)
        
        return cookies
    }

    func testInitWithCookies() {
        //given
        let cookies = generateValidCookies()
        
        //then
        XCTAssertNotNil(NetflixCredential(from: cookies))
    }
    
    func testInitWithInvalidCookiesNil() {
        //given
        let cookies = generateInvalidCookies()
        
        //then
        XCTAssertNil(NetflixCredential(from: cookies))
    }
    
    func testValueInit() {
        //given
        let credential = NetflixCredential(netflixID: Values.NetflixIdValue, secureNetflixID: Values.SecureNetflicIDValue)
        
        //then
        XCTAssertEqual(credential, NetflixCredential(netflixID: Values.NetflixIdValue, secureNetflixID: Values.SecureNetflicIDValue))
    }

    func testInitNil() {
        //given
        let credential = NetflixCredential()
        
        //then
        XCTAssertNil(credential.netflixID)
        XCTAssertNil(credential.secureNetflixID)
    }
    
    func testGetListOfCredentials() {
        //given
        let credential = NetflixCredential(netflixID: Values.NetflixIdValue, secureNetflixID: Values.SecureNetflicIDValue)
        
        //when
        let storageItems = credential.getListOfCredentialItemsToStore()
        
        //then
        XCTAssertEqual(storageItems.count, 2) //Assert we have two storage items
        
        for credential in storageItems {
            if !(credential.key.elementsEqual(NetflixCredential.RequiredIDs.Credential.netflixID.rawValue) ||
                credential.key.elementsEqual(NetflixCredential.RequiredIDs.Credential.secureNetflixID.rawValue)) {
                XCTFail("Unexpected credential name: \(credential.key)")
            }
            XCTAssertNotNil(credential.value)
        }
    }
    
    func testRestoreFromStorageItems() {
        //given
        let restoredNetflixCredential = NetflixCredential()
        let expectedNetflixCredential = NetflixCredential(netflixID: Values.NetflixIdValue, secureNetflixID: Values.SecureNetflicIDValue)
        var storageItems: [UserCredentialStorageItem] = []
        
        let netflixID = UserCredentialStorageItem(name: NetflixCredential.RequiredIDs.Credential.netflixID.rawValue, value: Values.NetflixIdValue)
        storageItems.append(netflixID)
        
        let secureNetflixID = UserCredentialStorageItem(name: NetflixCredential.RequiredIDs.Credential.secureNetflixID.rawValue, value: Values.SecureNetflicIDValue)
        storageItems.append(secureNetflixID)
        
        //when
        restoredNetflixCredential.restoreFromStorageItems(storageItems)
        
        //then
        XCTAssertEqual(restoredNetflixCredential, expectedNetflixCredential)
    }
}
