//
//  NetflixLoginViewController.swift
//  RatingsExporter
//
//  Created by Jason Beck on 12/11/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import UIKit.UIViewController
import WebKit

final class NetflixLoginViewController: UIViewController {
	//MARK: - Outlets
	private weak var loginWebView: WKWebView!
	private weak var setupIndicatorView: UIActivityIndicatorView!
	
	//MARK: - Overridden functions
	override func loadView() {
		setupWebView()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		layoutViews()
		
		//Load the Netflix login page
		let netflixLoginURL = URL(string: Common.URLs.netflixLoginURL)!
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
				destinationURL.absoluteString.elementsEqual(Common.URLs.netflixSuccessRedirectURL){
				
				//Cancel the navigation
				decisionHandler(.cancel)
				
				//Extract out the cookie values we need
				webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] (cookies) in
					if let credential = NetflixCredential(from: cookies) {
						do {
							try UserCredentialStore.storeCredential(credential)
							self?.dismiss(animated: true, completion: nil)
						} catch {
							DispatchQueue.main.async {
								let displayMessage = NSLocalizedString("Unable to get Netflix credentials", comment: "Failed to get the data needed to verify the user.")
								self?.displayError(displayMessage)
							}
						}
					}
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
        
        //Only check pinning for the login page. Asset certs change all the time and are different for every CDN.
        if challenge.protectionSpace.host == "www.netflix.com" {
            
            //Actualy do the pinning junk here
            let remoteNetflixCertProvided: NSData = SecCertificateCopyData(certificate!)
            if(!(isServerTrusted && netflixCertsMatch(remoteServerCertData: (remoteNetflixCertProvided as Data)))) {
                //If we don't trust the login certificate, cancel the call
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
        }
        
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
	}
	
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		hideSetupIndicator()
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
		guard let knownNetflixCertPath = Bundle.main.path(forResource: "netflix", ofType: "cer") else {
				//We couldn't get the path to the resources. Return failure case.
				//TODO: Throw here instead?
				return false
		}
		
		do {
			let knownNetflixCertData = try Data(contentsOf: URL(fileURLWithPath: knownNetflixCertPath))

			if remoteServerCertData.elementsEqual(knownNetflixCertData) {
				return true
			}
		} catch {
			print("Error encountered producing data from bundled certs: \(error.localizedDescription)")
			return false
		}
		
		return false
	}
	
	/**
	Checks that all of the certificates a valid Netflix request would make are, indeed, valid.
	
	- Parameter remoteServerCertData: The certificate the remote server provided as Data.
	- Returns: `true` if the certificate matches known, good certificates. `false` otherwise.
	*/
	private func displayError(_ message: String) {
		let error = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
		let errorAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
		error.addAction(errorAction)
		present(error, animated: true, completion: nil)
	}
	
	/**
	Sets up the properties for the webview
	*/
	private func setupWebView() {
		let webConfiguration = WKWebViewConfiguration()
		
		//We don't want to persist the cookies, so we create a temporary store
		//webConfiguration.websiteDataStore = WKWebsiteDataStore.default()
		webConfiguration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
		
		//Create a root outer view
		let initialView = UIView(frame: CGRect.zero)
		initialView.backgroundColor = .black
		view = initialView
		
		//Create a new webview with our options
		let _loginWebView = WKWebView(frame: CGRect.zero, configuration: webConfiguration)
		_loginWebView.translatesAutoresizingMaskIntoConstraints = false
		_loginWebView.navigationDelegate = self
		_loginWebView.isOpaque = false
		_loginWebView.scrollView.backgroundColor = .clear
		loginWebView = _loginWebView
		
		//Create an activity indicator
		let _setupIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
		_setupIndicatorView.translatesAutoresizingMaskIntoConstraints = false
		_setupIndicatorView.color = UIColor.red
		_setupIndicatorView.isUserInteractionEnabled = false
		_setupIndicatorView.hidesWhenStopped = true
		_setupIndicatorView.startAnimating()
		setupIndicatorView = _setupIndicatorView
		
		view.addSubview(_loginWebView)
		view.addSubview(_setupIndicatorView)
	}
	
	/**
	Layout the views in the controller
	*/
	private func layoutViews() {
		//Setup constraints
		let margins = view.layoutMarginsGuide
		
		loginWebView.topAnchor.constraint(equalTo: margins.topAnchor).isActive = true
		loginWebView.bottomAnchor.constraint(equalTo: margins.bottomAnchor).isActive = true
		loginWebView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
		loginWebView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
		
		setupIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
		setupIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
		setupIndicatorView.heightAnchor.constraint(equalToConstant: 37.0).isActive = true
		setupIndicatorView.widthAnchor.constraint(equalToConstant: 37.0).isActive = true
	}
	
	/**
	Stops the animating of the setupIndicator, which will also hide the view
	*/
	private func hideSetupIndicator() {
		setupIndicatorView?.stopAnimating()
	}
}
