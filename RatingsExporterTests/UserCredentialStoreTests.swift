//
//  UserCredentialStoreTests.swift
//  RatingsExporterTests
//
//  Created by Jason Beck on 12/18/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import XCTest
@testable import RatingsExporter

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
            kSecAttrAccount: "TestNetflixID" as CFString]
        
        var status = SecItemDelete(queryDict as CFDictionary)
        guard status == noErr || status == errSecItemNotFound else {
            XCTFail("Unable to clear keychain with error: \(status)")
            return
        }
        
        queryDict[kSecAttrAccount] = "TestNetflixSecretID" as CFString
        status = SecItemDelete(queryDict as CFDictionary)
        guard status == noErr || status == errSecItemNotFound else {
            XCTFail("Unable to clear keychain with error: \(status)")
            return
        }
    }
    
    func testInitStorageItemMinimum() {
        //given
        let credential = CredentialStorageItem(name: "TestCredential")
        
        //then
        let expectedCredential = CredentialStorageItem(name: "TestCredential", value: nil, valueType: .Cookie, description: nil)
        XCTAssertEqual(credential, expectedCredential)
    }

    func testStoreAndRestoreNetflixCredential() {
        //Store Credentials
        //given
        let storeCredential = NetflixCredential(netflixID: "TestNetflixID", secureNetflixID: "TestNetflixSecretID")
        
        //then
        do {
            try UserCredentialStore.storeCredential(storeCredential)
        } catch {
            XCTFail("Error encountered storing credential: \(storeCredential) with error: \(error.localizedDescription)")
        }
        
        //Restore Credentials
        var restoredCredential = NetflixCredential()
        do {
            try restoredCredential = UserCredentialStore.restoreCredential(for: restoredCredential) as! NetflixCredential
        } catch {
            XCTFail("Error encountered restoring credential: \(restoredCredential) with error:\(error.localizedDescription)")
        }
        
        XCTAssertEqual(storeCredential, restoredCredential)
    }
}
