//
//  MockURLProtectionSpace.swift
//  RatingsExporterTests
//
//  Created by Jason Beck on 12/28/18.
//  Copyright © 2018 Jason Beck. All rights reserved.
//

import Foundation

class MockURLProtectionSpace: URLProtectionSpace {
	private var mockServerTrust: SecTrust?
	override public var serverTrust: SecTrust? {
		get {
			return mockServerTrust
		}
		set {
			mockServerTrust = newValue
		}
	}
	
	init(host: String, port: Int, protocol: String?, realm: String?, authenticationMethod: String?, serverTrust: SecTrust?) {
		mockServerTrust = serverTrust
		
		super.init(host: host, port: port, protocol: `protocol`, realm: realm, authenticationMethod: authenticationMethod)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
}
