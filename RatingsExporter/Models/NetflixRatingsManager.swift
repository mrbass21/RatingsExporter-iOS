//
//  NetflixRatingsLists.swift
//  RatingsExporter
//
//  Created by Jason Beck on 1/13/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

///Notifications that NetflixRatingsManger will send to notify the delegate of status.
public protocol NetflixRatingsManagerDelegate {
    /**
     Notification that the manager loaded a new range of titles.
     
     - Parameter manager : A reference to the manager that fetched the ratings.
     - Parameter indexes: A range of movie indexes that were retrieved or updated.
     */
    func NetflixRatingsManagerDelegate(_ manager: NetflixRatingsManager, didLoadRatingIndexes indexes: ClosedRange<Int>)
}

//TODO: Persist ratings on device.
///A class used to manage the ratings NetflixFetcher retuns, and deals with device persistance.
public class NetflixRatingsManager {
	
    ///Describes the fetching behavior desired.
	public enum FetchMode {
		///Loads ratings as they are requested form the subscript.
		case sequential
		///Pre-loads all the ratings before alerting the delegate.
		case preloadAll
		///Let the protocol implementer request pre-fetches.
		case directed
	}
    
    //TODO: Maybe change to CoreData interface?
    ///The private persistance (in memory) of the list of items.
    private var ratingsLists: [NetflixRatingsList?]? = nil
    
    ///The selected fetch mode
	public var fetchMode: FetchMode
    
    ///A delegate to inform of updates
    public var delegate: NetflixRatingsManagerDelegate?
    
    ///Public for dependency injection!
    public var fetcher: RatingsFetcher!
    
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
    subscript(index: Int) -> NetflixRating? {
        get {
            //Let's math where the item is!
            let page = (index / 100) //Page is treated is 0 indexed on Netflixs back end!
            let pageNormalizedItemNumber = index % 100
			
			let returnRating = ratingsLists?[page]?.ratingItems[pageNormalizedItemNumber]
			
			if fetchMode == .sequential, returnRating == nil {
				fetcher.fetchRatings(page: UInt(page))
			}
            
            return returnRating
        }
    }
    
    /**
     Creates a RatingsManager that will manage the fetched ratings.
     
     - Parameter fetcher: A Netflix Fetcher to retrieve credentials.
     - Parameter withCredentials: An NetflixCredential to use for the fetcher.
     - Parameter usingFetchmode: The FetchMode to use when managing the ratings. If `nil` is specified, the value is `sequential`.
     */
	public init?(fetcher: RatingsFetcher?, withCredentials credentials: NetflixCredential?, usingFetchMode mode: FetchMode = .sequential) {
        
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

        //Create a fetcher instance if one was not provided to us
        if fetcher == nil {
            //It's fine to force unwrap here. We checked that credentials has a value.
            self.fetcher = RatingsFetcher(forCredential: useCredentials, with: nil)
            guard self.fetcher != nil else {
                return nil
            }
        } else {
            self.fetcher = fetcher!
        }
        
        //Set the fetch mode
        self.fetchMode = mode
        
        //Set ourselves as the delegate
        self.fetcher.delegate = self
        
        //Fetch the first page
        self.fetcher.fetchRatings(page: 0)
    }
}


extension NetflixRatingsManager: RatingsFetcherDelegate {
    public func errorFetchingRatingsForPage(page: UInt) {
        debugLog("Error on page \(page)")
    }
    
    public func didFetchRatings(ratings: NetflixRatingsList) {
        if ratingsLists == nil {
            //This is the first run of the object and we are preloading the first page and setting up the lists
            ratingsLists = [NetflixRatingsList?].init(repeating: nil, count: (ratings.totalRatings / ratings.numberOfRequestedItems) + 1)
            ratingsLists![ratings.page] = ratings
        } else {
            //Append this list to the list... of lists... I probably should refactor for clarity
            //TODO: Refactor so that it's not immensely confusing how this works.
            ratingsLists![ratings.page] = ratings
        }
        
        let indexRange = (ratings.page * 100)...(((ratings.page + 1) * 100) - 1)
        
        delegate?.NetflixRatingsManagerDelegate(self, didLoadRatingIndexes: indexRange)
    }
}
