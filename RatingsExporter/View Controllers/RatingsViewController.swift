//
//  ViewController.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/10/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import UIKit

class RatingsViewController: UITableViewController {
    
    ///Identifiers for this view controller in Storyboard
    struct Identifiers {
        ///Identifiers used for segues
        struct Segue {
            static let NetflixLoginSegue = "NetflixLoginSegue"
        }
        ///Identifiers used for cell
        struct Cell {
            static let NetflixRatingsCell = "NetflixRatingsCell"
        }
    }
    
    ///The fetching object that makes the requests
    var fetcher: RatingsFetcher!
    var ratingsList: NetflixRatingsList?
 
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Check if the user has valid credentials stored.
        if ((try? UserCredentialStore.isCredentialStored(forType: NetflixCredential.self))) == false {
            //User is not logged on.
            showLoginView()
        }
        else {
            fetcher = RatingsFetcher(forCredential: try! UserCredentialStore.restoreCredential(forType: NetflixCredential.self), with: nil)
			fetcher.delegate = self
            fetcher.fetchRatings(page: 1)
        }
    }
    
    //MARK: - Table View Data Source Delegate
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let ratingsList = ratingsList {
            return ratingsList.ratingItems.count
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //This is just to test that the global tint color was applied to the control
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.Cell.NetflixRatingsCell) as! NetflixRatingsCell
        
        if let ratingItem = ratingsList?.ratingItems[indexPath.row] {
            cell.initFromRating(ratingItem)
        } else {
            cell.ratingTitle.text = "Loading..."
            cell.ratingRating.text = ""
        }
        
        return cell
    }
}

//MARK: - Actions
extension RatingsViewController {
    @IBAction func logOut() {
        let credential = NetflixCredential()
        do {
            try UserCredentialStore.clearCredential(credential)
            showLoginView()
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}

//MARK: - Helper Functions
extension RatingsViewController {
    private func showLoginView() {
        performSegue(withIdentifier: Identifiers.Segue.NetflixLoginSegue, sender: nil)
    }
}

//MARK: - RatingsFetcherDelegate
extension RatingsViewController: RatingsFetcherDelegate {
    func errorFetchingRatingsForPage(page: UInt) {
        print("Error")
    }
    
    func didFetchRatings(ratings: NetflixRatingsList) {
		ratingsList = ratings
        tableView.reloadData()
    }
}
