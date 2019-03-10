//
//  NetflixRatingsLists.swift
//  RatingsExporter
//
//  Created by Jason Beck on 1/13/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

import Foundation.NSURLSession

///Notifications that NetflixRatingsManger will send to notify the delegate of status.
public protocol NetflixRatingsManagerDelegate: class {
	/**
	Notification that the manager loaded a new range of titles.
	
	- Parameter manager : A reference to the manager that fetched the ratings.
	- Parameter indexes: A range of movie indexes that were retrieved or updated.
	*/
	func NetflixRatingsManagerDelegate(_ manager: NetflixRatingsManagerProtocol, didLoadRatingIndexes indexes: ClosedRange<Int>)
}

///The protocol that a RatingsManager should conform to.
public protocol NetflixRatingsManagerProtocol: class {
	var delegate: NetflixRatingsManagerDelegate? {get set}
	var totalPages: Int {get}
	var itemsPerPage: Int {get}
	var totalRatings: Int {get}
	subscript(index: Int) -> NetflixRating? {get}
}

//TODO: Persist ratings on device.
///A class used to manage the ratings NetflixFetcher retuns, and deals with device persistance.
public final class NetflixRatingsManager: NetflixRatingsManagerProtocol {
	
	var shakti: Shakti<NetflixCredential>?
	
	var activeTasks: [Int: URLSessionTask?] = [:]
	
	//TODO: Maybe change to CoreData interface?
	///The private persistance (in memory) of the list of items.
	private var ratingsLists: [NetflixRatingsList?]? = nil
	
	///A delegate to inform of updates
	public var delegate: NetflixRatingsManagerDelegate?
	
	///Returns the number of pages in the lists
	public var totalPages: Int {
		if let list = ratingsLists?.first, let firstList = list {
			return (firstList.totalRatings / firstList.numberOfRequestedItems)
		} else {
			return 0
		}
	}
	
	///Returns the number of items in a page.
	public var itemsPerPage: Int {
		//If the list is initialized, return the count. Otherwise, return 0.
		if let list = ratingsLists?.first, let firstList = list {
			return firstList.ratingItems.count
		} else {
			return 0
		}
	}
	
	///The total number of ratings for the user.
	public var totalRatings: Int {
		//Every list contains the total ratings, so just grab the first one (Which is immediately fetched).
		if let list = ratingsLists?.first, let firstList = list {
			return firstList.totalRatings as Int
		} else {
			return 0
		}
	}
	
	///Get's the rating for the item at the index.
	public subscript(index: Int) -> NetflixRating? {
		get {
			//Let's math where the item is!
			let page = (index / 100) //Page is treated is 0 indexed on Netflixs back end!
			let pageNormalizedItemNumber = index % 100
			
			let returnRating = ratingsLists?[page]?.ratingItems[pageNormalizedItemNumber]
			
			return returnRating
		}
	}
	
	/**
	Creates a RatingsManager that will manage the fetched ratings.
	
	- Parameter fetcher: A Netflix Fetcher to retrieve credentials.
	- Parameter withCredentials: An NetflixCredential to use for the fetcher.
	- Parameter usingFetchmode: The FetchMode to use when managing the ratings. If `nil` is specified, the value is `sequential`.
	*/
	public init?(withCredentials credentials: NetflixCredential?) {
		
		//Check if we were provided credentials. If not, try and harvest them from the internal store
		let useCredentials: NetflixCredential
		if credentials == nil {
			let tempCredentials = try? UserCredentialStore.restoreCredential(forType: NetflixCredential.self)
			guard tempCredentials != nil else {
				return nil
			}
			useCredentials = tempCredentials!
		}
		else {
			useCredentials = credentials!
		}

		shakti = Shakti<NetflixCredential>(forCredential: useCredentials)
		shakti?.initializeShakti() { [weak self] (success) in
			if success {
				self?.activeTasks[0] = self?.shakti?.getRatingsList(page: 0, completion: { (list) in
					
					guard let list = list else {
						return
					}
					
					let task = self?.shakti?.fetchBoxArtURLForList(list, completion: {
						
					})
					
					if let task = task {
						self?.activeTasks[1] = task
						task.resume()
					}
					
					if self?.ratingsLists == nil {
						//This is the first run of the object and we are preloading the first page and setting up the lists
						self?.ratingsLists = [NetflixRatingsList?].init(repeating: nil, count: ((list.totalRatings) / (list.numberOfRequestedItems)) + 1)
						self?.ratingsLists![list.page] = list
					} else {
						//Append this list to the list... of lists... I probably should refactor for clarity
						//TODO: Refactor so that it's not immensely confusing how this works.
					
						self?.ratingsLists![list.page] = list
					}
					
					let indexRange = (list.page * 100)...(((list.page + 1) * 100) - 1)
					
					if self != nil {
						self!.delegate?.NetflixRatingsManagerDelegate(self!, didLoadRatingIndexes: indexRange)
					}
					
					
				})
				
				self?.activeTasks[0]??.resume()
			} else {
				debugLog("Could not initialize")
			}
		}
	}
}
