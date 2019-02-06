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
		movieTitle.text = movie?.title ?? NSLocalizedString("Unknown Title", comment: "An unknown movie title")
		rating.text = "\(movie?.intRating ?? 0)"
		dateRated.text = movie?.date ?? NSLocalizedString("Unknown Date", comment: "An unknown date when the movie was rated")
	}
}
