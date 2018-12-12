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
    
    private var isLoggingIn = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load the Netflix login page
        loginWebView.navigationDelegate = self
        let netflixLoginURL = URL(string: "https://www.netflix.com/login")!
        let myRequest = URLRequest(url: netflixLoginURL)
        loginWebView.load(myRequest)
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension NetflixLoginViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        //detect if a redirect to Browse happened for if a login succeeded.
        
        decisionHandler(.allow)
    }
}
