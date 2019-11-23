//
//  UserCredentialStore.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/16/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import Foundation.NSDate
import Security.SecItem

///A struct used to represent the storage attributes that can be applied to a storage item.
public struct UserCredentialStorageItem {
	///The key used to identify the item in storage. This value must be unique for all storage items.
	public let key: String
	///The value relating to the `key` parameter
	public var value: String?
	///The type of data. This determines how the data is stored in Keychain. Only Cookie supported at this time.
	public var valueType: ValueType
	///An optional description to be stored as the description for this item in Keychain.
	public var description: String?
	
	
	///Describes what kind of data this should be stored as.
	public enum ValueType {
		///A cookie value that is expressed internally as a String
		case Cookie
	}
	
	/**
	Initialize a `Credential Store Item` struct that persists credential items.
	
	- Parameter key: The key used to identify the item in storage.
	- Parameter value: The value to store.
	- Parameter valueType: The type of data to be stored. This determines the storage strategy. For instance,
	cryptographic keys require a different storage method than internet passwords.
	For now, the only supported type is `Cookie`.
	- Parameter description: A user readable description of the item. This is not used internally and is
	only for the benifit of the implementer.
	*/
	public init(key: String, value: String? = nil, valueType: ValueType = .Cookie, description: String? = nil) {
		self.key = key
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

public protocol UserCredentialStorageProtocol: class {
	//We need an initializer to restore the item or delete it
	init()
	
	/**
	Returns a list of credential items that describe the credential from storage.
	
	- Returns: An array of `UserCredentialStorageItem` objects that were stored for the `UserCredential`.
	*/
	func getListOfCredentialItemsToStore() -> [UserCredentialStorageItem]
	
	/**
	Gets a list of credential items that describe the credential for storage.
	
	- Parameter storageItems: An array of `UserCredentialStorageItem` objects that desicribe the `UserCredential`.
	*/
	func restoreFromStorageItems(_ storageItems: [UserCredentialStorageItem])
}

///A class used to persist items that conform to the `UserCredentialStorageProtocol`
public final class UserCredentialStore {
	
	///Errors that can be encountered while working with UserCredentialStore
	public enum UserCredentialStoreError: Error, Equatable {
		///The attributes in the CredentialStorageItem were either invalid or unexpectedly nil
		case invalidItemAttributes
		///When restoring tha data from storage, en error occured and invalid data was retrieved
		case invalidData
		///Was unable to find an item expected to exist
		case itemNotFound
		///Some other storage error occured
		case unexpectedStorageError(status: OSStatus)
	}
	
	
	//MARK: - Public Interface
	
	
	/**
	Restores the credential to it's stored value.
	
	- Parameter forType: A type that implements `UserCredentialStorageProtocol`.
	- Throws:
		- `UserCredentialStoreError.itemNotFound` if the item is not stored.
		- `UserCredentialStoreError.invalidData` if the data was corrupt on retrieval.
		- `UserCredentialStoreError.unexpectedStorageError(status:)` if another error was encountered with the OSStatus set.
	- Returns: A new instance of credentialType restored from the storage.
	*/
	public static func restoreCredential<T: UserCredentialStorageProtocol>(forType credentialType: T.Type) throws -> T {
		let returnCredential = credentialType.self.init()
		
		let credentialItems = returnCredential.getListOfCredentialItemsToStore()
		
		var returnCredentialItems = [UserCredentialStorageItem]()
		for item in credentialItems {
			var mutItem = item
			try retrieveCredentialStorageItem(&mutItem)
			returnCredentialItems.append(mutItem)
		}
		
		returnCredential.restoreFromStorageItems(returnCredentialItems)
		
		return returnCredential
	}
	
	/**
	Stores the credential. Nil attributes are not allowed.
	
	- Parameter credential: A populated credential that conforms to `UserCredentialStorageProtocol` to be stored.
	- Throws:
		- `UserCredentialStoreError.itemNotFound` if the item is not stored.
		- `UserCredentialStoreError.invalidItemAttribute' if an attribute is nil
		- `UserCredentialStoreError.unexpectedStorageError(status:)` if another error was encountered with the OSStatus set.
	*/
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
	
	/**
	Checks if the credential exists already in storage or not.
	
	- Parameter forType: A type that implements `UserCredentialStorageProtocol`.
	- Throws:
		- `UserCredentialStoreError.itemNotFound` if the item is not stored.
		- `UserCredentialStoreError.invalidItemAttribute' if an attribute is nil
		- `UserCredentialStoreError.unexpectedStorageError(status:)` if another error was encountered with the OSStatus set.
	- Returns: A Bool indicating if the item is currently stored or not
	*/
	public static func isCredentialStored<T: UserCredentialStorageProtocol>(forType credentialType: T.Type) throws -> Bool {
		let returnCredential = credentialType.self.init()
		
		let credentialItems = returnCredential.getListOfCredentialItemsToStore()
		
		var credentialDoesNotExist: Bool = false
		for item in credentialItems {
			if(!(try doesCredentialItemAlreadyExist(item))) {
				credentialDoesNotExist = true
				break
			}
		}
		
		return !credentialDoesNotExist
	}
	
	/**
	Clears the credentials for the `UserCredentialStorageProtocol`
	
	- Parameter credential: A populated credential that conforms to `UserCredentialStorageProtocol` to be cleared from storage.
	- Throws:
		- `UserCredentialStoreError.unexpectedStorageError(status:)` if another error was encountered with the OSStatus set.
	*/
	public static func clearCredential(_ credential: UserCredentialStorageProtocol) throws {
		let credentialItems = credential.getListOfCredentialItemsToStore()
		
		for item in credentialItems {
			try deleteCredentialItem(item)
		}
	}
	
	/**
	Clears the credentials for a type `UserCredentialStorageProtocol`
	
	- Parameter credential: A type that conforms to `UserCredentialStorageProtocol` to be cleared from storage.
	- Throws:
		- `UserCredentialStoreError.unexpectedStorageError(status:)` if another error was encountered with the OSStatus set.
	*/
	public static func clearCredential<T: UserCredentialStorageProtocol>(forType credentialType: T.Type) throws {
		let clearCredential = credentialType.self.init()
		let credentialItems = clearCredential.getListOfCredentialItemsToStore()
		
		for item in credentialItems {
			try deleteCredentialItem(item)
		}
	}
	
	
	//MARK: - Keychain functions
	
	
	/**
	Performs a search in Keychain for the item without returning the data.
	
	- Parameter storageItem: A `CredentialStorageItem` to search for.
	- Throws:
		- `UserCredentialStoreError.unexpectedStorageError(status:)` if an error was encountered with the OSStatus set.
	- Returns: `true` if the item was found in Keychain, and `false` if it was not located.
	*/
	private static func doesCredentialItemAlreadyExist(_ storageItem: UserCredentialStorageItem) throws -> Bool {
		//Build the search query
		let keychainGetQuery: [CFString: Any] = [
			kSecClass: kSecClassGenericPassword,
			kSecAttrAccount: storageItem.key as CFString,
			kSecReturnData: kCFBooleanFalse!,
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
	
	/**
	Performs a search in Keychain for the item and returns the data.
	
	- Parameter storageItem: A `CredentialStorageItem` to search for. This is an inout parameter and will be updated with it's data on success.
	- Throws:
		- `UserCredentialStoreError.itemNotFound` if the item was not found in Keychain.
		- `UserCredentialStoreError.unexpectedStorageError(status:)` if an error was encountered with the OSStatus set.
	*/
	private static func retrieveCredentialStorageItem(_ storageItem: inout UserCredentialStorageItem)
		throws {
			//Build the search query
			let keychainGetQuery: [CFString: Any] = [
				kSecClass: kSecClassGenericPassword,
				kSecAttrAccount: storageItem.key as CFString,
				kSecReturnData: kCFBooleanTrue!,
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
	
	/**
	Performs a search in Keychain and updates the stored data in keychain to the item provided.
	
	- Parameter storageItem: A `CredentialStorageItem` to search for and update stored information for.
	- Throws:
		- `UserCredentialStoreError.invalidItemAttributes if the attributes of the provided storeage item are invalid.
		- `UserCredentialStoreError.unexpectedStorageError(status:)` if an error was encountered with the OSStatus set.
	*/
	private static func updateCredentialItem(_ storageItem: UserCredentialStorageItem) throws {
		guard storageItem.value != nil else {
			throw UserCredentialStoreError.invalidItemAttributes
		}
		
		//Convert String to UTF8 data
		let UTF8Data = storageItem.value!.data(using: String.Encoding.utf8)!
		
		//Build the search query
		let updateQueryDict: [CFString: Any] = [
			kSecClass: kSecClassGenericPassword,
			kSecAttrAccount: storageItem.key as CFString,
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
	
	/**
	Creates a new entry in keychain for the `CredentialStorageItem`.
	
	- Parameter storageItem: A `CredentialStorageItem` to store in Keychain.
	- Throws:
		- `UserCredentialStoreError.invalidItemAttributes if the attributes of the provided storeage item are invalid.
		- `UserCredentialStoreError.invalidData if the `Value` field of the `CredentialStorageItem` was unable to be converted to UTF-8 Data.
		- `UserCredentialStoreError.unexpectedStorageError(status:)` if an error was encountered with the OSStatus set.
	*/
	private static func createCredentialItem(_ storageItem: UserCredentialStorageItem) throws {
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
			kSecAttrAccount: storageItem.key as CFString,
			kSecValueData: UTF8data,
			kSecReturnData: kCFBooleanFalse!
		]
		
		//Save the item
		let status = SecItemAdd(addAttributesDict as CFDictionary, nil)
		
		guard status == noErr else {
			throw UserCredentialStoreError.unexpectedStorageError(status: status)
		}
	}
	
	/**
	Deletes an entry in keychain for the `CredentialStorageItem`.
	
	- Parameter storageItem: A `CredentialStorageItem` to delete from Keychain.
	- Throws:
		- `UserCredentialStoreError.unexpectedStorageError(status:)` if an error was encountered with the OSStatus set.
	*/
	private static func deleteCredentialItem(_ storageItem: UserCredentialStorageItem) throws {
		let queryDict: [CFString: Any] = [
			kSecClass: kSecClassGenericPassword,
			kSecAttrAccount: storageItem.key
		]
		
		let status = SecItemDelete(queryDict as CFDictionary)
		
		guard status == noErr else {
			throw UserCredentialStoreError.unexpectedStorageError(status: status)
		}
	}
}
