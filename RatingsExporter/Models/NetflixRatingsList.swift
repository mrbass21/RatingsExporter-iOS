//
//  NetflixRatings.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/30/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import Foundation.NSDate

///A Struct that represnts the outter wrapper of the returned JSON from Netflix
public struct NetflixRatingsList {
    ///I have no idea wht this variable is meant to represent.
    public var codeName: String
    ///The array of NetflixRating items.
    public var ratingItems: [NetflixRating]
    ///The number of NetflixRating items.
    public var totalRatings: Int
    ///The page number of results
    public var page: Int
    ///The number of items requested in the page request.
    public var numberOfRequestedItems: Int
    ///I'm not sure what track id refers to
    public var trackId: UInt
    ///The timezone of the request? Maybe the `NetflixRating.comparableDate` is relative to the fetched time zone?
    public var timeZoneAbbrev: String
}


extension NetflixRatingsList {
    public init?(json: [String: Any]) {
        
        //Pull out the code name
        guard let codeName = json["codeName"] as? String,
        let ratingItems = json["ratingItems"] as? [[String: Any]],
        let totalRatings = json["totalRatings"] as? Int,
        let page = json["page"] as? Int,
        let size = json["size"] as? Int,
        let trackId = json["trkid"] as? UInt,
        let timeZone = json["tz"] as? String
            else {
                return nil
            }
        
        //Set everything
        self.codeName = codeName
        self.totalRatings = totalRatings
        self.page = page
        self.numberOfRequestedItems = size
        self.trackId = trackId
        self.timeZoneAbbrev = timeZone
        self.ratingItems = Array()
        
        for rating in ratingItems {
            let movieRating = rating 
            
            //Parse out all the individual items
            guard let ratingType = movieRating["ratingType"] as? String,
                let typedRating = NetflixRating.ratingType(rawValue: ratingType),
                let title = movieRating["title"] as? String,
                let movieID = movieRating["movieID"] as? UInt,
                let yourRating = movieRating["yourRating"] as? Int, //Why isn't this unsigned? *Grumble grumble*
                let intRating = movieRating["intRating"] as? Int, //Why isn't this unsigned? *Grumble grumble*
                let date = movieRating["date"] as? String,
                let timestamp = movieRating["timestamp"] as? UInt,
                let comparableDate = movieRating["comparableDate"] as? Double else {
                    return nil
            }
            
            //Set them
            let comparableDateDate = Date(timeIntervalSince1970: comparableDate)
            self.ratingItems.append(NetflixRating(comparableDate: comparableDateDate, date: date, intRating: intRating, movieID: movieID, ratingType: typedRating, timestamp: timestamp, title: title, yourRating: yourRating))
            
        }
    }
}
