//
//  KeychainAccess.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/12/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

//Currently there are no common credential items to conform to, but this architechture is based off the concept
//of a base credential.

//MARK: - UserCredentialProtocol
///A protocol that defines a credential used for some service.
public protocol UserCredentialProtocol: Equatable {
}
