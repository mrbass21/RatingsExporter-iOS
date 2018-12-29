//
//  MockWKNavigationAction.swift
//  RatingsExporterTests
//
//  Created by Jason Beck on 12/29/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import Foundation
import WebKit

class MockWKNavigationAction: WKNavigationAction {
    var mockNavigationType: WKNavigationType
    var mockRequestURL: URLRequest
    
    init(navigationType: WKNavigationType, with request: URLRequest) {
        mockNavigationType = navigationType
        mockRequestURL = request
    }
    
    override var navigationType: WKNavigationType {
        get {
            return mockNavigationType
        }
        set {
            mockNavigationType = newValue
        }
    }
    
    override var request: URLRequest {
        get {
            return mockRequestURL
        }
        set{
            mockRequestURL = request
        }
    }
}
