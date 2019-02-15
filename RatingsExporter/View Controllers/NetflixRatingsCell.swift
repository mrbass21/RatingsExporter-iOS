//
//  NetflixRatingsCell.swift
//  RatingsExporter
//
//  Created by Jason Beck on 1/12/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

import UIKit.UITableViewCell

final class NetflixRatingsCell: UITableViewCell {
	@IBOutlet weak var ratingTitleLabel: UILabel!
	@IBOutlet weak var ratingRatingLabel: UILabel!
	@IBOutlet weak var ratingBoxArtView: UIImageView!
	
	private var rating: NetflixRating!
	private var imageDownload: URLSessionDownloadTask?
	
	deinit {
		if let download = imageDownload {
			download.cancel()
		}
	}
	
	func initFromRating(_ rating: NetflixRating) {
		self.rating = rating
		self.ratingTitleLabel.text = rating.title
		self.ratingRatingLabel.text = "\(rating.yourRating)"
		
		//Get the URL
		if let boxArtURL = rating.getBoxArtURL(boxArtType: .SMALL) {
			print(boxArtURL)
			imageDownload = self.ratingBoxArtView.loadImage(url: boxArtURL)
		}
	}
}
