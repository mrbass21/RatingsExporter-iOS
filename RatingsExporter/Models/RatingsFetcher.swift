//
//  RatingsFetcher.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/30/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import Foundation

///Fetches Netflix ratings
class RatingsFetcher {
    
    ///The session to use when making a request
    var session: URLSession
    
    ///The credentials to use for the fetch
    let credential: NetflixCredential
    
    struct URLs {
        static var RatingsURL = "https://www.netflix.com/api/shakti/va5e8014f/ratinghistory"
    }
    
    init(forCredential credential: NetflixCredential, with session: URLSession?) {
        self.credential = credential
        
        if let session = session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            //configuration.httpCookieStorage.
            self.session = URLSession(configuration: configuration)
        }
    }
    
    ///Fetches one page of ratings
    public func fetchRatings(page: UInt) {
        
        let ratingsURL = URL(string: "\(URLs.RatingsURL)?pg=\(page)")!
        
        let dataTask = session.dataTask(with: ratingsURL, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            if let httpResponse = (response as? HTTPURLResponse) {
                if httpResponse.statusCode != 200 {
                    print("Unexpected return code: \(httpResponse.statusCode)")
                }
                
                if let responseData = data {
                    print("\(String(describing: String(data: responseData, encoding: String.Encoding.utf8)) )")
                }
            }
        })
        dataTask.resume()
    }
}
