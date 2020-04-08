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
			return CharacterRule(primaryTag: CharacterRuleTag(tag: "![", type: .open), otherTags: [
					CharacterRuleTag(tag: "]", type: .close),
					CharacterRuleTag(tag: "(", type: .metadataOpen),
					CharacterRuleTag(tag: ")", type: .metadataClose)
			], styles: [1 : [CharacterStyle.image]], metadataLookup: false, spacesAllowed: .bothSides, isSelfContained: true)
		case .links:
			return CharacterRule(primaryTag: CharacterRuleTag(tag: "[", type: .open, escapeCharacters: [EscapeCharacter(character: "\\", rule: .remove),EscapeCharacter(character: "!", rule: .keep)]), otherTags: [
					CharacterRuleTag(tag: "]", type: .close),
					CharacterRuleTag(tag: "(", type: .metadataOpen),
					CharacterRuleTag(tag: ")", type: .metadataClose)
			], styles: [1 : [CharacterStyle.link]], metadataLookup: true, spacesAllowed: .bothSides, isSelfContained: true)
		case .backticks:
			return CharacterRule(primaryTag: CharacterRuleTag(tag: "`", type: .repeating), otherTags: [], styles: [1 : [CharacterStyle.code]], cancels: .allRemaining)
		case .strikethroughs:
			return CharacterRule(primaryTag:CharacterRuleTag(tag: "~", type: .repeating, min: 2, max: 2), otherTags : [], styles: [2 : [CharacterStyle.strikethrough]])
		case .asterisks:
			return CharacterRule(primaryTag: CharacterRuleTag(tag: "*", type: .repeating, min: 1, max: 3), otherTags: [], styles: [1 : [CharacterStyle.italic], 2 : [CharacterStyle.bold], 3 : [CharacterStyle.bold, CharacterStyle.italic]])
		case .underscores:
			return CharacterRule(primaryTag: CharacterRuleTag(tag: "_", type: .repeating, min: 1, max: 3), otherTags: [], styles: [1 : [CharacterStyle.italic], 2 : [CharacterStyle.bold], 3 : [CharacterStyle.bold, CharacterStyle.italic]])
		case .referencedLinks:
			return CharacterRule(primaryTag: CharacterRuleTag(tag: "[", type: .open, escapeCharacters: [EscapeCharacter(character: "\\", rule: .remove),EscapeCharacter(character: "!", rule: .keep)]), otherTags: [
					CharacterRuleTag(tag: "]", type: .close),
					CharacterRuleTag(tag: "[", type: .metadataOpen),
					CharacterRuleTag(tag: "]", type: .metadataClose)
			], styles: [1 : [CharacterStyle.referencedLink]], metadataLookup: true, spacesAllowed: .bothSides, isSelfContained: true)
				
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
		md.applyAttachments = false
		let attributedString = md.attributedString()
		let tokens : [Token] = md.previouslyFoundTokens
		let stringTokens = tokens.filter({ $0.type == .string && !$0.isMetadata })
		
		let existentTokenStyles = stringTokens.compactMap({ $0.characterStyles as? [CharacterStyle] })
		let expectedStyles = challenge.tokens.compactMap({ $0.characterStyles as? [CharacterStyle] })
		
		let linkTokens = tokens.filter({ $0.type == .string && (($0.characterStyles as? [CharacterStyle])?.contains(.link) ?? false) })
		
		return ChallengeReturn(tokens: tokens, stringTokens: stringTokens, links : linkTokens, attributedString:  attributedString, foundStyles: existentTokenStyles, expectedStyles : expectedStyles)
	}
}


extension XCTestCase {
	
	func resourceURL(for filename : String ) -> URL {
		let thisSourceFile = URL(fileURLWithPath: #file)
		let thisDirectory = thisSourceFile.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
		return thisDirectory.appendingPathComponent("Resources", isDirectory: true).appendingPathComponent(filename)
	}
	

}


