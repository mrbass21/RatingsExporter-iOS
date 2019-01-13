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
            static let MoveiDetailsSegue = "MovieDetailsSegue"
        }
        ///Identifiers used for cell
        struct Cell {
            static let NetflixRatingsCell = "NetflixRatingsCell"
            static let LoadingRatingCell = "LoadingRatingsCell"
        }
    }
    
    public var ratingsLists: NetflixRatingsLists!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Register Nibs
        tableView.register(UINib(nibName: Identifiers.Cell.NetflixRatingsCell, bundle: nil), forCellReuseIdentifier: Identifiers.Cell.NetflixRatingsCell)
        tableView.register(UINib(nibName: Identifiers.Cell.LoadingRatingCell, bundle: nil), forCellReuseIdentifier: Identifiers.Cell.LoadingRatingCell)
        
        //Check if the user has valid credentials stored.
        if ((try? UserCredentialStore.isCredentialStored(forType: NetflixCredential.self))) == false {
            //User is not logged on.
            showLoginView()
        }
        else {
            ratingsLists = NetflixRatingsLists(fetcher: nil, withCredentials: nil)
            ratingsLists.delegate = self
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Identifiers.Segue.MoveiDetailsSegue {
            //Load the rating into the controller
            let controller = segue.destination as! RatingsDetailViewController
            controller.movie = sender as? NetflixRating
        }
    }
    
    //MARK: - Table View Data Source Delegate
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("Creating \(ratingsLists.totalRatings) number of rows")
        return ratingsLists.totalRatings
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //This is just to test that the global tint color was applied to the control
        let redBackgroundView = UIView()
        redBackgroundView.backgroundColor = UIColor(displayP3Red: 100/255, green: 20/255, blue: 0/255, alpha: 1.0)
        if let rating = ratingsLists[indexPath.row] {
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.Cell.NetflixRatingsCell) as! NetflixRatingsCell
            cell.selectedBackgroundView = redBackgroundView
            cell.initFromRating(rating)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.Cell.LoadingRatingCell, for: indexPath)
            cell.selectedBackgroundView = redBackgroundView
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //performSegue(withIdentifier: Identifiers.Segue.MoveiDetailsSegue, sender: ratingsList?.ratingItems[indexPath.row])
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

extension RatingsViewController: NetflixRatingsListProtocol {
    func NetflixRatingsListsStateChanged(_ oldState: NetflixRatingsLists.RatingsListState, newState: NetflixRatingsLists.RatingsListState) {
        if oldState == .initializing && newState == .ready {
            //We now have data to display
            tableView.reloadData()
        }
    }
}
