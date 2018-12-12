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
    
    struct Settings {
        static let netflixLoginURL = "https://www.netflix.com/login"
        static let netflixSuccessRedirectURL = "https://www.netflix.com/browse"
    }
    
    @IBOutlet weak var loginWebView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load the Netflix login page
        loginWebView.navigationDelegate = self
        let netflixLoginURL = URL(string: Settings.netflixLoginURL)!
        let myRequest = URLRequest(url: netflixLoginURL)
        loginWebView.load(myRequest)
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension NetflixLoginViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
       
        //Detect if a redirect to Browse happened for if a login succeeded.
        
        //If the user logs in from a form, the navigation type will be formSubmitted (1).
        //If the user launches the app and already has a valid session, the navigation type will be other (-1)
        if navigationAction.navigationType == .formSubmitted || navigationAction.navigationType == .other {
            //If there's a valid session, the url will ask for https://www.netflix.com/browse.
            if let destinationURL = navigationAction.request.url, destinationURL.absoluteString.elementsEqual(Settings.netflixSuccessRedirectURL) {
                print("Harvest them cookies!")
                decisionHandler(.cancel)
                let loggedInAlert = UIAlertController(title: "Logged In", message: "User is logged in", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default) { action in
                    self.dismiss(animated: true, completion: nil)
                }
                loggedInAlert.addAction(okAction)
                present(loggedInAlert, animated: true, completion: nil)
                return
            }
        }
        
        //print("Action: \(navigationAction.navigationType.rawValue) for url: \(String(describing: navigationAction.request.url?.absoluteString))")
        
        decisionHandler(.allow)
    }
}
