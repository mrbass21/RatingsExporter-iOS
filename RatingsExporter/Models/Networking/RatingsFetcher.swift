//
//  RatingsFetcher.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/30/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//
import Foundation.NSURLSession

///Notifies the delegate of calls in the RatingsFetcher lifecycle.
protocol RatingsFetcherDelegate: class {
	/**
	The returned ratings for a specific page.
	
	- Parameter ratings : The list of retrieved ratings.
	*/
	func didFetchRatings(_ ratings: NetflixRatingsList)
	
	//TODO: Pass the error, maybe?.
	/**
	An error occured fetching a specific page.
	
	- Parameter page : The page that failed to retrieve.
	*/
	func errorFetchingRatingsForPage(_ page: UInt)
}

///Protocol that a RatingsFetcher implements.
public protocol RatingsFetcherProtocol: class {
	var authURL: String? {get set}
	func fetchRatings(page: UInt)
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
	
	///The delegate to inform of updates.
	weak var delegate: RatingsFetcherDelegate?
	
	var sessionState: SessionState = .invalidated
	
	var requestedConfiguration: URLSessionConfiguration?
	
	private var activeTasks: [URLSessionTask] = []
	
	///The credentials to use for the fetch
	private let credential: NetflixCredential
	//private var shakti: ShaktiProtocol?
	
	public var authURL: String?
	
	var netflixSession: NetflixSessionProtocol
	
	/**
	Initialize a RatingsFetcher object.
	
	- Parameter forCredential: The `NetflixCredential` to use for fetching ratings.
	- Parameter with: An URLSession to use for fetching. If none is provided, a default URLSession (not default) is created with
	ephemeral storage. If a session is provided, RatingsFetcher will try and inject the credentials into the data store
	for the provided session.
	*/
	public init<NetflixCredentialType: NetflixCredentialProtocol>(forCredential credential: NetflixCredentialType) {
		
		//Set the credential
		self.credential = NetflixCredential(netflixID: credential.netflixID, secureNetflixID: credential.secureNetflixID)
		
		//Create a new session
		self.netflixSession = NetflixSession(withCredential: credential)
		
		//Continue initialization
		super.init()
	}
	
	public init<NetflixCredentialType: NetflixCredentialProtocol,
		netflixSessionType: NetflixSessionProtocol>
		(forCredential credential: NetflixCredentialType,
		 with netflixSession: netflixSessionType) {
		
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
	
	/**
	Initialize a RatingsFetcher object. If the page is fetched, `didRetrieveList(list:)` is called, otherwise `errorFetchingRatingsForPage` is called.
	
	- Parameter page: The page number to fetch.
	*/
	public final func fetchRatings(page: UInt) {
		
		let ratingsURL = URL(string: "\(Common.URLs.netflixRatingsURL)?pg=\(page)")
		
		if let ratingsURL = ratingsURL {
			let task = netflixSession.netflixRequest(url: ratingsURL) { [weak self] (data, urlResponse, error) in
				if let httpResponse = (urlResponse as? HTTPURLResponse) {
					
					if httpResponse.statusCode != 200 {
						//TODO: Make this a little more friendly for the consuming API
						DispatchQueue.main.async {
							self?.delegate?.errorFetchingRatingsForPage(page)
						}
					}
					
					if let responseData = data {
						//Serialize the data
						let json = try? JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any]
						
						if let json = json, let finalJson = json {
							guard let ratings = NetflixRatingsList(json: finalJson) else {
								self?.delegate?.errorFetchingRatingsForPage(page)
								return
							}
							
							self?.didRetrieveList(list: ratings)
						}
					}
				}
			}
			if let task = task {
				self.activeTasks.insert(task, at: Int(page))
			}
		}
		
		
	}
	
	public func getStreamingBoxArtForTitle(_ title: Int) {
		
	}
	
//	private final func initShakti() {

//	}
//
	//Private interface
	
	
	
	
	
	/**
	Manages the activeTasks and alerts the delegate of success.
	
	- Parameter list: The list of returned Netflix ratings.
	*/
	private final func didRetrieveList(list: NetflixRatingsList) {
		//Release the task. We're done.
		self.activeTasks.remove(at: list.page)
		
		//return it to the delegate
		DispatchQueue.main.async {
			self.delegate?.didFetchRatings(list)
		}
	}
	
	private final func invalidateAndCancelSession() {
		//session.invalidateAndCancel()
		sessionState = .willInvalidate
	}
	
	private final func invalidateButFinishSession() {
		//session.finishTasksAndInvalidate()
		sessionState = .willInvalidate
	}
}

///Handling invalidation
extension RatingsFetcher {
//	public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
//		if session === self.session && sessionState != .invalidated {
//			sessionState = .invalidated
//		}
//	}
}
