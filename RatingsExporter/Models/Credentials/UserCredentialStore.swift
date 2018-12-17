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
public struct CredentialItemStorageAttribteKeys: RawRepresentable, Hashable, Equatable {
    public private (set) var rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init (rawValue: String) {
        self.rawValue = rawValue
    }
    
    public var hashValue: Int {
        return self.rawValue.hashValue
    }
    
    public static func ==(_ lhs: CredentialItemStorageAttribteKeys, _ rhs: CredentialItemStorageAttribteKeys) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension CredentialItemStorageAttribteKeys {
    //Key for the credential name
    public static let Name = CredentialItemStorageAttribteKeys(rawValue: "Name")
    
    //Key for the credential value
    public static let Value = CredentialItemStorageAttribteKeys(rawValue: "Value")
    
    //Key for the credential value type
    public static let ValueType = CredentialItemStorageAttribteKeys(rawValue: "ValueType")
    
    //The description of the item to be stored
    public static let Description = CredentialItemStorageAttribteKeys(rawValue: "Description")
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
    func restoreFromStorageItemAttributes( attributes: [[CredentialItemStorageAttribteKeys: String]]) -> UserCredentialStorageProtocol?
}


class UserCredentialStore {
    
    enum UserCredentialStoreError: Error {
        case invalidItemAttributes
        case valueTypeNotSupported
        case invalidData
        case unexpectedStorageError(status: OSStatus)
    }
    
    public static func restoreCredential(for credential: UserCredentialStorageProtocol) -> String {
        
        return "works"
    }
    
    public static func storeCredential(_ credential: UserCredentialStorageProtocol) throws {
        
        //Get the credential items
        let credentialItems = credential.getListOfCredentialItemsByName()
        
        for item in credentialItems {
            //Get the attributes for that item
            let itemStorageAttributes = credential.getCredentialStorageAttributes(for: item)
            
            //Store the item
            try storeCredentialItem(withAttributes: itemStorageAttributes)
        }
    }
    
    //MARK: - Keychain functions
    private static func storeCredentialItem(withAttributes attributes: [CredentialItemStorageAttribteKeys: String]) throws {
        
        //Attributes can't be empty
        guard attributes.isEmpty || attributes.count < 3 else {
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
            throw UserCredentialStoreError.invalidItemAttributes
        }
        
        //We only support one type currently
        if attributes[.ValueType] != "Cookie" { //TODO: Probably should be an enum or class type
            throw UserCredentialStoreError.valueTypeNotSupported
        }
        
        //Convert the value to UTF-8 data
        guard let UTF8data = attributes[.Value]!.data(using: String.Encoding.utf8) else {
            throw UserCredentialStoreError.invalidData
        }
    
        //Get a dictionary with the default values
        let addAttributesDict: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrModificationDate: Date(),
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
}
