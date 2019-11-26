//
//  Shakti.swift
//  RatingsExporter
//
//  Created by Jason Beck on 11/25/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

struct Shakti: Decodable {
    var version: String {
        return models.abContext.data.headers.uiVersion
    }
    
    var authURL: String {
        return models.memberContext.data.userInfo.authURL
    }
    
    //Netflix's bullshit JSON structure
    private var models: model
    
    struct model: Decodable {
        var abContext: abContext
        var memberContext: memberContext
        
        struct abContext: Decodable {
            var data: data
            
            struct data: Decodable {
                var headers: headers
                
                struct headers: Decodable {
                    var uiVersion: String
                    
                    enum CodingKeys: String, CodingKey {
                        case uiVersion = "X-Netflix.uiVersion"
                    }
                }
            }
        }
        
        struct memberContext: Decodable {
            var data: data
            
            struct data: Decodable {
                var userInfo: userInfo
                
                struct userInfo: Decodable {
                    var authURL: String
                }
            }
        }
    }
}
