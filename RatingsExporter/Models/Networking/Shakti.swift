////
////  Shakti.swift
////  RatingsExporter
////
////  Created by Jason Beck on 2/26/19.
////  Copyright © 2019 Jason Beck. All rights reserved.
////

import Foundation.NSURL

protocol ShaktiProtocol {
	associatedtype CredentialType: NetflixCredentialProtocol
	
	///This object requires a network request to initialize. Calls will not succeed unless initialization is completed.
	///This variable stores the state of the Shakti object.
	var isInitialized: Bool {get}
	
	///The authURL fetched from Netflix.
	var authURL: String? {get}
	
	///The deployed Shakti version on Netflixs back end.
	var shaktiVersion: String? {get}
	
	/**
	Initialize the Shakti Object. Initialization is not complete until the `initializeShakti(:ShaktiInitCompletion)`
	or `initializeShaktiWithSession(:NetflixSession,:ShaktiInitCompletion)` is called. Once Shakti is initialized,
	`isInitialized` will return `true`. It will return `false` if Shakti is not initialized.
	
	The following functions are still available even if `isInitialized` is false:
	
	* fetchRatings
	* getBoxArt for DVD titles
	*/
	init(forCredential: CredentialType)
	
	/**
	Initializes Shakti using a default `NetflixSession`. The completion handler is called passing a Bool representing if Shakti
	initialized or not.
	
	The default session will be used for all subsequent calls and initializes it with the `willDownloadAssets` set to `true`.
	The initialization requires a network call to setup. If this fails for any reason, `isInitialized` will be set to false.
	
	The completion handler Bool will contain `true` if Shakti initialized properly, and false otherwise.
	
	The following functions are still available even if `isInitialized` is false:
	
	* fetchRatings
	* getBoxArt for DVD titles
	
	- Parameter completion: A completion handler that will fire once Shakti is properly initialized.
	The Bool option is set to true if Shakti was setup properly, and false otherwise.
	*/
	func initializeShakti(completion: @escaping (Bool) -> ())
	
	/**
	Initializes Shakti using the provided `NetflixSession`. The completion handler is called passing a Bool representing if Shakti
	initialized or not.
	
	The default session will be used for all subsequent calls and initializes it with the `willDownloadAssets` set to `true`.
	The initialization requires a network call to setup. If this fails for any reason, `isInitialized` will be set to false.
	
	The completion handler Bool will contain `true` if Shakti initialized properly, and false otherwise.
	
	The following functions are still available even if `isInitialized` is false:
	
	* fetchRatings
	* getBoxArt for DVD titles
	
	- Parameter completion: A completion handler that will fire once Shakti is properly initialized.
	The Bool option is set to true if Shakti was setup properly, and false otherwise.
	*/
	func initializeShaktiWithSession<NetflixSessionType: NetflixSessionProtocol>(_ session: NetflixSessionType?, completion: @escaping (Bool) -> ())

}

public final class Shakti<NetflixCredentialType: NetflixCredentialProtocol>: ShaktiProtocol {
	typealias CredentialType = NetflixCredentialType
	
	public typealias ShaktiInitCompletion = (Bool) -> ()
	
	var isInitialized: Bool {
		return authURL != nil
	}
	
	var authURL: String?
	var shaktiVersion: String?
	var netflixCredential: NetflixCredentialType
	
	private var netflixSession: NetflixSessionProtocol
	
	
	var tasks: URLSessionTask?
	
	public init(forCredential credential: NetflixCredentialType) {
		//Store the credential
		netflixCredential = credential
		
		//Create a NetflixSession for the calls.
		netflixSession = NetflixSession(withCredential: credential, willDownloadAssets: true)
	}
	
	deinit {
		debugLog("Deinit")
	}
	
