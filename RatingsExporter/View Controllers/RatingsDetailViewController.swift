//
//  RatingsDetailViewController.swift
//  RatingsExporter
//
//  Created by Jason Beck on 1/13/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

import UIKit.UIViewController
import UIKit.UIImageView

final class RatingsDetailViewController: UIViewController {
	@IBOutlet weak var boxArt197: UIImageView!
	@IBOutlet weak var rating: UILabel!
	@IBOutlet weak var dateRated: UILabel!
	
	private var downloadTask: URLSessionDownloadTask?
	
	
	///The movie to display
	public var movie: NetflixRating?
	
	override func viewDidLoad() {
		if let boxArtURL = movie?.getBoxArtURL(boxArtType: .GHD) {
			downloadTask = boxArt197.loadImage(url: boxArtURL)
		}
		
		rating.text = "\(movie?.intRating ?? 0) Stars"
		dateRated.text = movie?.date ?? NSLocalizedString("Unknown Date", comment: "An unknown date when the movie was rated")
	}
	
	deinit {
		if let downloadTask = downloadTask {
			downloadTask.cancel()
		}
	}
}
