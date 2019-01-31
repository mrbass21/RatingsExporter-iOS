//
//  RatingsDetailViewController.swift
//  RatingsExporter
//
//  Created by Jason Beck on 1/13/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

import UIKit.UIViewController

final class RatingsDetailViewController: UIViewController {
	@IBOutlet weak var movieTitle: UILabel!
	@IBOutlet weak var rating: UILabel!
	@IBOutlet weak var dateRated: UILabel!
	
	
	///The movie to display
	public var movie: NetflixRating?
	
	override func viewDidLoad() {
		movieTitle.text = movie?.title
		rating.text = "\(movie?.yourRating ?? 0)"
		dateRated.text = movie?.date
	}
}
