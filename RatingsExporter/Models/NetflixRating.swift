//
//  NetflixRating.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/30/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import Foundation

///A struct representing the individual rating items. Items with * are assumed types and might be wrong. Praise the crash Gods.
struct NetflixRating {
    ///Date of the Rating in UNIX timestamp for comparisons
    var comparableDate: Date
    ///A string of the rating date
    var date: String
    ///An integer value of the rating. This can be negative. Yes, I'm as irritated as you are reading that.
    var intRating: Int
    ///*The ID of the movie. Might need to use this to fetch box art some how
    var movieID: UInt
    ///The type of rating. I assume this refers to "stars" or "thumbs". Testing will be required to figure out the difference.
    var ratingType: ratingType // This should be an enum type
    ///The timestamp of when the item was fetched
    var timestamp: Date
    ///The title of the item the rating is for
    var title: String
    ///The rating you gave it. As far as I can tell this is a whole number, which can also be negative... yes. I'm still irritated.
    var yourRating: Int
    
    enum ratingType: String {
        case Star = "star"
    }
}
