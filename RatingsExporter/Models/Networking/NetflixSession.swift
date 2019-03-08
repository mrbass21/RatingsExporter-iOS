//
//  NetflixSession.swift
//  RatingsExporter
//
//  Created by Jason Beck on 3/4/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//
import Foundation.NSURLSession

/*
This object is only intended to do something _all_ connections must do. Right now this includes:
	* Certificate Pinning
	* Injecting Credentials
	* Setting the User Agent

Only add logic to this object if all Netflix connections need it!
*/

public protocol NetflixSessionProtocol {
	///Determines if it should check additionally for the Asset certificate pin.
	///If this is not set, all requests for the assets will fail.
	var willDownloadAssets: Bool {get set}
	
	///URLSession to use. Otherwise, a ephimeral default connection is used
	var sessionToUse: URLSession? {get set}
	
	///Performs a request that handles cert pinning
	func netflixRequest(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> () ) -> URLSessionTask?
	
}

final class NetflixSession: NSObject, NetflixSessionProtocol {
	
	public enum NetflixSessionError: Error {
		case invalidCredentials
	}
	
	public var willDownloadAssets: Bool
	
	///Session that will be used for connections.
	var sessionToUse: URLSession?
	
	private var dataTasks: [URLSessionTask] = []
	
	init<NetflixCredentialType: NetflixCredentialProtocol>(withCredential credential: NetflixCredentialType,
														   willDownloadAssets: Bool = false) {
		self.willDownloadAssets = willDownloadAssets
		super.init()
	
		sessionToUse = createValidSession(withConfiguration: nil, usingNetflixCredential: credential)
	}
	
	deinit {
		debugLog("De-initializing")
	}
	
	public func netflixRequest(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> () ) -> URLSessionTask? {
		let task = sessionToUse?.dataTask(with: url, completionHandler: { (data, urlResponse, error) in
			completion(data, urlResponse, error)
		})
		
		return task
	}
	
	
	/**
	Creates a new session object, using the provided URLSessionConfiguration as a base for required settings.
	
	- Parameter configuration: The `URLSessionConfiguration` to create the session from.
	*/
	private final func createValidSession<NetflixCredentialType: NetflixCredentialProtocol>(withConfiguration configuration: URLSessionConfiguration?,
										  usingNetflixCredential credential: NetflixCredentialType) -> URLSession? {
		//Create the configuration
		let useConfiguration: URLSessionConfiguration!
		
		if let configuration = configuration {
			//If we've been passed a session, get a copy of the current configuration
			useConfiguration = configuration
		} else {
			useConfiguration = URLSessionConfiguration.ephemeral
		}
		
		//Set the headers for the session
		setHeadersForSessionConfiguration(&useConfiguration)
		
		//Inject the cookie values for the credential
		try? injectCookiesForSessionConfiguration(&useConfiguration, forCredential: credential)
		
		//Finally create a session with the updated configuration
		//NOTE: The session now contains a strong reference to this class! You _must_ invalidate the session when you are done!
		return URLSession(configuration: useConfiguration, delegate: self, delegateQueue: nil)
	}
	
	/**
	Injects the required cookies from a Netflix Credential into the session storage.
	
	- Parameter sessionConfig: The session configuration to inject the cookies into.
	- Parameter forCredential: The Netflix Credential to attempt to inject.
	
	- Throws:
	- NetflixSessionError.invalidCredentials if netflixID or secureNetflixID are nil or the `HTTPCookie` creation failed.
	*/
	private final func injectCookiesForSessionConfiguration<NetflixCredentialType: NetflixCredentialProtocol>(_ sessionConfig: inout URLSessionConfiguration,
																											  forCredential credential: NetflixCredentialType) throws {
		
		//Check that we have what we need
		guard credential.netflixID != nil, credential.secureNetflixID != nil else {
			throw NetflixSessionError.invalidCredentials
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
			throw NetflixSessionError.invalidCredentials
		}
		
		cookieStore.setCookie(netflixCookie)
		
		//Create SecureNetflixId
		var secureNetflixCookieDict: [HTTPCookiePropertyKey: Any] = cookieDict
		secureNetflixCookieDict[HTTPCookiePropertyKey.secure] = true
		secureNetflixCookieDict[HTTPCookiePropertyKey.name] = "SecureNetflixId"
		secureNetflixCookieDict[HTTPCookiePropertyKey.value] = credential.secureNetflixID!
		guard let secureNetflixCookie = HTTPCookie(properties: secureNetflixCookieDict) else {
			throw NetflixSessionError.invalidCredentials
		}
		
		cookieStore.setCookie(secureNetflixCookie)
	}
	
	/**
	Modifies the session provided `URLSessionConfiguration` to contain common headers that are used for `RatingsFetcher`.
	
	- Parameter sessionConfig: The `URLSessionConfiguration` to update with required headers.
	*/
	private final func setHeadersForSessionConfiguration(_ sessionConfig: inout URLSessionConfiguration) {
		
		//Get a copy of the current headers
		var headers: [AnyHashable: Any]
//		if let existingHeaders = requestedConfiguration?.httpAdditionalHeaders {
//			headers = existingHeaders
//		}
//		else {
			headers = [:]
		//}
		
		//Set the user agent string
		let userAgentString = "RatingsExporter (https://github.com/mrbass21/RatingsExporter-iOS)(iPhone; CPU iPhone OS like Mac OS X) Version/0.1"
		
		//Update the headers
		headers["User-Agent"] = userAgentString
		
		//Modify it
		sessionConfig.httpAdditionalHeaders = headers
	}
}


///Certificate Pinning
extension NetflixSession: URLSessionDelegate {
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
		
		if isServerTrusted && certificateIsExpected(certificate) {
			let credential = URLCredential(trust: serverTrust)
			completionHandler(.useCredential, credential)
		} else {
			debugLog("Certificate not trusted. Connection dropped.")
			completionHandler(.cancelAuthenticationChallenge, nil)
		}
	}
	
	@available (iOS 10.0, *)
	private final func certificateIsExpected(_ certificate: SecCertificate) -> Bool {
		
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
		
		if willDownloadAssets {
			guard let knownNetflixAssetsCertPath = Bundle.main.path(forResource: "netflix-assets", ofType: "cer"),
				let expectedAssetsCertificateData = try? Data(contentsOf: URL(fileURLWithPath: knownNetflixAssetsCertPath)),
				let expectedAssetsCertificate = SecCertificateCreateWithData(nil, expectedAssetsCertificateData as CFData),
				let providedAssetsCertPubKey = SecCertificateCopyKey(certificate),
				let expectedAssetsCertPubKey = SecCertificateCopyKey(expectedAssetsCertificate),
				let providedAssetsCertPubKeyData = SecKeyCopyExternalRepresentation(providedAssetsCertPubKey, nil),
				let expectedAssetsCertPubKeyData = SecKeyCopyExternalRepresentation(expectedAssetsCertPubKey, nil) else {
					//Could not load the expected certificate. Return failure.
					debugLog("Unable to load requred data to compare assets certificates")
					return false
			}
			
			//Check that the public keys match for assets cert
			if providedAssetsCertPubKeyData == expectedAssetsCertPubKeyData {
				debugLog("Certificates match")
				return true
			}
		}
		
		//Only one case results in `true`, and if we got here, we didn't hit it.
		debugLog("Certificates did not match")
		return false
	}
}
