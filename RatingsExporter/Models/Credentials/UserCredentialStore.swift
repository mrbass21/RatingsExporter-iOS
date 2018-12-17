//
//  UserCredentialStore.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/16/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import Foundation
import Security

class UserCredentialStore {
    
    private struct Keychain {
        enum KeychainError: Error {
            case notFound
            case badData
            case unexpectedError(status: OSStatus)
        }
    }
    
    public static func getCredential(_ credential: UserCredentialProtocol) {
        
    }
    
//    public static func storeCredential(_ credential: UserCredentialProtocol) {
//        
//        //Get credentials from storage
//        do {
//            let storeCreds = try credential.getCredentialsForStorage()
//            for credential in storeCreds {
//                storeCredential(credential)
//            }
//        } catch {
//            
//        }
//    }
    
    //MARK: - Keychain functions
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
}
