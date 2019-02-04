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
	
	struct TestValues {
		static let netflixIdValue = "FAKE_NETFLIX_ID_VALUE"
		static let secureNetflixIDValue = "FAKE_SECURE_NETFLIX_ID_VALUE"
		static let unknownIDValue = "UNKNOWN_ID_VALUE"
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
			.name: Common.Identifiers.Cookie.netflixID.rawValue,
			.value: TestValues.netflixIdValue,
			.domain: "test"
		]
		let cookieSecureNetflixIDProps: [HTTPCookiePropertyKey: Any] = [
			.path: "/",
			.name: Common.Identifiers.Cookie.secureNetflixID.rawValue,
			.value: TestValues.secureNetflixIDValue,
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
			.name: "NotValidName1",
			.value: TestValues.netflixIdValue,
			.domain: "test"
		]
		let cookieSecureNetflixIDProps: [HTTPCookiePropertyKey: Any] = [
			.path: "/",
			.name: "NotValidName2",
			.value: TestValues.secureNetflixIDValue,
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
		let credential = NetflixCredential(netflixID: TestValues.netflixIdValue, secureNetflixID: TestValues.secureNetflixIDValue)
		
		//then
		XCTAssertEqual(credential, NetflixCredential(netflixID: TestValues.netflixIdValue, secureNetflixID: TestValues.secureNetflixIDValue))
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
		let credential = NetflixCredential(netflixID: TestValues.netflixIdValue, secureNetflixID: TestValues.secureNetflixIDValue)
		
		//when
		let storageItems = credential.getListOfCredentialItemsToStore()
		
		//then
		XCTAssertEqual(storageItems.count, 2) //Assert we have two storage items
		
		for credential in storageItems {
			if !(credential.key == NetflixCredential.RequiredIDs.CredentialItemKeys.netflixID.rawValue ||
				credential.key == NetflixCredential.RequiredIDs.CredentialItemKeys.secureNetflixID.rawValue) {
				XCTFail("Unexpected credential name: \(credential.key)")
			}
			XCTAssertNotNil(credential.value)
		}
	}
	
	func testRestoreFromStorageItems() {
		//given
		let restoredNetflixCredential = NetflixCredential()
		let expectedNetflixCredential = NetflixCredential(netflixID: TestValues.netflixIdValue, secureNetflixID: TestValues.secureNetflixIDValue)
		var storageItems: [UserCredentialStorageItem] = []
		
		let netflixID = UserCredentialStorageItem(key: NetflixCredential.RequiredIDs.CredentialItemKeys.netflixID.rawValue, value: TestValues.netflixIdValue)
		storageItems.append(netflixID)
		
		let secureNetflixID = UserCredentialStorageItem(key: NetflixCredential.RequiredIDs.CredentialItemKeys.secureNetflixID.rawValue, value: TestValues.secureNetflixIDValue)
		storageItems.append(secureNetflixID)
		
		//when
		restoredNetflixCredential.restoreFromStorageItems(storageItems)
		
		//then
		XCTAssertEqual(restoredNetflixCredential, expectedNetflixCredential)
	}
	
	func testTooFewCredentialItems() {
		//given
		let restoredNetflixCredential = NetflixCredential()
		let expectedNetflixCredential = NetflixCredential(netflixID: TestValues.netflixIdValue, secureNetflixID: nil)
		var storageItems: [UserCredentialStorageItem] = []
		
		let netflixID = UserCredentialStorageItem(key: NetflixCredential.RequiredIDs.CredentialItemKeys.netflixID.rawValue, value: TestValues.netflixIdValue, valueType: .Cookie, description: nil)
		storageItems.append(netflixID)
		
		//when
		restoredNetflixCredential.restoreFromStorageItems(storageItems)
		
		//then
		XCTAssertEqual(restoredNetflixCredential, expectedNetflixCredential)
	}
	
	func testUnknownItemAdded() {
		//given
		let restoredNetflixCredential = NetflixCredential()
		let expectedNetflixCredential = NetflixCredential(netflixID: TestValues.netflixIdValue, secureNetflixID: TestValues.secureNetflixIDValue)
		var storageItems: [UserCredentialStorageItem] = []
		
		let netflixIDItem = UserCredentialStorageItem(key: NetflixCredential.RequiredIDs.CredentialItemKeys.netflixID.rawValue, value: TestValues.netflixIdValue, valueType: .Cookie, description: nil)
		storageItems.append(netflixIDItem)
		
		let secureNetflixIDItem = UserCredentialStorageItem(key: NetflixCredential.RequiredIDs.CredentialItemKeys.netflixID.rawValue, value: TestValues.netflixIdValue, valueType: .Cookie, description: nil)
		storageItems.append(secureNetflixIDItem)
		
		let UnknownIDItem = UserCredentialStorageItem(key: "Unknown", value: TestValues.unknownIDValue, valueType: .Cookie, description: nil)
		storageItems.append(UnknownIDItem)
		
		//when
		restoredNetflixCredential.restoreFromStorageItems(storageItems)
		
		//then
		XCTAssertEqual(restoredNetflixCredential, expectedNetflixCredential)
	}
}
