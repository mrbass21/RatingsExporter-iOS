//
//  KeychainAccess.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/12/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import Foundation
import Security

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
    
    //MARK: - Internal Storage
    private lazy var _netflixID: String? = {
        //Lookup in Keychain
        return getCookie(name: Keychain.KeychainIDs.netflixID)
    }()

    private lazy var _netflixSecureID: String? = {
       return getCookie(name: Keychain.KeychainIDs.netflixSecretID)
    }()
    
    
    //MARK: - External Access
    public var netflixID: String? {
        mutating get{
            return _netflixID
        }
        
        set {
            storeCookie(name: Keychain.KeychainIDs.netflixID, value: newValue)
        }
    }
    
    public var netflixSecureID: String? {
        mutating get {
            return _netflixSecureID
        }
        
        set {
            
        }
    }
    
    //MARK: - Private Methods
    private func storeCookie(name: String, value: String?) {
        
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
        
        var returnQueryCookie: AnyObject?
        let status = withUnsafeMutablePointer(to: &returnQueryCookie) {
            SecItemCopyMatching(keychainQuery as CFDictionary, UnsafeMutablePointer($0))
        }
        
        //If the cookie isn't found, throw an error
        guard status != errSecItemNotFound else {
            throw Keychain.KeychainError.notFound
        }
        
        guard status == noErr else {
            throw Keychain.KeychainError.unexpectedError(status: status)
        }
        
        guard let returnCookie = returnQueryCookie as? [CFString: AnyObject], let returnCookieValue = returnCookie[kSecValueData] as? String else {
            throw Keychain.KeychainError.badData
        }
        
        return returnCookieValue
    }
    
    private func deleteCookieKeychainItem() {
        
    }
}
