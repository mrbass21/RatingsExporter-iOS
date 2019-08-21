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
		
		//Continue initialization
		super.init()
		
		//Configure the connection
		createValidSession(withConfiguration: sessionConfig)
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
			createValidSession(withConfiguration: self.requestedConfiguration)
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
					let json = ((try? JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any]) as [String : Any]??)
					
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
	
	//Private interface
	
	/**
	Modifies the session provided `URLSessionConfiguration` to contain common headers that are used for `RatingsFetcher`.
	
	- Parameter sessionConfig: The `URLSessionConfiguration` to update with required headers.
	*/
	private final func setHeadersForSessionConfiguration(_ sessionConfig: inout URLSessionConfiguration) {
		
		//Get a copy of the current headers
		var headers: [AnyHashable: Any]
		if let existingHeaders = requestedConfiguration?.httpAdditionalHeaders {
			headers = existingHeaders
		}
		else {
			headers = [:]
		}
		
		//Set the user agent string
		let userAgentString = "RatingsExporter (https://github.com/mrbass21/RatingsExporter-iOS)(iPhone; CPU iPhone OS like Mac OS X) Version/0.1"
		
		//Update the headers
		headers["User-Agent"] = userAgentString
		
		//Modify it
		sessionConfig.httpAdditionalHeaders = headers
	}
	
	/**
	Injects the required cookies from a Netflix Credential into the session storage.
	
	- Parameter sessionConfig: The session configuration to inject the cookies into.
	- Parameter forCredential: The Netflix Credential to attempt to inject.
	
	- Throws:
	- RatingsFetcherError.invalidCredentials if netflixID or secureNetflixID are nil or the `HTTPCookie` creation failed.
	*/
	private final func injectCookiesForSessionConfiguration(_ sessionConfig: inout URLSessionConfiguration, forCredential credential: NetflixCredential) throws {
		
		//Check that we have what we need
		guard credential.netflixID != nil, credential.secureNetflixID != nil else {
			throw RatingsFetcherError.invalidCredentials
		}
		
		//Get a handle to the cookie store
		let cookieStore: HTTPCookieStorage!
		
		if let existingStore = sessionConfig.httpCookieStorage {
			cookieStore = existingStore
		} else {
			cookieStore = HTTPCookieStorage()
		}
		
		//Set the minimum values to create a cookie
		let cookieDict = [
			HTTPCookiePropertyKey.path: "/",
			HTTPCookiePropertyKey.domain: ".netflix.com"
		]
		
		//Create the cookies from the credential
		
		//Create NetflixId
		var netflixCookieDict = cookieDict
		netflixCookieDict[HTTPCookiePropertyKey.name] = "NetflixId"
		netflixCookieDict[HTTPCookiePropertyKey.value] = credential.netflixID!
		guard let netflixCookie = HTTPCookie(properties: netflixCookieDict) else {
			throw RatingsFetcherError.invalidCredentials
		}
		
		cookieStore.setCookie(netflixCookie)
		
		//Create SecureNetflixId
		var secureNetflixCookieDict: [HTTPCookiePropertyKey: Any] = cookieDict
		secureNetflixCookieDict[HTTPCookiePropertyKey.secure] = true
		secureNetflixCookieDict[HTTPCookiePropertyKey.name] = "SecureNetflixId"
		secureNetflixCookieDict[HTTPCookiePropertyKey.value] = credential.secureNetflixID!
		guard let secureNetflixCookie = HTTPCookie(properties: secureNetflixCookieDict) else {
			throw RatingsFetcherError.invalidCredentials
		}
		
		cookieStore.setCookie(secureNetflixCookie)
	}
	
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
	
	/**
	Creates a new session object, using the provided URLSessionConfiguration as a base for required settings.
	
	- Parameter configuration: The `URLSessionConfiguration` to create the session from.
	*/
	private final func createValidSession(withConfiguration configuration: URLSessionConfiguration?) {
		//Create the configuration
        var useConfiguration: URLSessionConfiguration!
		
		if let configuration = configuration {
			//If we've been passed a session, get a copy of the current configuration
			useConfiguration = configuration
		} else {
			useConfiguration = URLSessionConfiguration.ephemeral
		}
		
		//Set the headers for the session
		setHeadersForSessionConfiguration(&useConfiguration)
		
		//Inject the cookie values for the credential
		try? injectCookiesForSessionConfiguration(&useConfiguration, forCredential: self.credential)
		
		//Finally create a session with the updated configuration
		//NOTE: The session now contains a strong reference to this class! You _must_ invalidate the session when you are done!
		self.session = URLSession(configuration: useConfiguration, delegate: self, delegateQueue: nil)
		self.sessionState = .active(nil)
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
