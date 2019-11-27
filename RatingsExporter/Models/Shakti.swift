//
//  Shakti.swift
//  RatingsExporter
//
//  Created by Jason Beck on 11/25/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//
import Foundation


protocol ShaktiProtocol {
    var streamingBaseURL: URL {get}
}

struct Shakti: Decodable, ShaktiProtocol {
    
    public var streamingBaseURL: URL {
        return URL(string: "\(models.serverDefs.data.API_ROOT)/shakti/\(models.serverDefs.data.BUILD_IDENTIFIER)")!
    }
    
//    var version: String {
//        return models.abContext.data.headers.uiVersion
//    }
//
//    var authURL: String {
//        return models.memberContext.data.userInfo.authURL
//    }
    
    //Netflix's bullshit JSON structure
    private var models: model
    
    struct model: Decodable {
        var memberContext: memberContext
        var serverDefs: serverDefs
        
        ///Member information section
        struct memberContext: Decodable {
            var data: data
            
            struct data: Decodable {
                var userInfo: userInfo
                
                struct userInfo: Decodable {
                    var authURL: String         // The auth url for this profile
                    var name: String            // The name of the profile
                    var userGuid: String        // The GUID for the profile
                }
            }
        }
        
        ///Server Definition section
        struct serverDefs: Decodable {
            var data: data
            
            struct data: Decodable {
                var BUILD_IDENTIFIER: String    // Identifies the API build number used in the URL
                var API_ROOT: String            // Identifies the root API path
                var DVD_CO: String              // The DVD api endpoint? Does not use the BUILD_IDENTIFIER
            }
        }
    }
}

extension Shakti: CustomStringConvertible {
    var description: String {
        return  """
                Public:
                
                Streaming Base URL:\t \(streamingBaseURL)
                
                Internal:
                
                Name:\t\t\t\t \(models.memberContext.data.userInfo.name)
                User Guid:\t\t\t \(models.memberContext.data.userInfo.userGuid)
                Auth URL:\t\t\t \(models.memberContext.data.userInfo.authURL)
                API Root:\t\t\t \(models.serverDefs.data.API_ROOT)
                DVD Root:\t\t\t \(models.serverDefs.data.DVD_CO)
                Build Identifier:\t \(models.serverDefs.data.BUILD_IDENTIFIER)
                """
    }
    
}
