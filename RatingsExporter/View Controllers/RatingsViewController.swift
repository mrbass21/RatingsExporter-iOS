//
//  ViewController.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/10/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import UIKit

class RatingsViewController: UITableViewController {
    
    struct Identifiers {
        struct Segue {
            static let NetflixLoginSegue = "NetflixLoginSegue"
        }
        struct Cell {
            static let NetflixRatingsCell = "NetflixRatingsCell"
        }
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //For now we force load the NetflixLoginViewController to test logging in/grabbing the cookies.
        //TODO: Don't force the segue unless it's for a legitimate need to log in.
        //if !UserCredentials.hasCredentials {
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

