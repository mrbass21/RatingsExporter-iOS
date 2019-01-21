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

///Fetches Netflix ratings
public final class RatingsFetcher {
    
    ///Errors that can be encountered while working with RatingsFetcher
    public enum RatingsFetcherError: Error, Equatable {
        ///The credentials provided were invalid.
        case invalidCredentials
    }
	
	///The delegate to inform of updates.
	public weak var delegate: RatingsFetcherDelegate?
	
    //NOTE: The session cannot be a let verb, because we need to inject cookies into it.
    ///The session to use when making a request.
    public var session: URLSession!
	
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
    public init(forCredential credential: NetflixCredential, with session: URLSession?) {
        
        //Set the credential
        self.credential = credential
        
        //Create the configuration
        let configuration: URLSessionConfiguration!
        
        if let session = session {
            //If we've been passed a session, get a copy of the current configuration
            configuration = session.configuration
        } else {
            configuration = URLSessionConfiguration.ephemeral
        }
        
        //Set the headers for the session
        setHeadersForSessionConfiguration(&configuration)
        
        //Inject the cookie values for the credential
        try? injectCookiesForSessionConfiguration(&configuration, forCredential: self.credential)
        
        //Finally create a session with the updated configuration
        self.session = URLSession(configuration: configuration)
    }
    
    /**
     Initialize a RatingsFetcher object. If the page is fetched, `didRetrieveList(list:)` is called, otherwise `errorFetchingRatingsForPage` is called.
     
     - Parameter page: The page number to fetch.
     */
    public func fetchRatings(page: UInt) {
        
        if activeTasks[page] != nil {
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
    
    //Private interface
    
    private func setHeadersForSessionConfiguration(_ sessionConfig: inout URLSessionConfiguration) {
        
        //Get a copy of the current headers
        var headers = sessionConfig.httpAdditionalHeaders
        let userAgentString = "RatingsExporter (https://github.com/mrbass21/RatingsExporter-iOS)(iPhone; CPU iPhone OS like Mac OS X) Version/0.1"
        
        if var headers = headers {
            //Update the headers
            headers["User-Agent"] = userAgentString
        } else {
            //There are no headers. Create a new dictionary
            headers = ["User-Agent": userAgentString]
        }
        
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
    private func injectCookiesForSessionConfiguration(_ sessionConfig: inout URLSessionConfiguration, forCredential credential: NetflixCredential) throws {
        
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
    private func didRetrieveList(list: NetflixRatingsList) {
        //Release the task. We're done.
        self.activeTasks[UInt(list.page)] = nil
        
        //return it to the delegate
        DispatchQueue.main.async {
            self.delegate?.didFetchRatings(list)
        }
    }
}
