//
//  NetflixRatingsCell.swift
//  RatingsExporter
//
//  Created by Jason Beck on 1/12/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

import UIKit

class NetflixRatingsCell: UITableViewCell {
    @IBOutlet weak var ratingTitle: UILabel!
    @IBOutlet weak var ratingRating: UILabel!

    func initFromRating(_ rating: NetflixRating) {
        self.ratingTitle.text = rating.title
        self.ratingRating.text = "\(rating.yourRating)"
    }
}
