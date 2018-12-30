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
    ///Stores the settings Netflix uses.
    struct NetflixSettings {
        ///IDs that Netflix uses in its cookies
        struct NetflixCookie {
            ///The Netflix ID Key in the cookie.
            static let netflixID = "NetflixId"
            ///The Secure NetflixID in the cookie.
            static let netflixSecureID = "SecureNetflixId"
        }
        
        ///URL endpoints Netflix uses
        struct NetflixURLs {
            ///The login URL. This is where users are directed to login.
            static let netflixLoginURL = "https://www.netflix.com/login"
            ///The redirect URL users are sent to if they have a valid login.
            static let netflixSuccessRedirectURL = "https://www.netflix.com/browse"
        }
    }
    
    ///Identifiers for this view controller in Storyboard
    struct Identifiers {
        ///Identifiers for this view controller in Storyboard
        struct Storyboard {
            ///The ID that refers to this login view controller
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
                    destinationURL.absoluteString.elementsEqual(NetflixSettings.NetflixURLs.netflixSuccessRedirectURL){
                
                //Cancel the navigation
                decisionHandler(.cancel)
            
                //Extract out the cookie values we need
                WKWebsiteDataStore.default().httpCookieStore.getAllCookies { (cookies) in
                    let credential = NetflixCredential(from: cookies)
                    
                }
                
                //We did what we needed to do. Return from the function so we don't double call the decision handler
                return
            }
        }
        
        //The WebKit requested navigation to a page other than /browse. Allow it for now.
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        //We should only ever be dealing with Netflix here. Drop any connection that isn't to Netflix
        
        //Code for this was found at: https://infinum.co/the-capsized-eight/how-to-make-your-ios-apps-more-secure-with-ssl-pinning
        //
        //Thanks for the clear tutorial on cert pinning!
        
        //We need a server trust. If we don't have it, bail.
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0)
        
        //Set policies for domain name check
        let policies = NSMutableArray()
        policies.add(SecPolicyCreateSSL(true, (challenge.protectionSpace.host as CFString)))
        SecTrustSetPolicies(serverTrust, policies)
        
        //Evaluate Trust
        var result: SecTrustResultType = .invalid
        SecTrustEvaluate(serverTrust, &result)
        let isServerTrusted: Bool = (result == .proceed || result == .unspecified)
        
        //Actualy do the pinning junk here
        let remoteNetflixCertProvided: NSData = SecCertificateCopyData(certificate!)
        if(isServerTrusted && netflixCertsMatch(remoteServerCertData: (remoteNetflixCertProvided as Data))) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

//MARK: - Helper Methods
extension NetflixLoginViewController {
    /**
     Checks that all of the certificates a valid Netflix request would make are, indeed, valid.
     
     - Parameter remoteServerCertData: The certificate the remote server provided as Data.
     - Returns: `true` if the cretificate maches known, good certificates. `false` otherwise.
     */
    private func netflixCertsMatch(remoteServerCertData: Data) -> Bool {
        //Currently Netflix uses two separate certificates.
        //
        // 1. One for the main Netflix domain
        // 2. The other for storage and distributions of all of the assets
        //
        //We need to check both.
        
        //Load the certificates
        guard let knownNetflixCertPath = Bundle.main.path(forResource: "netflix", ofType: "cer"),
            let knownNetflixAssetCertPath = Bundle.main.path(forResource: "netflix-assets", ofType: "cer") else {
                //We couldn't get the path to the resources. Return failure case.
                //TODO: Throw here instead?
                return false
        }
        
        do {
            let knownNetflixCertData = try Data(contentsOf: URL(fileURLWithPath: knownNetflixCertPath))
            let knownNetflixAssetCertData = try Data(contentsOf: URL(fileURLWithPath: knownNetflixAssetCertPath))
            if remoteServerCertData.elementsEqual(knownNetflixCertData) || remoteServerCertData.elementsEqual(knownNetflixAssetCertData) {
                return true
            }
        } catch {
            print("Error encountered producing data from bundled certs: \(error.localizedDescription)")
            return false
        }

        return false
    }
}
