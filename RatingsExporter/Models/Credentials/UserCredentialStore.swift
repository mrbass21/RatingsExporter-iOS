//
//  UserCredentialStore.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/16/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import Foundation
import Security

public struct CredentialStorageItem {
    let name: String
    var value: String?
    var valueType: ValueType
    var description: String?
    
    enum ValueType {
        case Cookie
    }
    
    init(name: String, value: String? = nil, valueType: ValueType = .Cookie, description: String? = nil) {
        self.name = name
        self.value = value
        self.valueType = valueType
        self.description = description
    }
}
//In this class there are some possibly confusing terminoligy to refer to parts of the credential.
//
//
//A Credential is considered a standard unit to represet a credential as a whole. For example:
//A username and a password are considered a single credential.
//
//A Credential Item is defined as any part that makes up a whole credential. A username is a
//Credential Item. A password is a Credential Item. These two Credential Items make up a Credential.
//
//Credential Item Attributes are a list of attributes that describe how the Credential Item should be stored.


protocol UserCredentialStorageProtocol {
    //Gets a list of credential items to store
    func getListOfCredentialItemsToStore() -> [CredentialStorageItem]
    
    //Initialize a new credential item from Storage Attributes
    func restoreFromStorageItems(_ storageItems: [CredentialStorageItem])
}


class UserCredentialStore {
    
    //Enum of possible errors that can be thrown
    enum UserCredentialStoreError: Error {
        case invalidItemAttributes
        case invalidData
        case itemNotFound
        case unexpectedStorageError(status: OSStatus)
    }
    
    //MARK: - Public Interface
    public static func restoreCredential(for credential: UserCredentialStorageProtocol) throws -> UserCredentialStorageProtocol {
        let credentialItems = credential.getListOfCredentialItemsToStore()
        
        var returnCredentialItems = [CredentialStorageItem]()
        for item in credentialItems {
            var mutItem = item
            try retrieveCredentialStorageItem(&mutItem)
            returnCredentialItems.append(item)
        }
        
        credential.restoreFromStorageItems(returnCredentialItems)
        
        return credential
    }
    
    public static func storeCredential(_ credential: UserCredentialStorageProtocol) throws {
        
        //Get the credential items
        let credentialItems = credential.getListOfCredentialItemsToStore()
        
        for item in credentialItems {
            //Create the item or update it
            if try doesCredentialItemAlreadyExist(item) {
                try updateCredentialItem(item)
            } else {
                try createCredentialItem(item)
            }
        }
    }
    
    //MARK: - Keychain functions
    private static func doesCredentialItemAlreadyExist(_ storageItem: CredentialStorageItem) throws -> Bool {
        //Build the search query
        let keychainGetQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: storageItem.name as CFString,
            kSecReturnData: kCFBooleanFalse,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        //Query and set the object from keychain
        let status = SecItemCopyMatching(keychainGetQuery as CFDictionary, nil)
        
        //If the cookie isn't found, throw an error
        guard status != errSecItemNotFound else {
            return false
        }
        
        //If there's any error other than the one above, panic!
        guard status == noErr else {
            throw UserCredentialStoreError.unexpectedStorageError(status: status)
        }
        
        //Item was found
        return true
    }
    
    private static func retrieveCredentialStorageItem(_ storageItem: inout CredentialStorageItem)
        throws {
            //Build the search query
            let keychainGetQuery: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: storageItem.name as CFString,
                kSecReturnData: kCFBooleanTrue,
                kSecMatchLimit: kSecMatchLimitOne
            ]
            
            //Query and set the object from keychain
            var returnQueryCookie: AnyObject?
            let status = withUnsafeMutablePointer(to: &returnQueryCookie) {
                SecItemCopyMatching(keychainGetQuery as CFDictionary, UnsafeMutablePointer($0))
            }
            
            //If the cookie isn't found, throw an error
            guard status != errSecItemNotFound else {
                throw UserCredentialStoreError.itemNotFound
            }
            
            //If there's any error other than the one above, panic!
            guard status == noErr else {
                throw UserCredentialStoreError.unexpectedStorageError(status: status)
            }
            
            //Transform the data back into a String
            guard let returnCookieData = returnQueryCookie as? Data,
                let returnCookieString = String(bytes: returnCookieData, encoding: String.Encoding.utf8) else {
                    //We had an errpr transforming the data back into a string
                    throw UserCredentialStoreError.invalidData
            }
            
            storageItem.value = returnCookieString
            storageItem.valueType = .Cookie
    }
    
    private static func updateCredentialItem(_ storageItem: CredentialStorageItem) throws {
        guard storageItem.value != nil else {
            throw UserCredentialStoreError.invalidItemAttributes
        }
        
        //Convert String to UTF8 data
        let UTF8Data = storageItem.value!.data(using: String.Encoding.utf8)!
        
        //Build the search query
        let updateQueryDict: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: storageItem.name as CFString,
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
            throw UserCredentialStoreError.unexpectedStorageError(status: status)
        }
    }
    
    private static func createCredentialItem(_ storageItem: CredentialStorageItem) throws {
        guard storageItem.value != nil else {
            throw UserCredentialStoreError.invalidItemAttributes
        }
        
        //Convert the value to UTF-8 data
        guard let UTF8data = storageItem.value!.data(using: String.Encoding.utf8) else {
            throw UserCredentialStoreError.invalidData
        }
    
        //Get a dictionary with the default values
        let addAttributesDict: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrCreationDate: Date(),
            kSecAttrDescription: storageItem.description ?? "No Description",
            kSecAttrAccount: storageItem.name as CFString,
            kSecValueData: UTF8data,
            kSecReturnData: kCFBooleanFalse
        ]
    
        //Save the item
        let status = SecItemAdd(addAttributesDict as CFDictionary, nil)
    
        guard status == noErr else {
            throw UserCredentialStoreError.unexpectedStorageError(status: status)
        }
    }
}
