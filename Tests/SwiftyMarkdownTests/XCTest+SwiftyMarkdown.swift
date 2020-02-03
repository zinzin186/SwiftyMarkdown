//
//  XCTest+SwiftyMarkdown.swift
//  SwiftyMarkdownTests
//
//  Created by Simon Fairbairn on 17/12/2019.
//  Copyright © 2019 Voyage Travel Apps. All rights reserved.
//

import XCTest
@testable import SwiftyMarkdown


struct ChallengeReturn {
	let tokens : [Token]
	let stringTokens : [Token]
	let links : [Token]
	let attributedString : NSAttributedString
	let foundStyles : [[CharacterStyle]]
	let expectedStyles : [[CharacterStyle]]
}

class SwiftyMarkdownCharacterTests : XCTestCase {
	let defaultRules = SwiftyMarkdown.characterRules
	
	var challenge : TokenTest!
	var results : ChallengeReturn!
	var rules : [CharacterRule]? = nil
	
	func attempt( _ challenge : TokenTest, rules : [CharacterRule]? = nil ) -> ChallengeReturn {
		if let validRules = rules {
			SwiftyMarkdown.characterRules = validRules
		} else {
			SwiftyMarkdown.characterRules = self.defaultRules
		}
		
		let md = SwiftyMarkdown(string: challenge.input)
		let tokeniser = SwiftyTokeniser(with: SwiftyMarkdown.characterRules)
		let tokens = tokeniser.process(challenge.input)
		let stringTokens = tokens.filter({ $0.type == .string && !$0.isMetadata })
		
		let existentTokenStyles = stringTokens.compactMap({ $0.characterStyles as? [CharacterStyle] })
		let expectedStyles = challenge.tokens.compactMap({ $0.characterStyles as? [CharacterStyle] })
		
		let linkTokens = tokens.filter({ $0.type == .string && (($0.characterStyles as? [CharacterStyle])?.contains(.link) ?? false) })
		
		return ChallengeReturn(tokens: tokens, stringTokens: stringTokens, links : linkTokens, attributedString:  md.attributedString(), foundStyles: existentTokenStyles, expectedStyles : expectedStyles)
	}
}


extension XCTestCase {
	
	func resourceURL(for filename : String ) -> URL {
		let thisSourceFile = URL(fileURLWithPath: #file)
		let thisDirectory = thisSourceFile.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
		return thisDirectory.appendingPathComponent("Resources", isDirectory: true).appendingPathComponent(filename)
	}
	

}


