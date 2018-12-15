//
//  UserCredentialsTest.swift
//  RatingsExporterTests
//
//  Created by Jason Beck on 12/15/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import XCTest
import Security
@testable import RatingsExporter

class UserCredentialsTest: XCTestCase {

    override func setUp() {
        super.setUp()
        clearKeychain()
    }

    override func tearDown() {
        clearKeychain()
        super.tearDown()
    }
    
    //MARK: - Functions used to setup keychain
    func clearKeychain() {
        //Create a query for the entry
        let netflixIDQueryDict: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: UserCredentials.UserCredentialKeys.kUserCredentialNetflixID.rawValue as CFString
        ]
        
        let netflixSecureIDQueryDict: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: UserCredentials.UserCredentialKeys.kUserCredentialNetflixSecureID.rawValue as CFString
        ]
        
        //Delete the item
        let status1 = SecItemDelete(netflixIDQueryDict as CFDictionary)
        let status2 = SecItemDelete(netflixSecureIDQueryDict as CFDictionary)
        
        //Check for errors
        guard status1 == noErr || status1 == errSecItemNotFound else {
            XCTFail("Error clearing \(UserCredentials.UserCredentialKeys.kUserCredentialNetflixID) from Keychain with error: \(String(describing: SecCopyErrorMessageString(status1, nil)))")
            return
        }
        guard status2 == noErr || status2 == errSecItemNotFound else {
            XCTFail("Error clearing \(UserCredentials.UserCredentialKeys.kUserCredentialNetflixID) from Keychain with error \(String(describing: SecCopyErrorMessageString(status2, nil)))")
            return
        }
    }

    //MARK: - Start of Tests
    func testCanSetValidCredentialsFromCookie() {
        //given
        let mockNetflixID = "THIS_IS_A_NETFLIX_ID"
        let mockNetflixSecureID = "THIS_IS_A_NETFLIX_SECURE_ID"
        
        let cookies: [UserCredentials.UserCredentialKeys: String] = [
            UserCredentials.UserCredentialKeys.kUserCredentialNetflixID: mockNetflixID,
            UserCredentials.UserCredentialKeys.kUserCredentialNetflixSecureID: mockNetflixSecureID
        ]
        
        //when
        do {
            try UserCredentials.setCredentials(fromCookies: cookies)
        } catch {
            XCTFail("Encountered error: \(error.localizedDescription) when setting credentials from cookies")
        }
        
        //then
        if let netflixID = UserCredentials.netflixID {
            XCTAssertEqual(netflixID, mockNetflixID)
        } else {
            XCTFail("NetflixID was nil")
        }
        
        if let netflixSecureID = UserCredentials.netflixSecureID {
            XCTAssertEqual(netflixSecureID, mockNetflixSecureID)
        } else {
            XCTFail("NetflixSecureID was nil")
        }
    }
    
    func testInvalidCredentialsDoesThrow() {
        //given
        var didThrow = false
        let mockNetflixID = "THIS_IS_A_NETFLIX_ID"
        
        let cookies: [UserCredentials.UserCredentialKeys: String] = [
            UserCredentials.UserCredentialKeys.kUserCredentialNetflixID: mockNetflixID
        ]
        
        //when
        do {
            try UserCredentials.setCredentials(fromCookies: cookies)
            didThrow = false
        } catch UserCredentials.UserCredentialError.MissingCredentials {
            didThrow = true
        } catch {
            XCTFail("Unexpected error: \(error.localizedDescription) encountered")
        }
        
        //then
        XCTAssertEqual(didThrow, true, "The setCredentials did not throw when given too few cookies")
    }
    
    func testCanSetNetflixIDCredentialWithSetter() {
        //given
        let mockUpdateNetflixID = "THIS_IS_AN_UPDATED_NETFLIX_ID"
        
        //when
        UserCredentials.netflixID = mockUpdateNetflixID
        
        //then
        XCTAssertEqual(UserCredentials.netflixID, mockUpdateNetflixID)
    }
    
    func testCanSetNetflixIDCredentialNil() {
        //when
        UserCredentials.netflixID = nil
        
        //then
        XCTAssertNil(UserCredentials.netflixID, "Expected nil for netflixID, got a value")
    }
    
    func testCanSetNetflixSecureIDCredentialWithSetter() {
        //given
        let mockUpdateNetflixSecureID = "THIS_IS_AN_UPDATED_NETFLIX_SECURE_ID"
        
        //when
        UserCredentials.netflixSecureID = mockUpdateNetflixSecureID
        
        //then
        XCTAssertEqual(UserCredentials.netflixSecureID, mockUpdateNetflixSecureID)
    }
    
    func testCanSetNetflixSecureIDCredentialNil() {
        //when
        UserCredentials.netflixSecureID = nil
        
        //then
        XCTAssertNil(UserCredentials.netflixSecureID, "Expected nil for netflixID, got a value")
    }
    
    func testHasCredentialsTrue()
    {
        //given
        UserCredentials.netflixID = "AN_ID"
        UserCredentials.netflixSecureID = "ANOTHER_ID"
        
        //then
        XCTAssertTrue(UserCredentials.hasCredentials)
    }
    
    func testHasCredentialsBothFalse() {
        //given
        clearKeychain()
        
        //then
        XCTAssertFalse(UserCredentials.hasCredentials)
    }
    
    func testHasCredentialsNetflixIDFalse() {
        //given
        clearKeychain()
        UserCredentials.netflixID = "AN_ID"
        
        //then
        XCTAssertFalse(UserCredentials.hasCredentials)
    }
    
    func testHasCredentialsNetflixSecureIDFalse() {
        //given
        clearKeychain()
        UserCredentials.netflixSecureID = "AN_ID"
        
        //then
        XCTAssertFalse(UserCredentials.hasCredentials)
    }
}
