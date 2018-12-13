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
    }
    
    //MARK: - External Access
    public var netflixID: String? {
        get {
            return getCookie(name: Keychain.KeychainIDs.netflixID)
        }
        
        set {
            if newValue == nil {
                deleteCookie(name: Keychain.KeychainIDs.netflixID)
            } else {
                storeCookie(name: Keychain.KeychainIDs.netflixID, value: newValue!)
            }
        }
    }
    
    public var netflixSecureID: String? {
        get {
            return getCookie(name: Keychain.KeychainIDs.netflixSecretID)
        }
        
        set {
            if newValue == nil {
                deleteCookie(name: Keychain.KeychainIDs.netflixSecretID)
            } else {
                storeCookie(name: Keychain.KeychainIDs.netflixSecretID, value: newValue!)
            }
        }
    }
    
    //MARK: - Private Methods
    private func storeCookie(name: String, value: String) {
        
        //Figure out if we need to create or update the keychain item.
        do {
             let _ = try getCookieKeychainItem(name: name, shouldReturnItem: false)
            
            //It didn't throw here, so that means that we already have a keychain value for this. Update it.
            try updateCookieKeychainItem(name: name, value: value)
            
        } catch Keychain.KeychainError.notFound {
            //Create the keychain item
            do {
                try createCookieKeychainItem(name: name, value: value)
            } catch Keychain.KeychainError.unexpectedError(let status) {
                print("Unexpected error from keychain get inside storeCookie! Keychain OSStaus error: \(String(describing: SecCopyErrorMessageString(status, nil)))")
            } catch {
                print("Keychain error creating \(name)")
            }
        } catch Keychain.KeychainError.unexpectedError(status: let status)
        {
            //Trying to get the keychain item failed horribly.
            print("Unexpected error from keychain get inside storeCookie! Keychain OSStaus error: \(String(describing: SecCopyErrorMessageString(status, nil)))")
        } catch {
            //Other failures...
            print("Keychain error retrieving \(name)")
        }
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
    
    private func deleteCookie(name: String) {
        do {
            try deleteCookieKeychainItem(name: name)
        } catch Keychain.KeychainError.unexpectedError(let status) {
            print("Unexpected OSStatus error: \(status) deleting keychain item: \(name)")
        } catch {
            print("This will never execute!")
        }
    }
    
    private func createCookieKeychainItem(name: String, value: String) throws {
        
        //Convert the value to UTF-8 data
        guard let UTF8data = value.data(using: String.Encoding.utf8) else {
            throw Keychain.KeychainError.badData
        }
        
        //Get a dictionary with the default values
        let addAttributesDict: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrModificationDate: Date(),
            kSecAttrDescription: "Stores the netflix cookie \(name) in keychain to fetch ratings for this user",
            kSecAttrAccount: name as CFString,
            kSecValueData: UTF8data,
            kSecReturnData: kCFBooleanFalse
        ]
        
        //Save the item
        let status = SecItemAdd(addAttributesDict as CFDictionary, nil)
        
        guard status == noErr else {
            throw Keychain.KeychainError.unexpectedError(status: status)
        }
    }
    
    private func updateCookieKeychainItem(name: String, value: String) throws {
        //Convert String to UTF8 data
        let UTF8Data = value.data(using: String.Encoding.utf8)!
        
        //Build the search query
        let updateQueryDict: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: name as CFString,
        ]
        
        //Create a list of changed attributes
        let updateItemsDict: [CFString: Any] = [
            kSecValueData: UTF8Data,
            kSecAttrModificationDate: Date()
            ]
        
        //Update the keychain item
        let status = SecItemUpdate(updateQueryDict as CFDictionary, updateItemsDict as CFDictionary)
        
        //Check for errors
        guard status == noErr else {
            throw Keychain.KeychainError.unexpectedError(status: status)
        }
    }
    
    private func getCookieKeychainItem(name: String, shouldReturnItem: Bool = true) throws -> String? {
        //Build the query
        let returnItem = shouldReturnItem ? kCFBooleanTrue : kCFBooleanFalse
        
        let keychainGetQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: name as CFString,
            kSecReturnData: returnItem!,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        //Query and set the object from keychain
        var returnQueryCookie: AnyObject?
        let status = withUnsafeMutablePointer(to: &returnQueryCookie) {
            SecItemCopyMatching(keychainGetQuery as CFDictionary, UnsafeMutablePointer($0))
        }
        
        //If the cookie isn't found, throw an error
        guard status != errSecItemNotFound else {
            throw Keychain.KeychainError.notFound
        }
        
        //If there's any error other than the one above, panic!
        guard status == noErr else {
            throw Keychain.KeychainError.unexpectedError(status: status)
        }
        
        if shouldReturnItem {
            //The user asked us to return the data
            
            //Transform the data back into a String
            guard let returnCookieData = returnQueryCookie as? Data,
                let returnCookieString = String(bytes: returnCookieData, encoding: String.Encoding.utf8) else {
                throw Keychain.KeychainError.badData
            }
            return returnCookieString
        } else {
            return nil
        }
    }
    
    private func deleteCookieKeychainItem(name: String) throws {
        //Create a query for the entry
        let queryDict: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: name as CFString
        ]

        //Delete the item
        let status = SecItemDelete(queryDict as CFDictionary)
        
        //Check for errors
        guard status == noErr else {
            throw Keychain.KeychainError.unexpectedError(status: status)
        }
    }
}
