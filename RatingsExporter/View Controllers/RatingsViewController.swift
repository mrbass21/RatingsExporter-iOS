//
//  ViewController.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/10/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import UIKit

class RatingsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //For now we force load the NetflixLoginViewController to test logging in/grabbing the cookies.
        performSegue(withIdentifier: "NetflixLoginSegue", sender: nil)
    
    }
    
    //MARK: - Table View Data Source Delegate
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "NetflixRatingsCell", for: indexPath)
    }
}

