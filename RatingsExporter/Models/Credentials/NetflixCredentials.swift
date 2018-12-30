//
//  NetflixCredentials.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/16/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import Foundation

///A protocol for creating a Netflix Credential
protocol NetflixCredentialProtocol: UserCredentialProtocol {
    ///The Netflix ID provided by a valid Netflix login.
    var netflixID: String? { get set }
    ///The Secure Netflix ID provided by a valid Netflix login.
    var secureNetflixID: String? { get set }
}

///A class for representing Netflix Credentials
class NetflixCredential: NetflixCredentialProtocol {
    
    ///Definitision of the IDs used for the Storage Items. This is for quick unified identification.
    struct RequiredIDs {
        ///The IDs expected for the Cookie.
        enum Cookie: String, CaseIterable {
            ///The ID epected for the Cookie value of Netflix ID.
            case netflixID = "NetflixId"
            ///The ID expected for the Cooke value of Secure Netflix ID.
            case secureNetflixID = "SecureNetflixId"
        }
        
        ///The IDs expected to be used as the Name field in the array of `CredentialStorageItems` returned to the `UserCredentialStore`.
        enum Credential: String {
            ///The ID for Netflix ID.
            case netflixID = "NetflixId"
            ///The ID for the Secure Netflix ID.
            case secureNetflixID = "SecretNetflixID"
        }
    }
    
    ///Internal storage for the Netflix ID.
    public var netflixID: String?
    ///Internal storage for the Secure Netflix ID.
    public var secureNetflixID: String?
    
    //MARK: - Init functions
    @available (iOS 2.0, *)
    init?(from cookies: [HTTPCookie]) {
        if !parseCredentialFromCooke(cookies) {
            return nil
        }
    }
    
    init(netflixID: String?, secureNetflixID: String?) {
        self.netflixID = netflixID
        self.secureNetflixID = secureNetflixID
    }
    
    init() {
        self.netflixID = nil
        self.secureNetflixID = nil
    }
    
    
    //MARK: - Private Functions
    /**
     Deletes an entry in keychain for the `CredentialStorageItem`.
     
     - Parameter cookies: An array of `HTTPCookie`s to populate the `NetflixCredential`.
     - Returns: true if the credential was able to be populated from the provided cookies, false otherwise.
     */
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
                    self.secureNetflixID = item.value
                }
            }
        }
        
        return true
    }
}

extension NetflixCredential: UserCredentialStorageProtocol {
    func getListOfCredentialItemsToStore() -> [CredentialStorageItem] {
        let credentialItems = [
            CredentialStorageItem(name: RequiredIDs.Credential.netflixID.rawValue, value: self.netflixID, description: "The Netflix cookie used in requests"),
            CredentialStorageItem(name: RequiredIDs.Credential.secureNetflixID.rawValue, value: self.secureNetflixID, description: "The Secure Netflix cookie used in requests")
        ]
        
        return credentialItems
    }
    
    func restoreFromStorageItems(_ storageItems: [CredentialStorageItem]) {
        
        if storageItems.count < 2 {
            print("Warning: Minimum number of storage items not supplied")
        }
        
        for item in storageItems {
            switch item.name {
            case RequiredIDs.Credential.netflixID.rawValue:
                self.netflixID = item.value
            case RequiredIDs.Credential.secureNetflixID.rawValue:
                self.secureNetflixID = item.value
            default:
                print("NetflixCredential: Unknown credential item")
                continue
            }
        }
    }
}
extension NetflixCredential: Equatable {
    static func == (lhs: NetflixCredential, rhs: NetflixCredential) -> Bool {
        return ((lhs.netflixID == rhs.netflixID) && (lhs.secureNetflixID == lhs.secureNetflixID))
    }
}
