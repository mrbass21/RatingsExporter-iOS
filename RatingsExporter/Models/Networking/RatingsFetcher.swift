//
//  RatingsFetcher.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/30/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//
import Foundation.NSURLSession

///Protocol that a RatingsFetcher implements.
public protocol RatingsFetcherProtocol: class {
	/**
	The returned ratings for a specific page.
	
	On a successful fetch, the completeion handler will be invoked with a `NetflixRatingsList`. Nil otherwise.
	
	- Parameter page: The page of ratings to fetch.
	- Parameter withCompletion: The completion handler invoked after a fetch.
	*/
	func fetchRatings(page: UInt, withCompletion: @escaping (NetflixRatingsList?) -> ()) -> URLSessionTask?
}

///Fetches Netflix ratings
public final class RatingsFetcher: NSObject, RatingsFetcherProtocol {
	
	///Errors that can be encountered while working with RatingsFetcher
	enum RatingsFetcherError: Error, Equatable {
		///The credentials provided were invalid.
		case invalidCredentials
	}
	
	enum SessionState: Equatable {
		case invalidated
		case willInvalidate
		case active(Timer?)
		
		public static func ==(lhs: SessionState, rhs: SessionState) -> Bool {
			switch (lhs, rhs) {
			case (.invalidated, .invalidated):
				return true
			case (.willInvalidate, .willInvalidate):
				return true
			case (let .active(lhsTimer), let .active(rhsTimer)):
				return lhsTimer === rhsTimer
			default:
				return false
			}
		}
	}
	
	private var activeTasks: [URLSessionTask] = []
	
	///The credentials to use for the fetch
	private let credential: NetflixCredential
	
	private var netflixSession: NetflixSessionProtocol
	
	
	public init<NetflixCredentialType: NetflixCredentialProtocol>
		(forCredential credential: NetflixCredentialType,
		with netflixSession: NetflixSessionProtocol) {
		
		//Set the credential
		self.credential = NetflixCredential(netflixID: credential.netflixID, secureNetflixID: credential.secureNetflixID)
		
		//Set the requested session configuration requested to be used
		self.netflixSession = netflixSession
		
		//Continue initialization
		super.init()
	}
	
	deinit {
		debugLog("Deinit")
		let _ = self.activeTasks.map {
			$0.cancel()
		}
		
		self.activeTasks.removeAll()
	}

//	public final func fetchRatings(page: UInt, withCompletion: @escaping (NetflixRatingsList?) -> ()) -> URLSessionTask?{
//		
//		guard let ratingsURL = URL(string: "\(Common.URLs.netflixRatingsURL)?pg=\(page)") else {
//			return nil
//		}
//		
//		let task = netflixSession.netflixRequest(url: ratingsURL) { (data, urlResponse, error) in
//			if let httpResponse = (urlResponse as? HTTPURLResponse) {
//				guard httpResponse.statusCode == 200  else {
//					//TODO: Make this a little more friendly for the consuming API
//					withCompletion(nil)
//					return
//				}
//					
//				if let responseData = data {
//					//Serialize the data
//					let json = try? JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any]
//					
//					if let json = json, let finalJson = json {
//						guard let ratings = NetflixRatingsList(json: finalJson) else {
//							withCompletion(nil)
//							return
//						}
//							
//						withCompletion(ratings)
//					}
//				}
//			}
//		}
//		
//		return task
//	}
}
