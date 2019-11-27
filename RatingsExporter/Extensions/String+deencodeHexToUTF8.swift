//
//  String+deencodeHex.swift
//  RatingsExporter
//
//  Created by Jason Beck on 2/25/19.
//  Copyright © 2019 Jason Beck. All rights reserved.
//

extension String {
	public func deencodeHexToUTF8() -> String{
		let replaceStrings: [String: String] = [
			"\\x20": " ",
			"\\x2F": "/",
			"\\x2A": "*",
			"\\x2B": "+",
			"\\x3D": "=",
			"\\x26": "&",
			"\\x3B": ";",
			"\\x24": "$",
			"\\x27": "'",
			"\\x40": "@",
			"\\x28": "(",
			"\\x3C": "<",
			"\\x3E": ">",
			"\\x29": ")",
			"\\x23": "#",
			"\\x3F": "?",
			"\\x7C": "|",
			"\\x21": "!"
		]
		
		var finalString: String = self
		for replaceString in replaceStrings {
			finalString = finalString.replacingOccurrences(of: replaceString.key, with: replaceString.value)
		}
		
		return finalString
	}
}
