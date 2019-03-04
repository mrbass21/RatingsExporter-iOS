//
//  RatingsFetcher.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/30/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//
import Foundation.NSURLSession

///Notifies the delegate of calls in the RatingsFetcher lifecycle.
public protocol RatingsFetcherDelegate: class {
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
	public enum RatingsFetcherError: Error, Equatable {
		///The credentials provided were invalid.
		case invalidCredentials
	}
	
	public enum SessionState: Equatable {
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
	public weak var delegate: RatingsFetcherDelegate?
	
	//NOTE: The session cannot be a let verb, because we need to inject cookies into it.
	///The session to use when making a request.
	public var session: URLSession!
	
	private var sessionState: SessionState = .invalidated
	
	private var requestedConfiguration: URLSessionConfiguration?
	
	///The array of currently executing dataTasks.
	private var activeTasks: [UInt : URLSessionDataTask] = [:]
	
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
	public init(forCredential credential: NetflixCredential, with sessionConfig: URLSessionConfiguration?) {
		
		//Set the credential
		self.credential = credential
		
		//Set the requested session configuration requested to be used
		self.requestedConfiguration = sessionConfig
		
		netflixSession = NetflixSession(withCredential: credential)
		
		//Continue initialization
		super.init()
		
		let _ = netflixSession.netflixRequest(url: URL(string: Common.URLs.netflixRatingsURL)!) { (data, response, error) in
			debugLog("Data Task lived Long Enough!")
		}
		
//		//Configure the connection
//		createValidSession(withConfiguration: sessionConfig)
		
		//Get credentials for the Shakti resources
		
		//initShakti()
	}
	
	/**
	Initialize a RatingsFetcher object. If the page is fetched, `didRetrieveList(list:)` is called, otherwise `errorFetchingRatingsForPage` is called.
	
	- Parameter page: The page number to fetch.
	*/
	public final func fetchRatings(page: UInt) {
		
		//Check if we are already fetching this page and return back nil if we are.
		if activeTasks[page] != nil {
			return
		}
		
		//Check that the session is still valid
		if sessionState == SessionState.invalidated {
			debugLog("The session is currently invalid. Creating a new one.")
			//createValidSession(withConfiguration: self.requestedConfiguration)
		} else if sessionState == .willInvalidate {
			//TODO: Inform delegate that we are waiting for a session to invalidate and inform when we are ready to create a new session again?
			debugLog("The session is starting to be invalidated, but not yet invalidated. Doing nothing.")
			return
		}
		
		debugLog("Downloading page \(page)")
		
		let ratingsURL = URL(string: "\(Common.URLs.netflixRatingsURL)?pg=\(page)")!
		
		let dataTask = session.dataTask(with: ratingsURL, completionHandler: { [weak self](data: Data?, response: URLResponse?, error: Error?) in
			if let httpResponse = (response as? HTTPURLResponse) {
				
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
		})
		dataTask.resume()
		activeTasks[page] = dataTask
	}
	
	public func getStreamingBoxArtForTitle(_ title: Int) {
		
	}
	
	private final func initShakti() {
		//The "Change Plan" page. Just want a lightweight page that gets the global netflix react object
		let changePlan = URL(string: Common.URLs.netflixChangePlan)!
		
		activeTasks[0] = session.dataTask(with: changePlan, completionHandler: { (data, response, error) in
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
			
			let json: [String: Any?] = try! JSONSerialization.jsonObject(with: finalJSON.data(using: .utf8)!, options: []) as! [String : Any?]
			
			//self.shakti = Shakti(fromReactContextJSON: json)
			
			//debugLog("Auth URL: \(self.shakti?.authURL)\nShakti Version: \(self.shakti?.shaktiVersion)")
			
			self.activeTasks[0] = nil
		})
		
		activeTasks[0]?.resume()
	}
	
	//Private interface
	
	
	
	
	
	/**
	Manages the activeTasks and alerts the delegate of success.
	
	- Parameter list: The list of returned Netflix ratings.
	*/
	private final func didRetrieveList(list: NetflixRatingsList) {
		//Release the task. We're done.
		self.activeTasks[UInt(list.page)] = nil
		
		if activeTasks.count <= 0 {
			debugLog("Invalidating URLSession")
			invalidateButFinishSession()
		}
		
		//return it to the delegate
		DispatchQueue.main.async {
			self.delegate?.didFetchRatings(list)
		}
	}
	
	private final func invalidateAndCancelSession() {
		session.invalidateAndCancel()
		sessionState = .willInvalidate
	}
	
	private final func invalidateButFinishSession() {
		session.finishTasksAndInvalidate()
		sessionState = .willInvalidate
	}
}

///Certificate Pinning
extension RatingsFetcher: URLSessionDelegate {
	public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		debugLog("Received an auth challenge!")
		
		//We need a server trust. If we don't have it, bail.
		guard let serverTrust = challenge.protectionSpace.serverTrust,
			let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
				completionHandler(.cancelAuthenticationChallenge, nil)
				return
		}
		
		//Set policies for domain name check
		let policies = NSMutableArray()
		policies.add(SecPolicyCreateSSL(true, (challenge.protectionSpace.host as CFString)))
		SecTrustSetPolicies(serverTrust, policies)
		
		completionHandler(.performDefaultHandling, nil)
		
		//Evaluate Trust
		var result: SecTrustResultType = .invalid
		SecTrustEvaluate(serverTrust, &result)
		
		let isServerTrusted: Bool = (result == .proceed || result == .unspecified)
		
		if isServerTrusted && certificateIsValid(certificate) {
			let credential = URLCredential(trust: serverTrust)
			completionHandler(.useCredential, credential)
		} else {
			debugLog("Certificate not trusted. Connection dropped.")
			completionHandler(.cancelAuthenticationChallenge, nil)
		}
	}
	
	@available (iOS 10.0, *)
	private final func certificateIsValid(_ certificate: SecCertificate) -> Bool {
		
		//Load the expected certificate.
		guard let knownNetflixCertPath = Bundle.main.path(forResource: "netflix", ofType: "cer"),
			let expectedCertificateData = try? Data(contentsOf: URL(fileURLWithPath: knownNetflixCertPath)),
			let expectedCertificate = SecCertificateCreateWithData(nil, expectedCertificateData as CFData),
			let providedCertPubKey = SecCertificateCopyKey(certificate),
			let expectedCertPubKey = SecCertificateCopyKey(expectedCertificate),
			let providedCertPubKeyData = SecKeyCopyExternalRepresentation(providedCertPubKey, nil),
			let expectedCertPubKeyData = SecKeyCopyExternalRepresentation(expectedCertPubKey, nil) else {
				//Could not load the expected certificate. Return failure.
				debugLog("Unable to load requred data to compare certificates")
				return false
		}
		
		//Check that the public keys match
		if providedCertPubKeyData == expectedCertPubKeyData {
			debugLog("Certificates match")
			return true
		}
		
		//Only one case results in `true`, and if we got here, we didn't hit it.
		debugLog("Certificates did not match")
		return false
	}
}

///Handling invalidation
extension RatingsFetcher {
	public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
		if session === self.session && sessionState != .invalidated {
			sessionState = .invalidated
		}
	}
}
