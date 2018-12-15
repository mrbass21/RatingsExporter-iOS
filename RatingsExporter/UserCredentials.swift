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

struct UserCredentials {
    
    enum UserCredentialError: Error {
        case InvalidCredentials
        case MissingCredentials
    }
    
    enum UserCredentialKeys: String {
        case kUserCredentialNetflixID = "NetflixID"
        case kUserCredentialNetflixSecureID = "NetflixSecureID"
    }
    
    private struct Keychain {
        enum KeychainError: Error {
            case notFound
            case badData
            case unexpectedError(status: OSStatus)
        }
    }
    
    //MARK: - External Access
    public static var netflixID: String? {
        get {
            return getCookie(name: UserCredentialKeys.kUserCredentialNetflixID.rawValue)
        }
        
        set {
            if newValue == nil {
                deleteCookie(name: UserCredentialKeys.kUserCredentialNetflixID.rawValue)
            } else {
                storeCookie(name: UserCredentialKeys.kUserCredentialNetflixID.rawValue, value: newValue!)
            }
        }
    }
    
    public static var netflixSecureID: String? {
        get {
            return getCookie(name: UserCredentialKeys.kUserCredentialNetflixSecureID.rawValue)
        }
        
        set {
            if newValue == nil {
                deleteCookie(name: UserCredentialKeys.kUserCredentialNetflixSecureID.rawValue)
            } else {
                storeCookie(name: UserCredentialKeys.kUserCredentialNetflixSecureID.rawValue, value: newValue!)
            }
        }
    }
    
    public static var hasCredentials: Bool {
        guard self.getCookie(name: UserCredentialKeys.kUserCredentialNetflixID.rawValue) != nil &&
            self.getCookie(name: UserCredentialKeys.kUserCredentialNetflixSecureID.rawValue) != nil else {
                return false
        }
        return true
    }
    
    public static func setCredentials(fromCookies: [UserCredentialKeys: String]) throws {
        
        if fromCookies.count < 2 {
            throw UserCredentialError.MissingCredentials
        }
        
        for (key, value) in fromCookies {
            storeCookie(name: key.rawValue, value: value)
        }
    }
    
    //MARK: - Private Methods
    private static func storeCookie(name: String, value: String) {
        
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
    
    private static func getCookie(name: String) -> String? {
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
    
    private static func deleteCookie(name: String) {
        do {
            try deleteCookieKeychainItem(name: name)
        } catch Keychain.KeychainError.unexpectedError(let status) {
            print("Unexpected OSStatus error: \(status) deleting keychain item: \(name)")
        } catch {
            print("This will never execute!")
        }
    }
    
    //MARK: - Keychain Direct Access Methods
    private static func createCookieKeychainItem(name: String, value: String) throws {
        
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
    
    private static func updateCookieKeychainItem(name: String, value: String) throws {
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
    
    private static func getCookieKeychainItem(name: String, shouldReturnItem: Bool = true) throws -> String? {
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
    
    private static func deleteCookieKeychainItem(name: String) throws {
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
