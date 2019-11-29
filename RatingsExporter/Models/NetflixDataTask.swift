//
//  NetflixDataTask.swift
//  RatingsExporter
//
//  Created by Jason Beck on 11/27/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//
import Foundation.NSURL

public protocol NetflixDataTaskProtocol {
    var pageRequest: UInt {get set}
    func executeRequestWithURL(url: URL)
}

class NetflixDataTask: NetflixDataTaskProtocol {
    var pageRequest: UInt
    private var dataTask: URLSessionDataTask?
    private weak var session: URLSession?
    private var completion: (NetflixDataTaskProtocol, NetflixRatingsList?, Error?) -> ()
    
    init(pageRequest: UInt, usingSession session: URLSession, completion: @escaping (NetflixDataTaskProtocol, NetflixRatingsList?, Error?) -> ()) {
        self.pageRequest = pageRequest
        self.session = session
        self.completion = completion
    }
    
    public func executeRequestWithURL(url: URL) {
        debugLog("Executing Data Task")
        prepareForExecuteWithURL(url: url)
        dataTask?.resume()
    }
    
    private func prepareForExecuteWithURL(url: URL) {
        let dataTask = session?.dataTask(with: url, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            if let httpResponse = (response as? HTTPURLResponse) {
                
                if httpResponse.statusCode != 200 {
                    let userInfo = ["response": response]
                    let error: Error = NSError(domain: "networking.NetflixDataTask", code: httpResponse.statusCode, userInfo: userInfo as [String : Any])
                    self.completion(self, nil, error)
                    return
                }
                
                if let responseData = data {
                    //Serialize the data
                    let json = ((try? JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any]) as [String : Any]??)
                    
                    if let json = json, let finalJson = json {
                        guard let ratings = NetflixRatingsList(json: finalJson) else {
                            let error: Error = NSError(domain: "parsing.NetflixDataTask", code: httpResponse.statusCode, userInfo:nil)
                            self.completion(self, nil, error)
                            return
                        }
                        
                        self.completion(self, ratings, nil)
                    }
                }
            }
        })
        self.dataTask = dataTask
    }
    
    deinit {
        debugLog("Denit called!")
    }
}
