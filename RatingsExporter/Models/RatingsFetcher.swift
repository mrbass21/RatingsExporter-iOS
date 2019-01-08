//
//  RatingsFetcher.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/30/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import Foundation

class RatingsFetcher {
    
    var session: URLSession?
    
    struct URLs {
        static var RatingsURL = "https://www.netflix.com/api/shakti/va5e8014f/ratinghistory"
    }
    
    init(with session: URLSession? = URLSession.shared) {
        self.session = session
    }
    
    public func fetchRatings(page: UInt) {
        
        let ratingsURL = URL(string: "\(URLs.RatingsURL)?pg=\(page)")!
        
        let dataTask = session?.dataTask(with: ratingsURL, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            if let httpResponse = (response as? HTTPURLResponse) {
                if httpResponse.statusCode != 200 {
                    print("Unexpected return code: \(httpResponse.statusCode)")
                }
                
                if let responseData = data {
                    print("\(String(describing: String(data: responseData, encoding: String.Encoding.utf8)) )")
                }
            }
        })
        
        dataTask?.resume()
    }
}
