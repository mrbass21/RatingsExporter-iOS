//
//  NetflixCredentials.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/16/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import Foundation

protocol NetflixCredentialProtocol: UserCredentialProtocol {
    var netflixID: String? { get set }
    var netflixSecureID: String? { get set }
}

class NetflixCredential: NetflixCredentialProtocol {
    
    struct RequiredIDs {
        enum Cookie: String, CaseIterable {
            case netflixID = "NetflixId"
            case secureNetflixID = "SecureNetflixId"
        }
    }
    
    public var netflixID: String?
    public var netflixSecureID: String?
    
    var credentialAttributes: [[CredentialAttribtesKeys : Any]] = [[CredentialAttribtesKeys:Any]]()
    
    @available (iOS 2.0, *)
    init?(from cookies: [HTTPCookie]) {
        if !parseCredentialFromCooke(cookies) {
            return nil
        }
    }
    
    init(netflixID: String, netflixSecureID: String) {
        self.netflixID = netflixID
        self.netflixSecureID = netflixSecureID
    }
    
    
    //MARK: - Private Functions
    private func parseCredentialFromCooke(_ cookies: [HTTPCookie]) -> Bool {
        let neededCookies = cookies.filter({ (cookie) -> Bool in
            if RequiredIDs.Cookie.init(rawValue: cookie.name) != nil {
                return true
            }
            
            return false
        })
        
        if neededCookies.count < RequiredIDs.Cookie.allCases.count {
            //We didn't find the minimum number of cookies we need
            return false
        } else {
            for item in neededCookies {
                if item.name.elementsEqual(RequiredIDs.Cookie.netflixID.rawValue) {
                    self.netflixID = item.value
                } else if item.name.elementsEqual(RequiredIDs.Cookie.secureNetflixID.rawValue) {
                    self.netflixSecureID = item.value
                }
            }
        }
        
        return true
    }
    
//    //UserCredentialProtocol functions
//    func getCredentialForStorage() throws -> UserCredentialProtocol {
//        
//    }
    
    func setCrecentialFromStorage(_ storageItems: UserCredentialProtocol) throws {
        
    }
    
    
    
    

    
//
//    private static func storeCookie(name: String, value: String) {
    
//        //Figure out if we need to create or update the keychain item.
//        do {
//            let _ = try getCookieKeychainItem(name: name, shouldReturnItem: false)
//
//            //It didn't throw here, so that means that we already have a keychain value for this. Update it.
//            try updateCookieKeychainItem(name: name, value: value)
//
//        } catch Keychain.KeychainError.notFound {
//            //Create the keychain item
//            do {
//                try createCookieKeychainItem(name: name, value: value)
//            } catch Keychain.KeychainError.unexpectedError(let status) {
//                print("Unexpected error from keychain get inside storeCookie! Keychain OSStaus error: \(String(describing: SecCopyErrorMessageString(status, nil)))")
//            } catch {
//                print("Keychain error creating \(name)")
//            }
//        } catch Keychain.KeychainError.unexpectedError(status: let status)
//        {
//            //Trying to get the keychain item failed horribly.
//            print("Unexpected error from keychain get inside storeCookie! Keychain OSStaus error: \(String(describing: SecCopyErrorMessageString(status, nil)))")
//        } catch {
//            //Other failures...
//            print("Keychain error retrieving \(name)")
//        }
//    }
//
//    private static func getCookie(name: String) -> String? {
//        //Use Keychain to get the cookie value
//        do {
//            return try getCookieKeychainItem(name: name)
//        } catch Keychain.KeychainError.unexpectedError(let status){
//            print("Unexpected keychain error: \(String(describing: SecCopyErrorMessageString(status, nil)))")
//            return nil
//        } catch {
//            print("\(name) not found in keychain")
//            return nil
//        }
//    }
//
//    private static func deleteCookie(name: String) {
//        do {
//            try deleteCookieKeychainItem(name: name)
//        } catch Keychain.KeychainError.unexpectedError(let status) {
//            print("Unexpected OSStatus error: \(status) deleting keychain item: \(name)")
//        } catch {
//            print("This will never execute!")
//        }
//    }
}
