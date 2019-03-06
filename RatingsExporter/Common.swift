//
//  Common.swift
//  RatingsExporter
//
//  Created by Jason Beck on 1/20/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//
import Foundation.NSURL

///A place for common difinitions that can be used throughout the application.
public struct Common {
	///String identifiers used throughout the application.
	public struct Identifiers {
		///Storyboard Segue identifiers.
		public struct Segue {
			///Identifier for the login view segue.
			public static let NetflixLoginSegue = "NetflixLoginSegue"
			///Identifier for the movie details segue.
			public static let MovieDetailsSegue = "MovieDetailsSegue"
		}
		
		///Storyboard identifiers
		public struct Storyboard {
			///Identifiter for the Netflix Login Controller
			public static let NetflixLoginController = "NetflixLoginViewController"
			///Identifier for the Ratings View Controller
			public static let RatingsViewController = "RatingsViewController"
			///Identifier for the Ratings Detail View Controller
			public static let RatingsDetailViewController = "RatingsDetailViewController"
		}
		
		///TableViewCell identifiers.
		public struct TableViewCell {
			///Identifier for the filled out netflix ratings cell.
			static let NetflixRatingsCell = "NetflixRatingsCell"
			///Identifier for the laoding rating netflix cell.
			static let LoadingRatingCell = "LoadingRatingsCell"
		}
		
		//Why is this an enum? Becuause it has additional logic to enforce that all cookies identified below
		//_must_ be found, or the credential harvest is considered a failure. Creating an enum exposed a simple
		//and easy interface to enforce this.
		
		///The IDs expected for the Cookie.
		public enum Cookie: String, CaseIterable {
			///The ID epected for the Cookie value of Netflix ID.
			case netflixID = "NetflixId"
			///The ID expected for the Cooke value of Secure Netflix ID.
			case secureNetflixID = "SecureNetflixId"
		}
	}
	
	///URLs used on Netflixs back end.
	public struct URLs {
		///The URL where the ratings are fetched from.
		public static var netflixRatingsURL: String  {
			return "https://www.netflix.com/api/shakti/\(NetflixAPIConstants.shaktiVersion)/ratinghistory"
		}
		///The login URL. This is where users are directed to login.
		static let netflixLoginURL = "https://www.netflix.com/login"
		///The redirect URL users are sent to if they have a valid login.
		static let netflixSuccessRedirectURL = "https://www.netflix.com/browse"
		///The base URL for DVD box art
		static let netflixDVDBoxArtBaseURL = "https://assets.nflxext.com/us/boxshots"
		///The "Your Accounts" page. This is used to resolve the global netflix object for authentication with Shakti.
		static let netflixChangePlan = "https://www.netflix.com/ChangePlan"
	}
	
	///Constants used to talk to the Netflix API
	public struct NetflixAPIConstants {
		///The version of the shakti API to use.
		public static let shaktiVersion = "v69746888"
	}
}


//Define some debug helpers
///Prints to log nearly like Print() does, only if we are in the debug configuration. No array if items is taken because it won't do a pretty print currently.
public func debugLog(_ items: Any, file: String = #file, lineNumber: UInt = #line ,separator: String = " ", terminator: String = "\n") {
	if _isDebugAssertConfiguration() {
		let fileURL: URL = URL(fileURLWithPath: file)
		print("file: \(fileURL.lastPathComponent) line: \(lineNumber) \(items)", separator: separator, terminator: terminator)
	}
}

