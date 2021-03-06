//
//  UserCredentialStoreTests.swift
//  RatingsExporterTests
//
//  Created by Jason Beck on 12/18/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import XCTest
@testable import RatingsExporter


//Create a test credential that conforms to the storage protocol for testing
class TestCredental: UserCredentialStorageProtocol, Equatable {
	
	var credential1: String?
	var credential2: String?
	
	struct StorageName {
		static let testFirstItem = "testFirstItem"
		static let testSecondItem = "TestSecondItem"
	}
	
	init(credential1: String? = nil, credential2: String? = nil) {
		self.credential1 = credential1
		self.credential2 = credential2
	}
	
	required init() {
		credential1 = nil
		credential2 = nil
	}
	
	static func == (lhs: TestCredental, rhs: TestCredental) -> Bool {
		return (lhs.credential1 == rhs.credential1) && (lhs.credential2 == rhs.credential2)
	}
	
	func getListOfCredentialItemsToStore() -> [UserCredentialStorageItem] {
		var returnCredentials: [UserCredentialStorageItem] = []
		
		let testCredentialItem1 = UserCredentialStorageItem(key: StorageName.testFirstItem, value: credential1)
		returnCredentials.append(testCredentialItem1)
		let testCredentialItem2 = UserCredentialStorageItem(key: StorageName.testSecondItem, value: credential2)
		returnCredentials.append(testCredentialItem2)
		
		return returnCredentials
	}
	
	func restoreFromStorageItems(_ storageItems: [UserCredentialStorageItem]) {
		for credential in storageItems {
			if credential.key.elementsEqual(StorageName.testFirstItem) {
				self.credential1 = credential.value
			} else if credential.key.elementsEqual(StorageName.testSecondItem) {
				self.credential2 = credential.value
			}
		}
	}
}

class UserCredentialStoreTests: XCTestCase {
	
	override func setUp() {
		clearKeychain()
		super.setUp()
	}
	
	override func tearDown() {
		super.tearDown()
	}
	
	func clearKeychain() {
		
		//Clear out keychain
		var queryDict: [CFString: CFString] = [
			kSecClass: kSecClassGenericPassword,
			kSecAttrAccount: TestCredental.StorageName.testFirstItem as CFString]
		
		var status = SecItemDelete(queryDict as CFDictionary)
		guard status == noErr || status == errSecItemNotFound else {
			XCTFail("Unable to clear keychain with error: \(status)")
			return
		}
		
		queryDict[kSecAttrAccount] = TestCredental.StorageName.testSecondItem as CFString
		status = SecItemDelete(queryDict as CFDictionary)
		guard status == noErr || status == errSecItemNotFound else {
			XCTFail("Unable to clear keychain with error: \(status)")
			return
		}
	}
	
	func testStoreAllNilThrowsInvalidAttribute() {
		//given
		let testNilCredential = TestCredental(credential1: nil, credential2: nil)
		
		//then
		XCTAssertThrowsError(try UserCredentialStore.storeCredential(testNilCredential)) { (Error) in
			XCTAssertEqual(Error as! UserCredentialStore.UserCredentialStoreError, UserCredentialStore.UserCredentialStoreError.invalidItemAttributes)
		}
	}
	
	func testStoreOneNilThrowsInvalidAttribute() {
		let testOneNilCredential = TestCredental(credential1: "testCredential", credential2: nil)
		
		XCTAssertThrowsError(try UserCredentialStore.storeCredential(testOneNilCredential)) { (Error) in
			XCTAssertEqual(Error as! UserCredentialStore.UserCredentialStoreError, UserCredentialStore.UserCredentialStoreError.invalidItemAttributes)
		}
	}
	
	func testRestoreItemThrowsItemNotFound() {
		XCTAssertThrowsError(try UserCredentialStore.restoreCredential(forType: TestCredental.self)) { (Error) in
			XCTAssertEqual(Error as! UserCredentialStore.UserCredentialStoreError, UserCredentialStore.UserCredentialStoreError.itemNotFound)
		}
	}
	
