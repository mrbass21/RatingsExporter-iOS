//
//  TestViewController.swift
//  RatingsExporter
//
//  Created by Jason Beck on 2/17/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

import UIKit
import Foundation

class TestViewController: UIViewController {

	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var refreshButton: UIButton!
	
	private var titlePageDownload: URLSessionDataTask?
	private var yourSettingsPageDownload: URLSessionDataTask?
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	@IBAction func didPressRefresh() {
		//refresh
		loadTitle()
	}
	
	private func loadTitle() {
		debugLog("Fetching Arrested Development title page")
	
		fetchHTMLPageForTitle(70140358) //Get Arrested Development
	}

//	private func fetchYourAccountPage() {
//		let yourAccountsURL = URL(string: Common.URLs.netflixYourAccountsURL)!
//		
//		//Inject Cookies
//		
//		yourSettingsPageDownload = URLSession.
//	}
	
	
	
	private func fetchHTMLPageForTitle(_ titleID: UInt) {
		let titleURL = NSURL(string: "https://www.netflix.com/title/\(titleID)")! as URL
		
		titlePageDownload = URLSession.shared.dataTask(with: titleURL) { (data, response, error) in
			debugLog("Got a response!")
			guard error == nil, (response as! HTTPURLResponse).statusCode == 200, let titlePage = data else {
				debugLog("Unable to fetch page with return code: \((response as! HTTPURLResponse).statusCode) and error \(error.debugDescription)")
				return
			}
			
			self.extractTitleImageFrom(String(bytes: titlePage, encoding: .utf8)!)
		}
		titlePageDownload?.resume()
	}
	
	private func extractTitleImageFrom(_ titlePage: String) {
		debugLog("Printing Page found: ")
		//print(titlePage)
		
		let searchMatchElement = """
								 <div class="title-image" style="background-image:url('
								 """
		
		if let startSubstringRange = titlePage.range(of: searchMatchElement){
			let startSubstring = titlePage[startSubstringRange.upperBound..<titlePage.endIndex]
			let endSubStringIndex = startSubstring.range(of: ".jpg")
			print(titlePage[startSubstringRange.lowerBound...endSubStringIndex!.upperBound])
		}
		
	}
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
