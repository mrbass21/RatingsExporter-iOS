//
//  LoadingRatingsCell.swift
//  RatingsExporter
//
//  Created by Jason Beck on 2/13/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

import UIKit.UITableViewCell

final class LoadRatingsCell: UITableViewCell {
	@IBOutlet weak var activitySpinner: UIActivityIndicatorView?
	
	override func prepareForReuse() {
		super.prepareForReuse()
		activitySpinner?.startAnimating()
	}
}
