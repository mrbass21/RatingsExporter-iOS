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
    var secureNetflixID: String? { get set }
}

class NetflixCredential: NetflixCredentialProtocol {
    
    struct RequiredIDs {
        enum Cookie: String, CaseIterable {
            case netflixID = "NetflixId"
            case secureNetflixID = "SecureNetflixId"
        }
        
        enum Credential: String {
            case netflixID = "NetflixId"
            case secureNetflixID = "SecretNetflixID"
        }
    }
    
    public var netflixID: String?
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
