//
//  NetflixRatingsLists.swift
//  RatingsExporter
//
//  Created by Jason Beck on 1/13/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

protocol NetflixRatingsListProtocol {
	func NetflixRatingsLists(_ : NetflixRatingsListProtocol, stateChangedFrom oldState: NetflixRatingsLists.RatingsListState, To newState: NetflixRatingsLists.RatingsListState)
}

class NetflixRatingsLists {
    
    public enum RatingsListState {
        case initializing
        case ready
    }
	
	public enum FetchMode {
		///Loads ratings as they are requested (generally by the table view controller)
		case sequencial
		///Preloads all the ratings before alerting the delegate
		case preloadAll
		///Let the protocol implementer request pre-fetches
		case directed
	}
    
    private var ratingsLists: [NetflixRatingsList?]? = nil
	private var fetchMode: FetchMode
    
    public var delegate: NetflixRatingsListProtocol?
    
    ///Public for dependency injection!
    public var fetcher: RatingsFetcher!
    
    //Creates a state for the object
    private var state: RatingsListState = .initializing {
        didSet {
            self.delegate?.NetflixRatingsListsStateChanged(oldValue, newState: state)
        }
    }
    
    ///Returns the number of pages in the lists
    public var totalPages: Int {
        if let list = ratingsLists?.first, let firstList = list {
            return (firstList.totalRatings / firstList.numberOfItemsInList)
        } else {
            return 0
        }
    }
    
    //WHAT IF WE DIVIDE BY ZERO!!!!
    public var itemsPerPage: Int {
        if let list = ratingsLists?.first, let firstList = list {
            return firstList.numberOfItemsInList
        } else {
            return 0
        }
    }
    
    public var totalRatings: Int {
        if let list = ratingsLists?.first, let firstList = list {
            return firstList.totalRatings as Int
        } else {
            return 0
        }
    }
    
    ///Get's the specifed rating
    subscript(index: Int) -> NetflixRating? {
        get {
            //Check for initalization. Can't return ratings till the first page is fetched.
            if state == .initializing {
                return nil
            }
            
            //Let's math where the item is!
            let page = (index / 100)
            let pageNormalizedItemNumber = index % 100
			
			let returnRating = ratingsLists?[page]?.ratingItems[pageNormalizedItemNumber]
			
			if fetchMode == .sequencial, returnRating == nil {
				fetcher.fetchRatings(page: UInt(page))
			}
            
            return returnRating
        }
    }
    
	init?(fetcher: RatingsFetcher?, withCredentials credentials: NetflixCredential?, usingFetchMode mode: FetchMode = .sequencial) {
        
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
        } else {
            self.fetcher = fetcher!
        }
        
        //Set ourselves as the delegate
        self.fetcher.delegate = self
        
        //Fetch the first page
        self.fetcher.fetchRatings(page: 1)
    }
}

extension NetflixRatingsLists: RatingsFetcherDelegate {
    func didFetchRatings(ratings: NetflixRatingsList) {
        if ratingsLists == nil {
            ratingsLists = [NetflixRatingsList?].init(repeating: nil, count: (ratings.totalRatings / ratings.numberOfItemsInList))
            ratingsLists![ratings.page - 1] = ratings
        }
        
        //Set the state appropriately
        //TODO: Fetching multiple pages at the same time might not work. Address this later
        state = .ready
    }
    
    func errorFetchingRatingsForPage(page: UInt) {
        print("NetflixRatingsLists: An error occured fetching page: \(page)")
        state = .ready
    }
}
