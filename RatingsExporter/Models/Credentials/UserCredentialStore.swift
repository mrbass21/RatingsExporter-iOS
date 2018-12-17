//
//  UserCredentialStore.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/16/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import Foundation
import Security

//MARK: - User CredentialStorageKeys
enum CredentialItemStorageAttribteKeys : String {
    case Name
    case Value
    case ValueType
    case Description
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
    //This is the list of items that UserCredentialStore will retrieve from keychain by the identifier,
    //however the credential item defines it.
    //It will follow a call to get the storage attributes for each specific item by identifier
    func getListOfCredentialItemsByName() -> Set<String>
    
    //This gets the attributes used to find or store the item in storage
    func getCredentialStorageAttributes(for identifier: String) -> [CredentialItemStorageAttribteKeys: String]
    
    //Initialize a new credential item from Storage Attributes
    func restoreFromStorageItemAttributes( attributes: [[CredentialItemStorageAttribteKeys: String]])
}


class UserCredentialStore {
    
    //Enum of possible errors that can be thrown
    enum UserCredentialStoreError: Error {
        case invalidItemAttributes
        case valueTypeNotSupported
        case invalidData
        case itemNotFound
        case unexpectedStorageError(status: OSStatus)
    }
    
    //MARK: - Public Interface
    public static func restoreCredential(for credential: UserCredentialStorageProtocol) throws -> UserCredentialStorageProtocol {
        let credentialItems = credential.getListOfCredentialItemsByName()
        
        var returnCredentialItems = [[CredentialItemStorageAttribteKeys: String]]()
        for item in credentialItems {
            //We need the credenial attribute list for searching... and also because I may one day support more types
            // (probably not)
            var credentialItemAttributes = credential.getCredentialStorageAttributes(for: item)
            
            try retrieveCredentialItem(withAttributes: &credentialItemAttributes)
            returnCredentialItems.append(credentialItemAttributes)
        }
        
        credential.restoreFromStorageItemAttributes(attributes: returnCredentialItems)
        
        return credential
    }
    
    public static func storeCredential(_ credential: UserCredentialStorageProtocol) throws {
        
        //Get the credential items
        let credentialItems = credential.getListOfCredentialItemsByName()
        
        for item in credentialItems {
            //Get the attributes for that item
            let itemStorageAttributes = credential.getCredentialStorageAttributes(for: item)
            
            //Create the item or update it
            if try doesCredentialItemAlreadyExist(withAttributes: itemStorageAttributes) {
                try updateCredentialItem(withAttributes: itemStorageAttributes)
            } else {
                try createCredentialItem(withAttributes: itemStorageAttributes)
            }
        }
    }
    
    //MARK: - Keychain functions
    private static func doesCredentialItemAlreadyExist(withAttributes attribute: [CredentialItemStorageAttribteKeys: String]) throws -> Bool {
        
        //Check that the attributes are valid
        try areAttributesValid(attribute)
        
        //Build the search query
        let keychainGetQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: attribute[.Name]! as CFString,
            kSecReturnData: kCFBooleanFalse,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        //Query and set the object from keychain
        var returnQueryCookie: AnyObject?
        let status = withUnsafeMutablePointer(to: &returnQueryCookie) {
            SecItemCopyMatching(keychainGetQuery as CFDictionary, UnsafeMutablePointer($0))
        }
        
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
    
    private static func retrieveCredentialItem(withAttributes attributes: inout [CredentialItemStorageAttribteKeys: String])
        throws {
            //Check if the attributes are valid
            try areAttributesValid(attributes)
            
            //Build the search query
            let keychainGetQuery: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: attributes[.Name]! as CFString,
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
            
            attributes[.Value] = returnCookieString
            attributes[.ValueType] = "Cookie" //TODO: This should be dynamic if I accept multiple types ever
    }
    
    private static func updateCredentialItem(withAttributes attributes: [CredentialItemStorageAttribteKeys: String]) throws {
        //Check that the attributes are valid
        try areAttributesValid(attributes)
        
        //Convert String to UTF8 data
        let UTF8Data = attributes[.Value]!.data(using: String.Encoding.utf8)!
        
        //Build the search query
        let updateQueryDict: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: attributes[.Name]! as CFString,
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
    
    private static func createCredentialItem(withAttributes attributes: [CredentialItemStorageAttribteKeys: String]) throws {
        
        //Check the attributes are valid
        try areAttributesValid(attributes)
        
        //Convert the value to UTF-8 data
        guard let UTF8data = attributes[.Value]!.data(using: String.Encoding.utf8) else {
            throw UserCredentialStoreError.invalidData
        }
    
        //Get a dictionary with the default values
        let addAttributesDict: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrCreationDate: Date(),
            kSecAttrDescription: attributes[.Description] ?? "No Description",
            kSecAttrAccount: attributes[.Name]! as CFString,
            kSecValueData: UTF8data,
            kSecReturnData: kCFBooleanFalse
        ]
    
        //Save the item
        let status = SecItemAdd(addAttributesDict as CFDictionary, nil)
    
        guard status == noErr else {
            throw UserCredentialStoreError.unexpectedStorageError(status: status)
        }
    }
    
    //MARK: - Helper Methods
    private static func areAttributesValid(_ attributes: [CredentialItemStorageAttribteKeys: String]) throws {
        
        //Attributes can't be empty
        guard attributes.isEmpty || attributes.count < 3 else {
            print("UserCredentialStore_areAttributesValid: attributes are empty or less than three.")
            throw UserCredentialStoreError.invalidItemAttributes
        }
        
        //We require at least three attributes to be present.
        //Name, value, and value type
        let requiredItems = attributes.filter { (key,_) -> Bool in
            if key == .Name || key == .Value || key == .ValueType
            {
                return true
            }
            return false
        }
        guard requiredItems.count >= 3 else {
            print("UserCredentialStore_areAttributesValid: Required attribute missing.")
            throw UserCredentialStoreError.invalidItemAttributes
        }
        
        //We only support one type currently
        if attributes[.ValueType] != "Cookie" { //TODO: Probably should be an enum or class type
            throw UserCredentialStoreError.valueTypeNotSupported
        }
    }
}
