//
//  ViewController.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/10/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import UIKit

final class RatingsViewController: UITableViewController {
	
	public var ratingsLists: NetflixRatingsManagerProtocol?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//Register Nibs
		tableView.register(UINib(nibName: Common.Identifiers.TableViewCell.NetflixRatingsCell, bundle: nil), forCellReuseIdentifier: Common.Identifiers.TableViewCell.NetflixRatingsCell)
		tableView.register(UINib(nibName: Common.Identifiers.TableViewCell.LoadingRatingCell, bundle: nil), forCellReuseIdentifier: Common.Identifiers.TableViewCell.LoadingRatingCell)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		//Check if the user has valid credentials stored.
		if ((try? UserCredentialStore.isCredentialStored(forType: NetflixCredential.self))) == false {
			//User is not logged on.
			showLoginView()
		}
		else {
			if ratingsLists == nil {
				ratingsLists = NetflixRatingsManager(fetcher: nil, withCredentials: nil)
				ratingsLists!.delegate = self
			}
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == Common.Identifiers.Segue.MovieDetailsSegue {
			//Load the rating into the controller
			let controller = segue.destination as! RatingsDetailViewController
			controller.movie = sender as? NetflixRating
		}
	}
	
	//MARK: - Table View Data Source Delegate
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return ratingsLists?.totalRatings ?? 0
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		//This is just to test that the global tint color was applied to the control
		let redBackgroundView = UIView()
		redBackgroundView.backgroundColor = UIColor(displayP3Red: 100/255, green: 20/255, blue: 0/255, alpha: 1.0)
		
		if let rating = ratingsLists?[indexPath.row] {
			let cell = tableView.dequeueReusableCell(withIdentifier: Common.Identifiers.TableViewCell.NetflixRatingsCell) as! NetflixRatingsCell
			cell.selectedBackgroundView = redBackgroundView
			cell.initFromRating(rating)
			return cell
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: Common.Identifiers.TableViewCell.LoadingRatingCell, for: indexPath)
			cell.selectedBackgroundView = redBackgroundView
			return cell
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let rating = ratingsLists?[indexPath.row] {
			performSegue(withIdentifier: Common.Identifiers.Segue.MovieDetailsSegue, sender: rating)
		}
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
			debugLog("Error: \(error.localizedDescription)")
		}
	}
}

//MARK: - Helper Functions
extension RatingsViewController {
	private func showLoginView() {
		performSegue(withIdentifier: Common.Identifiers.Segue.NetflixLoginSegue, sender: nil)
	}
}

extension RatingsViewController: NetflixRatingsManagerDelegate {
	func NetflixRatingsManagerDelegate(_: NetflixRatingsManagerProtocol, didLoadRatingIndexes indexes: ClosedRange<Int>) {
		
		if tableView.numberOfRows(inSection: 0) == 0 {
			tableView.reloadData()
		}
		
		let indexPaths = indexes.map { (index) -> IndexPath in
			IndexPath(row: index, section: 0)
		}
		
		tableView.reloadRows(at: indexPaths, with: .automatic)
	}
}
