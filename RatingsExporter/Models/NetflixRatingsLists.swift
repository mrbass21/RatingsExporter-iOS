//
//  NetflixRatingsLists.swift
//  RatingsExporter
//
//  Created by Jason Beck on 1/13/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

protocol NetflixRatingsListProtocol {
    func NetflixRatingsListsController(_ : NetflixRatingsLists, didLoadRatingIndexes indexes: ClosedRange<Int>)
}

class NetflixRatingsLists {
    
    public enum RatingsListState {
        case initializing
        case ready
    }
	
	public enum FetchMode {
		///Loads ratings as they are requested (generally by the table view controller)
		case sequential
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
    
	init?(fetcher: RatingsFetcher?, withCredentials credentials: NetflixCredential?, usingFetchMode mode: FetchMode = .sequential) {
        
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
    
    deinit {
        print("NetflixRatingsLists: Deinit!")
    }
}

extension NetflixRatingsLists: RatingsFetcherDelegate {
    func errorFetchingRatingsForPage(page: UInt) {
        print("Error on page \(page)")
    }
    
    func didFetchRatings(ratings: NetflixRatingsList) {
        if ratingsLists == nil {
            //This is the first run of the object and we are preloading the first page and setting up the lists
            ratingsLists = [NetflixRatingsList?].init(repeating: nil, count: (ratings.totalRatings / ratings.numberOfItemsInList) + 1)
            ratingsLists![ratings.page] = ratings
        } else {
            //Append this list to the list... of lists... I probably should refactor for clarity
            //TODO: Refactor so that it's not immensely confusing how this works.
            ratingsLists![ratings.page] = ratings
        }
        
        let indexRange = (ratings.page * 100)...(((ratings.page + 1) * 100) - 1)
        
        delegate?.NetflixRatingsListsController(self, didLoadRatingIndexes: indexRange)
    }
}
