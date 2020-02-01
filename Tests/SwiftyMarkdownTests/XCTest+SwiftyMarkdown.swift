//
//  XCTest+SwiftyMarkdown.swift
//  SwiftyMarkdownTests
//
//  Created by Simon Fairbairn on 17/12/2019.
//  Copyright © 2019 Voyage Travel Apps. All rights reserved.
//

import XCTest
@testable import SwiftyMarkdown

class SwiftyMarkdownCharacterTests : XCTestCase {
	let defaultRules = SwiftyMarkdown.characterRules
	
	func testDummy() {
		
	}
}


extension XCTestCase {
	
	func resourceURL(for filename : String ) -> URL {
		let thisSourceFile = URL(fileURLWithPath: #file)
		let thisDirectory = thisSourceFile.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
		return thisDirectory.appendingPathComponent("Resources", isDirectory: true).appendingPathComponent(filename)
	}
	

}

extension SwiftyMarkdownCharacterTests {
	func attempt( _ challenge : TokenTest, rules : [CharacterRule]? = nil ) -> (tokens : [Token], stringTokens: [Token], attributedString : NSAttributedString, foundStyles : [[CharacterStyle]], expectedStyles : [[CharacterStyle]] ) {
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
		
		return (tokens, stringTokens, md.attributedString(), existentTokenStyles, expectedStyles)
	}
}
