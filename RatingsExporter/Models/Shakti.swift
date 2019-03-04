//
//  Shakti.swift
//  RatingsExporter
//
//  Created by Jason Beck on 2/26/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

internal protocol ShaktiProtocol {
	var isInitialized: Bool {get}
	var authURL: String? {get}
	var shaktiVersion: String? {get}
	
	init(fromReactContextJSON context: [String : Any?], completion: @escaping (Bool) -> ())
}

public final class Shakti: ShaktiProtocol {
	
	internal var isInitialized: Bool {
		return authURL != nil
	}
	
	internal var authURL: String?
	internal var shaktiVersion: String?
	
	public init(completion: @escaping (Bool) -> ()) {
		
		
		authURL = getAuthURLFromReactContextJSON(context)
		shaktiVersion = getShaktiVersionFromReactContextJSON(context)
		
		if let _ = authURL, let _ = shaktiVersion {
			completion(true)
		}
		
		completion(false)
	}
	
	final private func getShaktiVersionFromReactContextJSON(_ reactContext: [String: Any?]) -> String? {
		
		if let models = (reactContext["models"] as? [String: Any?]),
			let serverDefs = (models["serverDefs"] as? [String: Any?]),
			let serverDefData = (serverDefs["data"] as? [String: Any?]),
			let shaktiVersion = (serverDefData["BUILD_IDENTIFIER"] as? String) {
			return shaktiVersion
		}
		
		return nil
	}
	
	final private func getAuthURLFromReactContextJSON(_ reactContext: [String: Any?]) -> String? {
		if let models = (reactContext["models"] as? [String: Any?]),
			let userInfo = models["userInfo"] as? [String: Any?],
			let data = userInfo["data"] as? [String: Any?],
			let authURL: String? = data["authURL"] as? String? {
			
			return authURL
		}
		
		return nil
	}
}
