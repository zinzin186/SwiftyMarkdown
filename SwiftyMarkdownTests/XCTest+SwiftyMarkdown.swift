//
//  XCTest+SwiftyMarkdown.swift
//  SwiftyMarkdownTests
//
//  Created by Simon Fairbairn on 17/12/2019.
//  Copyright © 2019 Voyage Travel Apps. All rights reserved.
//

import XCTest
@testable import SwiftyMarkdown

extension XCTestCase {
	func attempt( _ challenge : TokenTest ) -> (tokens : [Token], stringTokens: [Token], attributedString : NSAttributedString, foundStyles : [[CharacterStyle]], expectedStyles : [[CharacterStyle]] ) {
		let md = SwiftyMarkdown(string: challenge.input)
		let tokeniser = SwiftyTokeniser(with: SwiftyMarkdown.characterRules)
		let tokens = tokeniser.process(challenge.input)
		let stringTokens = tokens.filter({ $0.type == .string })
		
		let existentTokenStyles = stringTokens.compactMap({ $0.characterStyles as? [CharacterStyle] })
		let expectedStyles = challenge.tokens.compactMap({ $0.characterStyles as? [CharacterStyle] })
		
		return (tokens, stringTokens, md.attributedString(), existentTokenStyles, expectedStyles)
	}
}