	func testStoreCredential() {
		let testStoreCredential = TestCredental(credential1: "textC1", credential2: "testC2")
		
		XCTAssertNoThrow(try UserCredentialStore.storeCredential(testStoreCredential))
	}
	
	func testRestoreCredential() {
		//given
		var testRestoreCredential: TestCredental!
		let expectedCredential = TestCredental(credential1: "testC1", credential2: "testC2")
		XCTAssertNoThrow(try UserCredentialStore.storeCredential(expectedCredential))
		
		//when
		XCTAssertNoThrow(testRestoreCredential = try UserCredentialStore.restoreCredential(forType: TestCredental.self))
		
		//then
		XCTAssertEqual(testRestoreCredential, expectedCredential)
	}
	
	func testUpdateCredential() {
		//given
		let testUpdateCredential = TestCredental(credential1: "testC", credential2: "testC")
		var restoredUpdatedCredential: TestCredental!
		XCTAssertNoThrow(try UserCredentialStore.storeCredential(testUpdateCredential))
		
		//when
		testUpdateCredential.credential1 = "testC1"
		testUpdateCredential.credential2 = "testC2"
		XCTAssertNoThrow(try UserCredentialStore.storeCredential(testUpdateCredential))
		
		//then
		XCTAssertNoThrow(restoredUpdatedCredential = try UserCredentialStore.restoreCredential(forType: TestCredental.self))
		XCTAssertEqual(testUpdateCredential, restoredUpdatedCredential)
	}
	
	func testCredentialDoesntExist() {
		//given
		var credentialStored = true
		
		//when
		XCTAssertNoThrow( credentialStored = try UserCredentialStore.isCredentialStored(forType: TestCredental.self))
		
		//then
		XCTAssert(credentialStored == false)
	}
	
	func testCredentialDoesExist() {
		//given
		var credentialFound = false
		let testCredential = TestCredental(credential1: "testC1", credential2: "testC2")
		//store the credential
		XCTAssertNoThrow(try UserCredentialStore.storeCredential(testCredential))
		
		//when
		XCTAssertNoThrow(credentialFound = try UserCredentialStore.isCredentialStored(forType: TestCredental.self))
		
		//then
		XCTAssert(credentialFound == true)
	}
	
	func testClearCredential() {
		//given
		let testClearCredential = TestCredental(credential1: "testC1", credential2: "testC2")
		var testRestoreClearedCredential: TestCredental! //We never read this variable. We only care if it threw or not.
		
		//when
		XCTAssertNoThrow(try UserCredentialStore.storeCredential(testClearCredential))
		XCTAssertNoThrow(try UserCredentialStore.clearCredential(testClearCredential))
		
		//then
		XCTAssertThrowsError(testRestoreClearedCredential = try UserCredentialStore.restoreCredential(forType: TestCredental.self)) { (Error) in
			XCTAssertEqual(Error as! UserCredentialStore.UserCredentialStoreError, UserCredentialStore.UserCredentialStoreError.itemNotFound)
			
			//Satisfy the compiler warning for not being read.
			XCTAssertNil(testRestoreClearedCredential)
		}
	}
	
	func testClearCredentialByType() {
		//given
		let testClearCredential = TestCredental(credential1: "testC1", credential2: "testC2")
		var testRestoreClearedCredential: TestCredental! //We never read this variable. We only care if it threw or not.
		
		//when
		XCTAssertNoThrow(try UserCredentialStore.storeCredential(testClearCredential))
		XCTAssertNoThrow(try UserCredentialStore.clearCredential(forType: TestCredental.self))
		
		//then
		XCTAssertThrowsError(testRestoreClearedCredential = try UserCredentialStore.restoreCredential(forType: TestCredental.self)) { (Error) in
			XCTAssertEqual(Error as! UserCredentialStore.UserCredentialStoreError, UserCredentialStore.UserCredentialStoreError.itemNotFound)
			
			//Satisfy the compiler warning for not being read.
			XCTAssertNil(testRestoreClearedCredential)
		}
	}
}
