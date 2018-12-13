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
        static var addDictionary: [CFString: Any] {
            let keychainAttributes: [CFString: Any] = [
                kSecClass:kSecAttrGeneric,
                kSecAttrModificationDate: Date()
                ]
            
            return keychainAttributes
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
             let _ = try getCookieKeychainItem(name: name)
            //It didn't throw here, so that means that we already have a keychain value for this. Update it.
            updateCookieKeychainItem(name: name, value: value)
            
        } catch Keychain.KeychainError.notFound {
            //Create the keychain item
            do {
                try createCookieKeychainItem(name: name, value: value)
            } catch Keychain.KeychainError.unexpectedError(let status) {
                print("Unexpected error from keychain get inside storeCookie! Keychain OSStaus error: \(status)")
            } catch {
                print("Keychain error creating \(name)")
            }
        } catch Keychain.KeychainError.unexpectedError(status: let status)
        {
            //Trying to get the keychain item failed horribly.
            print("Unexpected error from keychain get inside storeCookie! Keychain OSStaus error: \(status)")
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
        deleteCookieKeychainItem(name: name)
    }
    
    private func createCookieKeychainItem(name: String, value: String) throws {
        
        //Convert the value to UTF-8 data
        let UTF8data = value.data(using: String.Encoding.utf8)!
        
        //Get a dictionary with the default values
        var addAttributesDict = Keychain.addDictionary
        addAttributesDict[kSecAttrDescription] = "Stores the netflix cookie \(name) in keychain to fetch ratings for this user"
        addAttributesDict[kSecAttrAccount] = name
        addAttributesDict[kSecValueData] = UTF8data as AnyObject
        
        //Save the item
        let status = SecItemAdd(addAttributesDict as CFDictionary, nil)
        
        guard status == noErr else {
            throw Keychain.KeychainError.unexpectedError(status: status)
        }
    }
    
    private func updateCookieKeychainItem(name: String, value: String) throws {
        //Convert String to UTF8 data
        let UTF8Data = value.data(using: String.Encoding.utf8)!
        
        var updateQueryDict = Keychain.queryDictionary
        updateQueryDict[kSecAttrAccount] = name as CFString
        
        let updateItemsDict = [kSecValueData: UTF8Data]
        
        let status = SecItemUpdate(updateQueryDict as CFDictionary, updateItemsDict as CFDictionary)
        
        guard status == noErr else {
            throw Keychain.KeychainError.unexpectedError(status: status)
        }
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
    
    private func deleteCookieKeychainItem(name: String) throws {
        var queryDict = Keychain.queryDictionary
        queryDict[kSecAttrAccount] = name as CFString

        let status = SecItemDelete(queryDict as CFDictionary)
        
        guard status == noErr else {
            throw Keychain.KeychainError.unexpectedError(status: status)
        }
    }
}
