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

enum Rule {
	case asterisks
	case backticks
	case underscores
	case images
	case links
	case referencedLinks
	case strikethroughs
	
	func asCharacterRule() -> CharacterRule {
		switch self {
		case .images:
			return CharacterRule(openTag: "![", intermediateTag: "](", closingTag: ")", escapeCharacter: "\\", styles: [1 : [CharacterStyle.image]], maxTags: 1)
		case .links:
			return CharacterRule(openTag: "[", intermediateTag: "](", closingTag: ")", escapeCharacter: "\\", styles: [1 : [CharacterStyle.link]], maxTags: 1)
		case .backticks:
			return CharacterRule(openTag: "`", intermediateTag: nil, closingTag: nil, escapeCharacter: "\\", styles: [1 : [CharacterStyle.code]], maxTags: 1, cancels: .allRemaining)
		case .strikethroughs:
			return CharacterRule(openTag: "~", intermediateTag: nil, closingTag: nil, escapeCharacter: "\\", styles: [2 : [CharacterStyle.strikethrough]], minTags: 2, maxTags: 2)
		case .asterisks:
			return CharacterRule(openTag: "*", intermediateTag: nil, closingTag: nil, escapeCharacter: "\\", styles: [1 : [CharacterStyle.italic], 2 : [CharacterStyle.bold], 3 : [CharacterStyle.bold, CharacterStyle.italic]], maxTags: 3)
		case .underscores:
			return CharacterRule(openTag: "_", intermediateTag: nil, closingTag: nil, escapeCharacter: "\\", styles: [1 : [CharacterStyle.italic], 2 : [CharacterStyle.bold], 3 : [CharacterStyle.bold, CharacterStyle.italic]], maxTags: 3)
		case .referencedLinks:
			return CharacterRule(openTag: "[", intermediateTag: "](", closingTag: ")", escapeCharacter: "\\", styles: [1 : [CharacterStyle.link]], maxTags: 1)
				
		}
	}
}

class SwiftyMarkdownCharacterTests : XCTestCase {
	let defaultRules = SwiftyMarkdown.characterRules
	
	var challenge : TokenTest!
	var results : ChallengeReturn!
	
	func attempt( _ challenge : TokenTest, rules : [Rule]? = nil ) -> ChallengeReturn {
		if let validRules = rules {
			SwiftyMarkdown.characterRules = validRules.map({ $0.asCharacterRule() })
		} else {
			SwiftyMarkdown.characterRules = self.defaultRules
		}
		
		let md = SwiftyMarkdown(string: challenge.input)
		let tokeniser = SwiftyTokeniser(with: SwiftyMarkdown.characterRules)
		let lines = challenge.input.components(separatedBy: .newlines)
		var tokens : [Token] = []
		for line in lines {
			tokens.append(contentsOf: tokeniser.process(line))
		}
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


