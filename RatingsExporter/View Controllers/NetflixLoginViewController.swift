//
//  NetflixLoginViewController.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/11/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import UIKit
import WebKit

class NetflixLoginViewController: UIViewController {
    
    @IBOutlet weak var loginWebView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //Load the Netflix login page
        loginWebView.navigationDelegate = self
        loginWebView.isHidden = true
        let netflixLoginURL = URL(string: "https://www.netflix.com/login")!
        let myRequest = URLRequest(url: netflixLoginURL)
        loginWebView.load(myRequest)
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension NetflixLoginViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Webkit loaded netflix page!")
        loginWebView.isHidden = false
    }
}
