//
//  SwiftyScanner.swift
//  SwiftyMarkdown
//
//  Created by Simon Fairbairn on 04/02/2020.
//

import Foundation
import os.log

extension OSLog {
	private static var subsystem = "SwiftyScanner"
	static let swiftyScannerTokenising = OSLog(subsystem: subsystem, category: "Swifty Scanner Tokenising")
	static let swiftyScannerPerformance = OSLog(subsystem: subsystem, category: "Swifty Scanner Peformance")
}

/// Swifty Scanning Protocol
public protocol SwiftyScanning {
	var metadataLookup : [String : String] { get set }
	func scan( _ string : String, with rule : CharacterRule) -> [Token]
	func scan( _ tokens : [Token], with rule : CharacterRule) -> [Token]
}

enum TagState {
	case none
	case open
	case intermediate
	case closed
}

class SwiftyScanner : SwiftyScanning {
	var metadataLookup: [String : String] = [:]
	
	init() {
		
	}
	
	func scan(_ string: String, with rule: CharacterRule) -> [Token] {
		return []
	}
	
	func scan(_ tokens: [Token], with rule: CharacterRule) -> [Token] {
		return tokens
	}

}

struct TokenGroup {
	enum TokenGroupType {
		case string
		case tag
		case escape
	}
	
	let string : String
	let isEscaped : Bool
	let type : TokenGroupType
	var state : TagState = .none
}
