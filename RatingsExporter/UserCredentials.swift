//
//  KeychainAccess.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/12/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import Foundation
import Security

// The original goal of this struct is to privide a single place to get the credentials as easily as possible
// from the callers perspctive. However, currently this design does not allow this struct to throw on error with
// keychain errors, so it's up to the caller to check that if they try and set a cookie, then try to get it again
// and it's nil, they handle the problem.
//
// A possible redesign of this is to make the computed properties functions that can throw to report keychain errors
// up one more layer to the consumer and let them handle the errors.

struct UserCredentials {
    
    private struct Keychain {
        enum KeychainError: Error {
            case notFound
            case badData
            case unexpectedError(status: OSStatus)
        }
        
         struct KeychainIDs {
            static let netflixID = "NetflixID"
            static let netflixSecretID = "NetflixSecretID"
        }
        
        static var queryDictionary: [CFString: CFString] {
            let keychainQuery = [
                kSecClass: kSecClassGenericPassword,
                kSecMatchLimit: kSecMatchLimitOne,
                ]
            
            return keychainQuery
        }
        static var addDictionary: CFDictionary {
            let keychainAttributes: CFDictionary = [
                kSecClass:kSecAttrGeneric,
                kSecAttrModificationDate: Date() as CFDate
                ] as CFDictionary
            
            return keychainAttributes
        }
    }
    
    //MARK: - External Access
    public var netflixID: String? {
        get {
            return getCookie(name: Keychain.KeychainIDs.netflixID)
        }
        
        set {
            storeCookie(name: Keychain.KeychainIDs.netflixID, value: newValue)
        }
    }
    
    public var netflixSecureID: String? {
        get {
            return getCookie(name: Keychain.KeychainIDs.netflixSecretID)
        }
        
        set {
            storeCookie(name: Keychain.KeychainIDs.netflixSecretID, value: newValue)
        }
    }
    
    //MARK: - Private Methods
    private func storeCookie(name: String, value: String?) {
        
        //Figure out if we need to create or update the keychain item.
        do {
             let _ = try getCookieKeychainItem(name: name)
            //It didn't throw here, so that means that we already have a keychain value for this. Update it.
        } catch Keychain.KeychainError.notFound {
            //Create the keychain item
        } catch Keychain.KeychainError.unexpectedError(status: let status)
        {
            //Trying to get the keychain item failed horribly.
            print("Unexpected error from keychain get inside storeCookie! Keychain OSStaus error: \(status)")
        } catch {
            //Other failures...
            print("Keychain error retrieving \(name)")
        }
        
        let keychainDescription = "Stores the netflix cookie \(name) in keychain to fetch ratings for this user"
        
    }
    
    private func getCookie(name: String) -> String? {
        //Use Keychain to get the cookie value
        do {
            return try getCookieKeychainItem(name: name)
        } catch Keychain.KeychainError.unexpectedError(let status){
            print("Unexpected keychain error: \(String(describing: SecCopyErrorMessageString(status, nil)))")
            return nil
        } catch {
            print("\(name) not found in keychain")
            return nil
        }
    }
    
    private func createCookieKeychainItem(name: String, value: String?) {
    
    }
    
    private func updateCookieKeychainItem(name: String, value: String?) {
        
    }
    
    private func getCookieKeychainItem(name: String) throws -> String {
        //Build the query
        var keychainQuery = Keychain.queryDictionary
        keychainQuery[kSecAttrAccount] = name as CFString
        
        //Query and set the object from keychain
        var returnQueryCookie: AnyObject?
        let status = withUnsafeMutablePointer(to: &returnQueryCookie) {
            SecItemCopyMatching(keychainQuery as CFDictionary, UnsafeMutablePointer($0))
        }
        
        //If the cookie isn't found, throw an error
        guard status != errSecItemNotFound else {
            throw Keychain.KeychainError.notFound
        }
        
        //If there's any error other than the one above, panic!
        guard status == noErr else {
            throw Keychain.KeychainError.unexpectedError(status: status)
        }
        
        //Do a bunch of binding to check everything goes okay
        guard let returnCookie = returnQueryCookie as? [CFString: AnyObject],
                let returnCookieValue = returnCookie[kSecValueData] as? Data,
                let returnCookieString = String(bytes: returnCookieValue, encoding: String.Encoding.utf8) else {
            throw Keychain.KeychainError.badData
        }
        
        return returnCookieString
    }
    
    private func deleteCookieKeychainItem() {
        
    }
}
