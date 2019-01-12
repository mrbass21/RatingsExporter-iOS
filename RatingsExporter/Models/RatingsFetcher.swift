//
//  RatingsFetcher.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/30/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//
import Foundation.NSURLSession

protocol RatingsFetcherDelegate: class {
	func didFetchRatings(ratings: NetflixRatingsList)
	func errorFetchingRatingsForPage(page: UInt)
}

///Fetches Netflix ratings
class RatingsFetcher {
    
    ///Errors that can be encountered while working with RatingsFetcher
    public enum RatingsFetcherError: Error, Equatable {
        case invalidCredentials
    }
	
	//Store the delegate
	public weak var delegate: RatingsFetcherDelegate!
	
    ///The session to use when making a request
    public var session: URLSession!
	
	///The array of currently executing dataTasks
	private var activeTasks: [URLSessionDataTask] = []
    
    ///The credentials to use for the fetch
    let credential: NetflixCredential
    
    struct URLs {
        static var RatingsURL = "https://www.netflix.com/api/shakti/va5e8014f/ratinghistory"
    }
    
    init(forCredential credential: NetflixCredential, with session: URLSession?) {
        
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
    
    ///Fetches one page of ratings
    public func fetchRatings(page: UInt) {
        
        let ratingsURL = URL(string: "\(URLs.RatingsURL)?pg=\(page)")!
        
        let dataTask = session.dataTask(with: ratingsURL, completionHandler: { [weak self](data: Data?, response: URLResponse?, error: Error?) in
            if let httpResponse = (response as? HTTPURLResponse) {
                
                if httpResponse.statusCode != 200 {
					//TODO: Make this a little more friendly for the consuming API
                    DispatchQueue.main.async {
                        self?.delegate?.errorFetchingRatingsForPage(page: page)
                    }
                }
                
                if let responseData = data {
                    //Serialize the data
                    let json = try? JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any]
                    
                    if let json = json, let finalJson = json {
                        guard let ratings = NetflixRatingsList(json: finalJson) else {
                            self?.delegate?.errorFetchingRatingsForPage(page: page)
                            return
                        }

                        //return it to the delegate
                        DispatchQueue.main.async {
                            self?.delegate?.didFetchRatings(ratings: ratings)
                        }
                    }
                    
					
                }
            }
        })
        dataTask.resume()
		activeTasks.append(dataTask)
    }
    
    //Private interface
    
    private final func setHeadersForSessionConfiguration(_ sessionConfig: inout URLSessionConfiguration) {
        
        //Get a copy of the current headers
        var headers = sessionConfig.httpAdditionalHeaders
        
        if var headers = headers {
            //Update the headers
            headers["User-Agent"] = "RatingsExporter (https://github.com/mrbass21/RatingsExporter-iOS)(iPhone; CPU iPhone OS like Mac OS X) Version/0.1"
        } else {
            //There are no headers. Create a new dictionary
            headers = ["User-Agent": "RatingsExporter (https://github.com/mrbass21/RatingsExporter-iOS)(iPhone; CPU iPhone OS like Mac OS X) Version/0.1"]
        }
        
        //Modify it
        sessionConfig.httpAdditionalHeaders = headers
    }
    
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
}
