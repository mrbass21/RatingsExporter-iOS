//
//  NetflixRatings.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/30/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import Foundation

///A Struct that represnts the outter wrapper of the returned JSON from Netflix
struct NetflixRatings {
    ///I have no idea wht this variable is meant to represent.
    var codeName: String
    ///The array of NetflixRating items
    var ratingItems: [NetflixRating]
    ///The number of NetflixRating items
    var totalRatings: UInt
    ///The page number of results
    var page: UInt
    ///The number of items per page.
    var size: UInt
    ///I'm not sure what track id refers to
    var trkid: UInt
    ///The timezone of the request? Maybe the `NetflixRating.comparableDate` is relative to the fetched time zone?
    var tz: String
}
