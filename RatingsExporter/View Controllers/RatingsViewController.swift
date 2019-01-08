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
 
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //let fetch = RatingsFetcher()
        //fetch.fetchRatings(page: 1)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Check if the user has valid credentials stored.
        
        
        
        //if (try? UserCredentialStore.restoreCredential(for: credential)) == nil {
            //User is not logged on.
            performSegue(withIdentifier: Identifiers.Segue.NetflixLoginSegue, sender: nil)
        //}
    }
    
    //MARK: - Table View Data Source Delegate
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //This is just to test that the global tint color was applied to the control
        return tableView.dequeueReusableCell(withIdentifier: Identifiers.Cell.NetflixRatingsCell, for: indexPath)
    }
}

//MARK: - Actions
extension RatingsViewController {
    @IBAction func logOut() {
        let credential = NetflixCredential()
        do {
            try UserCredentialStore.clearCredential(credential)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}
