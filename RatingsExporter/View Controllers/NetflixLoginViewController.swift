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
        
        //All of this is 'Unsafe' for now. I'd rather crash at the moment on a bad ur untrustable cert.
        //TODO: Be nice and display errors about lack of trust instead of crash.
        
        let serverTrust = challenge.protectionSpace.serverTrust
        let certificate = SecTrustGetCertificateAtIndex(serverTrust!, 0)
        
        //Set policies for domain name check
        let policies = NSMutableArray()
        policies.add(SecPolicyCreateSSL(true, (challenge.protectionSpace.host as CFString)))
        SecTrustSetPolicies(serverTrust!, policies)
        
        //Evaluate Trust
        var result: SecTrustResultType = .invalid
        SecTrustEvaluate(serverTrust!, &result)
        let isServerTrusted: Bool = (result == .proceed || result == .unspecified)
        
        //Actualy do the pinning junk here
        let remoteNetflixCertProvided: NSData = SecCertificateCopyData(certificate!)
        
        if(isServerTrusted && netflixCertsMatch(remoteServerCertData: (remoteNetflixCertProvided as Data))) {
            let credential = URLCredential(trust: serverTrust!)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

//MARK: - Helper Methods
extension NetflixLoginViewController {
    //Checks that all of the certificates a valid Netflix request would make are valid.
    private func netflixCertsMatch(remoteServerCertData: Data) -> Bool {
        //Currently Netflix uses two separate certificates.
        //
        // 1. One for the main Netflix domain
        // 2. The other for storage and distributions of all of the assets
        //
        //We need to check both.
        
        //TODO: Don't crash with bad data. Return false
        
        //Load the certificates
        let knownNetflixCertPath = Bundle.main.path(forResource: "netflix", ofType: "cer")!
        let knownNetflixCertData = try! Data(contentsOf: URL(fileURLWithPath: knownNetflixCertPath))
        
        let knownNetflixAssetCertPath = Bundle.main.path(forResource: "netflix-assets", ofType: "cer")!
        let knownNetflixAssetCertData = try! Data(contentsOf: URL(fileURLWithPath: knownNetflixAssetCertPath))
        
        if remoteServerCertData.elementsEqual(knownNetflixCertData) || remoteServerCertData.elementsEqual(knownNetflixAssetCertData) {
            return true
        }
        
        return false
    }
}
