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
    
    //MARK: - Convenience Structs
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
    
    struct Identifiers {
        struct Storyboard {
            static let NetflixLoginController = "NetflixLoginViewController"
        }
    }
    
    //MARK: - Outlets
    @IBOutlet weak var loginWebView: WKWebView!

    //MARK: - Overridden functions
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

//MARK: - WKNavigationDelegate
extension NetflixLoginViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
       
        //Detect if a redirect to Browse happened for if a login succeeded.
        
        //If the user logs in from a form, the navigation type will be formSubmitted (1).
        //If the user launches the app and already has a valid session, the navigation type will be other (-1)
        if navigationAction.navigationType == .formSubmitted || navigationAction.navigationType == .other {
            
            //If there's a valid session, the url will ask for https://www.netflix.com/browse.
            if let destinationURL = navigationAction.request.url,
                    destinationURL.absoluteString.elementsEqual(NetflixSettings.NetflixURLs.netflixSuccessRedirectURL) {
                
                //Cancel the navigation
                decisionHandler(.cancel)
            
                //Extract out the cookie values we need
                do {
                    let cookies = try extractCookies(from: WKWebsiteDataStore.default().httpCookieStore)
                    try UserCredentials.setCredentials(fromCookies: cookies)
                } catch
                {
                    print("Failed to get user credentials with error: \(error)")
                }
                
                return
            }
        }
        
        //The WebKit requested navigation to a page other than /browse. Allow it for now.
        decisionHandler(.allow)
    }
}


//MARK: - Cookie Extraction code
extension NetflixLoginViewController {
    @available(iOS 11.0, *)
    private func extractCookies(from cookieStore: WKHTTPCookieStore) throws -> [UserCredentials.UserCredentialKeys: String] {
        var returnCookies: [UserCredentials.UserCredentialKeys: String]? = nil
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
                print("We only need 2 cookies and we found: \(neededCookies.count)")
                
            } else {
                returnCookies = [UserCredentials.UserCredentialKeys: String]()
                for item in neededCookies {
                    if item.name.elementsEqual(NetflixSettings.NetflixCookie.netflixID) {
                        returnCookies![UserCredentials.UserCredentialKeys.kUserCredentialNetflixID] = item.value
                    } else if item.name.elementsEqual(NetflixSettings.NetflixCookie.netflixSecureID) {
                        returnCookies![UserCredentials.UserCredentialKeys.kUserCredentialNetflixSecureID] = item.value
                    }
                }
            }
        }
        
        if let returnCookies = returnCookies {
            return returnCookies
        } else {
            throw UserCredentials.UserCredentialError.MissingCredentials
        }
    }
}
