//
//  KeychainAccess.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/12/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import Foundation
import Security
import WebKit

// The original goal of this struct is to privide a single place to get the credentials as easily as possible
// from the callers perspctive. However, currently this design does not allow this struct to throw on error with
// keychain errors, so it's up to the caller to check that if they try and set a cookie, then try to get it again
// and it's nil, they handle the problem.
//
// A possible redesign of this is to make the computed properties functions that can throw to report keychain errors
// up one more layer to the consumer and let them handle the errors.



//MARK: - UserCredentialsProtocol
protocol UserCredentialProtocol {
 
}

struct UserCredentials {
    
    enum UserCredentialError: Error {
        case InvalidCredentials
        case MissingCredentials
    }
    
    
    //MARK: - Public Functions
//    public func storeCredential(_ credential: UserCredentialsProtocol) {
//        let storageCredentials = credential.getCredentialsForStorage()
//    }
    
    
//    //MARK: - External Access
//    public static var hasCredentials: Bool {
//        guard self.getCookie(name: UserCredentialKeys.kUserCredentialNetflixID.rawValue) != nil &&
//            self.getCookie(name: UserCredentialKeys.kUserCredentialNetflixSecureID.rawValue) != nil else {
//                return false
//        }
//        return true
//    }
//
//    public static func setCredentials(fromCookies: [UserCredentialKeys: String]) throws {
//
//        if fromCookies.count < 2 {
//            throw UserCredentialError.MissingCredentials
//        }
//
//        for (key, value) in fromCookies {
//            storeCookie(name: key.rawValue, value: value)
//        }
//    }
//
//    //MARK: - Private Methods
//
//

//
//    private static func updateCookieKeychainItem(name: String, value: String) throws {
//        
//    }
//
//    private static func getCookieKeychainItem(name: String, shouldReturnItem: Bool = true) throws -> String? {
//        //Build the query

//    }
//
//    private static func deleteCookieKeychainItem(name: String) throws {
//        //Create a query for the entry
//        let queryDict: [CFString: Any] = [
//            kSecClass: kSecClassGenericPassword,
//            kSecAttrAccount: name as CFString
//        ]
//
//        //Delete the item
//        let status = SecItemDelete(queryDict as CFDictionary)
//
//        //Check for errors
//        guard status == noErr else {
//            throw Keychain.KeychainError.unexpectedError(status: status)
//        }
//    }
}