	final public func initializeShakti(completion: @escaping ShaktiInitCompletion) {
		//Get the required data from Netflix
		//The "Change Plan" page. Just want a lightweight page that gets the global netflix react object
		let changePlanURL = URL(string: Common.URLs.netflixChangePlan)!
		
		let _ = netflixSession.netflixRequest(url: changePlanURL) { [weak self] (data, response, error) in
			guard (response as! HTTPURLResponse).statusCode == 200, let data = data else {
				debugLog("Unable to fetch account settings page!")
				return
			}
			
			//Find the global object
			let html = String(bytes: data, encoding: .utf8)!
			
			//How we find the start of the JSON
			let searchMatchStartElement = "netflix.reactContext = "
			let searchMatchEndElement = ";</script><script "
			
			
			//The indexes for the start and end of the string
			let globalJSONStartIndex = html.range(of: searchMatchStartElement)!
			let globalJSONEndIndex = html.range(of: searchMatchEndElement)!
			
			//Finally. The JSON!
			let globalJSON = String(html[globalJSONStartIndex.upperBound..<globalJSONEndIndex.lowerBound])
			
			//Remove the hex codes
			let finalJSON = globalJSON.deencodeHexToUTF8()
			
			let reactContext: [String: Any?] = try! JSONSerialization.jsonObject(with: finalJSON.data(using: .utf8)!, options: []) as! [String : Any?]
			
			self?.authURL = self?.getAuthURLFromReactContextJSON(reactContext)
			self?.shaktiVersion = self?.getShaktiVersionFromReactContextJSON(reactContext)
		
			completion(self?.isInitialized ?? false)
		}
	}
	
	final public func initializeShaktiWithSession<NetflixSessionType: NetflixSessionProtocol>(_ session: NetflixSessionType?, completion: @escaping ShaktiInitCompletion) {
		guard let session = session else {
			return
		}
		
		netflixSession = session
		
		initializeShakti(completion: completion)
	}
	
	/**
	Extracts the currently deployed Shakti version Netflix is using from the react context.
	
	- Parameter reactContext: A JSON object that represents the reactContext retrieved from any Netflix front-end page.
	- Returns: The ShaktVersion extracted from reactContext as a String, or nil if it was not found.
	*/
	final private func getShaktiVersionFromReactContextJSON(_ reactContext: [String: Any?]) -> String? {
		
		if let models = (reactContext["models"] as? [String: Any?]),
			let serverDefs = (models["serverDefs"] as? [String: Any?]),
			let serverDefData = (serverDefs["data"] as? [String: Any?]),
			let shaktiVersion = (serverDefData["BUILD_IDENTIFIER"] as? String) {
			return shaktiVersion
		}
		
		return nil
	}
	
	/**
	Extracts the currently AuthURL for the specific user profile from the react context.
	
	- Parameter reactContext: A JSON object that represents the reactContext retrieved from any Netflix front-end page.
	- Returns: The AuthURL extracted from reactContext as a String, or nil if it was not found.
	*/
	final private func getAuthURLFromReactContextJSON(_ reactContext: [String: Any?]) -> String? {
		if let models = (reactContext["models"] as? [String: Any?]),
			let userInfo = models["userInfo"] as? [String: Any?],
			let data = userInfo["data"] as? [String: Any?],
			let authURL: String? = data["authURL"] as? String? {
			
			return authURL
		}
		
		return nil
	}
	
	final func getRatingsList(page: UInt, completion: @escaping (NetflixRatingsList?) -> ()) -> URLSessionTask? {
		let ratingsFetcher = RatingsFetcher(forCredential: self.netflixCredential, with: self.netflixSession)
		let task = ratingsFetcher.fetchRatings(page: page) { (list) in
			debugLog("Downloaded page: \(page)")
			completion(list)
		}
		
		return task
	}
	
	
	//Private Interface
	private final func fetchRatings(page: UInt, withCompletion: @escaping (NetflixRatingsList?) -> ()) -> URLSessionTask?{
		
		guard let ratingsURL = URL(string: "\(Common.URLs.netflixRatingsURL)?pg=\(page)") else {
			return nil
		}
		
		let task = netflixSession.netflixRequest(url: ratingsURL) { (data, urlResponse, error) in
			if let httpResponse = (urlResponse as? HTTPURLResponse) {
				guard httpResponse.statusCode == 200  else {
					//TODO: Make this a little more friendly for the consuming API
					withCompletion(nil)
					return
				}
				
				if let responseData = data {
					//Serialize the data
					let json = try? JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any]
					
					if let json = json, let finalJson = json {
						guard let ratings = NetflixRatingsList(json: finalJson) else {
							withCompletion(nil)
							return
						}
						
						withCompletion(ratings)
					}
				}
			}
		}
		
		return task
	}
	
	final private func setBoxArtURLForRating(_ rating: inout NetflixRating) {
		
	}
}

extension Shakti: CustomStringConvertible {
	public var description: String {
		return "Shakti Version: \(self.shaktiVersion ?? "Not Found")\nAuth URL Set: \(self.authURL != nil)"
	}
}
