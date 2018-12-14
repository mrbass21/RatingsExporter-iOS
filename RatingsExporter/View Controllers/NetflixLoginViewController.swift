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
    

    struct NetflixSettings {
        struct NetflixCookie {
            static let netflixID = "NetflixId"
            static let netflixSecureID = "SecureNetflixId"
        }
            
        struct NetflixURLs {
            static let netflixLoginURL = "https://www.netflix.com/login"
            static let netflixSuccessRedirectURL = "https://www.netflix.com/browse"
        }
    }
    
    @IBOutlet weak var loginWebView: WKWebView!
    
    //Debugging variables
    //TODO: Remove this debugging variable
    private var shouldLoadNetflixBrowse = false   //Let the browse page be loaded in the webkit so you can debug by logging out.

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load the Netflix login page
        loginWebView.navigationDelegate = self
        let netflixLoginURL = URL(string: NetflixSettings.NetflixURLs.netflixLoginURL)!
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
            if let destinationURL = navigationAction.request.url,
                    destinationURL.absoluteString.elementsEqual(NetflixSettings.NetflixURLs.netflixSuccessRedirectURL),
                    !shouldLoadNetflixBrowse {
                
                print("Harvest them cookies!")
                extractCookies(from: WKWebsiteDataStore.default())
                decisionHandler(.cancel)
                
                //Adding a debugging alert popup
                //TODO: Remove this debugging alert
                let loggedInAlert = UIAlertController(title: "Logged In", message: "User is logged in", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default) { action in
                    self.dismiss(animated: true, completion: nil)
                }
                let browseAction = UIAlertAction(title: "Allow Browse", style: .default) { (_) in
                    self.shouldLoadNetflixBrowse = true
                    webView.load(URLRequest(url: URL(string: NetflixSettings.NetflixURLs.netflixSuccessRedirectURL)!))
                }
                loggedInAlert.addAction(okAction)
                loggedInAlert.addAction(browseAction)
                present(loggedInAlert, animated: true, completion: nil)
                
                //End debugging alert popup
                
                return
            }
        }
        
        //print("Action: \(navigationAction.navigationType.rawValue) for url: \(String(describing: navigationAction.request.url?.absoluteString))")
        
        decisionHandler(.allow)
    }
}


//MARK: - Cookie Extraction code
extension NetflixLoginViewController {
    //This function is only available in iOS 11 and up
    func extractCookies(from datastore: WKWebsiteDataStore) {
        let cookieStore = datastore.httpCookieStore
        
        var netflixID: String = ""
        var netflixSecureID: String = ""
        
        cookieStore.getAllCookies { (cookieArray) in
            
            let neededCookies = cookieArray.filter({ (cookie) -> Bool in
                //We are only looking for two cookies
                if cookie.name.elementsEqual(NetflixSettings.NetflixCookie.netflixID) ||
                    cookie.name.elementsEqual(NetflixSettings.NetflixCookie.netflixSecureID) {
                    return true
                } else {
                    return false
                }
            })
            
            if neededCookies.count != 2 {
                //TODO: Handle this error condition
                print("We only need 2 cookies and we found: \(neededCookies.count)")
            } else {
                for item in neededCookies {
                    if item.name.elementsEqual(NetflixSettings.NetflixCookie.netflixID) {
                        netflixID = item.value
                    } else if item.name.elementsEqual(NetflixSettings.NetflixCookie.netflixSecureID) {
                        netflixSecureID = item.value
                    }
                }
            }
            
            UserCredentials.netflixID = netflixID
            UserCredentials.netflixSecureID = netflixSecureID
        }
    }
}
