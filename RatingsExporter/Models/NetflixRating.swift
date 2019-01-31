//
//  NetflixRating.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/30/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import Foundation.NSDate

///A struct representing the individual rating items. Items with * are assumed types and might be wrong. Praise the crash Gods.
public struct NetflixRating {
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
	var timestamp: UInt
	///The title of the item the rating is for
	var title: String
	///The rating you gave it. As far as I can tell this is a whole number, which can also be negative... yes. I'm still irritated.
	var yourRating: Double
	
	public enum ratingType: String {
		case star = "star"
	}
	
	/**
	Initialize a NetflixRating object.
	
	- Parameter comparableDate: Unix Timestamp of the rating date for comparisons. Defaults to January 1, 1970 if one is not provided.
	- Parameter date: String representation of the ratinf date. Defaults to 1/1/19 if one is not provided.
	- Parameter intRating: An Int representation of the rating. For example, 10 represents a rating if 1.0. Negative numbers are possible.
	Defaults to 0 if a value is not provided.
	- Parameter movieID: An int value representing the Netflix internal id of the movie. Probably not negative. Defaults to 0 if no value is provided.
	- Parameter ratingType: The type of rating. Currently I've only reverse engineered the star type. Coule be a "thumb" or other type.
	- Parameter timestamp: A Unix Timestamp of when the rating was last fetched.
	- Parameter title: The title of the movie.
	- Parameter yourRating: The Double representation of your rating.
	- Returns: true if the credential was able to be populated from the provided cookies, false otherwise.
	*/
	public init(comparableDate: Date = Date.init(timeIntervalSince1970: 0), date: String = "1/1/1970", intRating: Int = 0, movieID: UInt = 0, ratingType: ratingType = .star, timestamp: UInt = 0, title: String = "", yourRating: Double = 0) {
		self.comparableDate = comparableDate
		self.date = date
		self.intRating = intRating
		self.movieID = movieID
		self.ratingType = ratingType
		self.timestamp = timestamp
		self.title = title
		self.yourRating = yourRating
	}
}
