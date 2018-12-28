//
//  NetflixLoginViewControllerTests.swift
//  RatingsExporterTests
//
//  Created by Jason Beck on 12/27/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import XCTest
import WebKit
@testable import RatingsExporter


class NetflixLoginViewControllerTests: XCTestCase {
    
     var controllerUnderTest: NetflixLoginViewController = (UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: NetflixLoginViewController.Identifiers.Storyboard.NetflixLoginController) as! NetflixLoginViewController)
    var bundle: Bundle = Bundle.init(for: NetflixLoginViewController.classForCoder())
    
    enum TestCertType: String {
        case goodNetflixCert = "netflix"
        case goodNetflixAssetCert = "netflix-assets"
    }

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testValidNetflixCertPinning() {
        //given
        
        //Create items to make the SecTrust
        let goodCertificate = getCertificateForTest(type: .goodNetflixCert)!
        let policy = SecPolicyCreateSSL(true, "www.netflix.com" as CFString)
        
        //Create the SecTrust
        var serverTrust: SecTrust?
        let status = withUnsafeMutablePointer(to: &serverTrust) { (serverTrust) -> OSStatus in
            return SecTrustCreateWithCertificates(goodCertificate, policy, serverTrust)
        }
        
        //Fail if error was encountered
        guard status == noErr else {
            XCTFail("Failed to create ServerTrust object")
            return
        }
        
        //Create the mock authentication challenge
        let mockURLProtection = MockURLProtectionSpace(host: "www.netflix.com", port: 443, protocol: "https", realm: nil, authenticationMethod: NSURLAuthenticationMethodServerTrust, serverTrust: serverTrust!)
        let authenticationChallenge = URLAuthenticationChallenge(protectionSpace: mockURLProtection, proposedCredential: nil, previousFailureCount: 0, failureResponse: nil, error: nil, sender: self)
    
        //then
        let webView = WKWebView(frame: CGRect.zero)
        controllerUnderTest.webView(webView, didReceive: authenticationChallenge) { (disposition, credential) in
            XCTAssertEqual(disposition, .useCredential)
        }
    }
    
    func testInvalidNetflixServerInfo() {
        //given
        
        //Create items to make the SecTrust
        let goodCertificate = getCertificateForTest(type: .goodNetflixCert)!
        let policy = SecPolicyCreateSSL(true, "www.netflax.com" as CFString)
        
        //Create the SecTrust
        var serverTrust: SecTrust?
        let status = withUnsafeMutablePointer(to: &serverTrust) { (serverTrust) -> OSStatus in
            return SecTrustCreateWithCertificates(goodCertificate, policy, serverTrust)
        }
        
        //Fail if error was encountered
        guard status == noErr else {
            XCTFail("Failed to create ServerTrust object")
            return
        }
        
        //Create the mock authentication challenge
        let mockURLProtection = MockURLProtectionSpace(host: "www.netflax.com", port: 443, protocol: "https", realm: nil, authenticationMethod: NSURLAuthenticationMethodServerTrust, serverTrust: serverTrust!)
        let authenticationChallenge = URLAuthenticationChallenge(protectionSpace: mockURLProtection, proposedCredential: nil, previousFailureCount: 0, failureResponse: nil, error: nil, sender: self)
        
        //then
        let webView = WKWebView(frame: CGRect.zero)
        controllerUnderTest.webView(webView, didReceive: authenticationChallenge) { (disposition, credential) in
            XCTAssertEqual(disposition, URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge)
        }
    }

}

//MARK: - URLAuthenticationChallengeSender
extension NetflixLoginViewControllerTests: URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {
    }
    
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {
    }
    
    func cancel(_ challenge: URLAuthenticationChallenge) {
    }
}

//MARK: - Helper Methods
extension NetflixLoginViewControllerTests {
    func getCertificateForTest(type identifier: TestCertType) -> SecCertificate? {
        let certURL = bundle.url(forResource: identifier.rawValue, withExtension: "cer")!
        let certData = try! Data(contentsOf: certURL)
        
        return SecCertificateCreateWithData(nil, certData as CFData)
    }
}
