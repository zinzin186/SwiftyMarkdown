//
//  SwiftyMarkdownCharacterTests.swift
//  SwiftyMarkdownTests
//
//  Created by Simon Fairbairn on 17/12/2019.
//  Copyright © 2019 Voyage Travel Apps. All rights reserved.
//

@testable import SwiftyMarkdown
import UIKit
import XCTest

class SwiftyMarkdownCharacterTests: XCTestCase {
	
	func testIsolatedCase() {
		let challenge = TokenTest(input: "A string with a ****bold italic**** word", output: "A string with a *bold italic* word",  tokens: [
			Token(type: .string, inputString: "A string with a ", characterStyles: []),
			Token(type: .string, inputString: "*bold italic*", characterStyles: [CharacterStyle.bold, CharacterStyle.italic]),
			Token(type: .string, inputString: " word", characterStyles: [])
		])
		let results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
			
	}
	
	
	func testThatRegularTraitsAreParsedCorrectly() {
		
		var challenge = TokenTest(input: "**A bold string**", output: "A bold string",  tokens: [
			Token(type: .string, inputString: "A bold string", characterStyles: [CharacterStyle.bold])
		])
		var results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "A string with a **bold** word", output: "A string with a bold word",  tokens: [
			Token(type: .string, inputString: "A string with a ", characterStyles: []),
			Token(type: .string, inputString: "bold", characterStyles: [CharacterStyle.bold]),
			Token(type: .string, inputString: " word", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "`Code (**should** not process internal tags)`", output: "Code (**should** not process internal tags)",  tokens: [
			Token(type: .string, inputString: "Code (**should** not process internal tags) ", characterStyles: [CharacterStyle.code])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "A string with `code` (should not be indented)", output: "A string with code (should not be indented)", tokens : [
			Token(type: .string, inputString: "A string with ", characterStyles: []),
			Token(type: .string, inputString: "code", characterStyles: [CharacterStyle.code]),
			Token(type: .string, inputString: " (should not be indented)", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "*An italicised string*", output: "An italicised string", tokens : [
			Token(type: .string, inputString: "An italicised string", characterStyles: [CharacterStyle.italic])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "A string with *italicised* text", output: "A string with italicised text", tokens : [
			Token(type: .string, inputString: "A string with ", characterStyles: []),
			Token(type: .string, inputString: "italicised", characterStyles: [CharacterStyle.italic]),
			Token(type: .string, inputString: " text", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "__A bold string__ with a **mix** **of** bold __styles__", output: "A bold string with a mix of bold styles", tokens : [
			Token(type: .string, inputString: "A bold string", characterStyles: [CharacterStyle.bold]),
			Token(type: .string, inputString: "with a ", characterStyles: []),
			Token(type: .string, inputString: "mix", characterStyles: [CharacterStyle.bold]),
			Token(type: .string, inputString: " ", characterStyles: []),
			Token(type: .string, inputString: "of", characterStyles: [CharacterStyle.bold]),
			Token(type: .string, inputString: " bold ", characterStyles: []),
			Token(type: .string, inputString: "styles", characterStyles: [CharacterStyle.bold])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "`A code string` with multiple `code` `instances`", output: "A code string with multiple code instances", tokens : [
			Token(type: .string, inputString: "A code string", characterStyles: [CharacterStyle.code]),
			Token(type: .string, inputString: " with multiple ", characterStyles: []),
			Token(type: .string, inputString: "code", characterStyles: [CharacterStyle.code]),
			Token(type: .string, inputString: " ", characterStyles: []),
			Token(type: .string, inputString: "instances", characterStyles: [CharacterStyle.code])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "_An italic string_ with a *mix* _of_ italic *styles*", output: "An italic string with a mix of italic styles", tokens : [
			Token(type: .string, inputString: "An italic string", characterStyles: [CharacterStyle.italic]),
			Token(type: .string, inputString: " with a ", characterStyles: []),
			Token(type: .string, inputString: "mix", characterStyles: [CharacterStyle.italic]),
			Token(type: .string, inputString: " ", characterStyles: []),
			Token(type: .string, inputString: "of", characterStyles: [CharacterStyle.italic]),
			Token(type: .string, inputString: " italic ", characterStyles: []),
			Token(type: .string, inputString: "styles", characterStyles: [CharacterStyle.italic])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "_An italic string_, **follwed by a bold one**, `with some code`, \\*\\*and some\\*\\* \\_escaped\\_ \\`characters\\`, `ending` *with* __more__ variety.", output: "An italic string, follwed by a bold one, with some code, **and some** _escaped_ `characters`, ending with more variety.", tokens : [
			Token(type: .string, inputString: "An italic string", characterStyles: [CharacterStyle.italic]),
			Token(type: .string, inputString: ", ", characterStyles: []),
			Token(type: .string, inputString: "followed by a bold one", characterStyles: [CharacterStyle.bold]),
			Token(type: .string, inputString: ", ", characterStyles: []),
			Token(type: .string, inputString: "with some code", characterStyles: [CharacterStyle.code]),
			Token(type: .string, inputString: ", **and some** _escaped_ `characters`, ", characterStyles: []),
			Token(type: .string, inputString: "ending", characterStyles: [CharacterStyle.code]),
			Token(type: .string, inputString: " ", characterStyles: []),
			Token(type: .string, inputString: "with", characterStyles: [CharacterStyle.italic]),
			Token(type: .string, inputString: " ", characterStyles: []),
			Token(type: .string, inputString: "more", characterStyles: [CharacterStyle.bold]),
			Token(type: .string, inputString: " variety.", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
	}
	
	func testThatExtraCharactersAreHandles() {
		var challenge = TokenTest(input: "***A bold italic string***", output: "A bold italic string",  tokens: [
			Token(type: .string, inputString: "A bold italic string", characterStyles: [CharacterStyle.bold, CharacterStyle.italic])
		])
		var results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "A string with a ****bold italic**** word", output: "A string with a *bold italic* word",  tokens: [
			Token(type: .string, inputString: "A string with a ", characterStyles: []),
			Token(type: .string, inputString: "*bold italic*", characterStyles: [CharacterStyle.bold, CharacterStyle.italic]),
			Token(type: .string, inputString: " word", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "A string with a ****bold italic*** word", output: "A string with a *bold italic word",  tokens: [
			Token(type: .string, inputString: "A string with a ", characterStyles: []),
			Token(type: .string, inputString: "*bold italic", characterStyles: [CharacterStyle.bold, CharacterStyle.italic]),
			Token(type: .string, inputString: " word", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "A string with a ***bold** italic* word", output: "A string with a bold italic word",  tokens: [
			Token(type: .string, inputString: "A string with a ", characterStyles: []),
			Token(type: .string, inputString: "bold", characterStyles: [CharacterStyle.bold, CharacterStyle.italic]),
			Token(type: .string, inputString: " italic", characterStyles: [CharacterStyle.italic]),
			Token(type: .string, inputString: " word", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
	}
	
	
	// The new version of SwiftyMarkdown is a lot more strict than the old version, although this may change in future
	func offtestThatMarkdownMistakesAreHandledAppropriately() {
		let mismatchedBoldCharactersAtStart = "**This should be bold*"
		let mismatchedBoldCharactersWithin = "A string *that should be italic**"
		
		var md = SwiftyMarkdown(string: mismatchedBoldCharactersAtStart)
		XCTAssertEqual(md.attributedString().string, "This should be bold")
		
		md = SwiftyMarkdown(string: mismatchedBoldCharactersWithin)
		XCTAssertEqual(md.attributedString().string, "A string that should be italic")
		
	}
	
	func testThatEscapedCharactersAreEscapedCorrectly() {
		var challenge = TokenTest(input: "\\*\\*A normal string\\*\\*", output: "**A normal string**", tokens: [
			Token(type: .string, inputString: "**A normal string**", characterStyles: [])
		])
		var results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "A string with double \\*\\*escaped\\*\\* asterisks", output: "A string with double **escaped** asterisks", tokens: [
			Token(type: .string, inputString: "A string with double **escaped** asterisks", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "\\_A normal string\\_", output: "_A normal string_", tokens: [
			Token(type: .string, inputString: "_A normal string_", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "A string with \\_escaped\\_ underscores", output: "A string with _escaped_ underscores", tokens: [
			Token(type: .string, inputString: "A string with _escaped_ underscores", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "\\`A normal string\\`", output: "`A normal string`", tokens: [
			Token(type: .string, inputString: "`A normal string`", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "A string with \\`escaped\\` backticks", output: "A string with `escaped` backticks", tokens: [
			Token(type: .string, inputString: "A string with `escaped` backticks", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "\\**One escaped, one not at either end\\**", output: "*One escaped, one not at either end*", tokens: [
			Token(type: .string, inputString: "*", characterStyles: []),
			Token(type: .string, inputString: "One escaped, one not at either end*", characterStyles: [CharacterStyle.italic]),
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "A string with one \\**escaped\\** asterisk, one not at either end", output: "A string with one *escaped* asterisk, one not at either end", tokens: [
			Token(type: .string, inputString: "A string with one *", characterStyles: []),
			Token(type: .string, inputString: "escaped*", characterStyles: [CharacterStyle.italic]),
			Token(type: .string, inputString: " asterisk, one not at either end", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
	}
	
	func offtestAdvancedEscaping() {
		
		var challenge = TokenTest(input: "\\***A normal string*\\**", output: "**A normal string*", tokens: [
			Token(type: .string, inputString: "**", characterStyles: []),
			Token(type: .string, inputString: "A normal string", characterStyles: [CharacterStyle.italic]),
			Token(type: .string, inputString: "**", characterStyles: [])
		])
		var results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "A string with randomly *\\**escaped**\\* asterisks", output: "A string with randomly **escaped** asterisks", tokens: [
			Token(type: .string, inputString: "A string with randomly **", characterStyles: []),
			Token(type: .string, inputString: "escaped", characterStyles: [CharacterStyle.italic]),
			Token(type: .string, inputString: "** asterisks", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
	}
	
	func testThatAsterisksAndUnderscoresNotAttachedToWordsAreNotRemoved() {
		let asteriskSpace = """
	An asterisk followed by a space: *
	Line break
	"""
		let backtickSpace = "A backtick followed by a space: `"
		let underscoreSpace = "An underscore followed by a space: _"
		
		let asteriskFullStop = "Two asterisks followed by a full stop: **."
		let backtickFullStop = "Two backticks followed by a full stop: ``."
		let underscoreFullStop = "Two underscores followed by a full stop: __."
		
		let asteriskComma = "An asterisk followed by a full stop: *, *"
		let backtickComma = "A backtick followed by a space: `, `"
		let underscoreComma = "An underscore followed by a space: _, _"
		
		let asteriskWithBold = "A **bold** word followed by an asterisk * "
		let backtickWithCode = "A `code` word followed by a backtick ` "
		let underscoreWithItalic = "An _italic_ word followed by an underscore _ "
		
		var md = SwiftyMarkdown(string: asteriskSpace)
		XCTAssertEqual(md.attributedString().string, asteriskSpace)
		
		md = SwiftyMarkdown(string: backtickSpace)
		XCTAssertEqual(md.attributedString().string, backtickSpace)
		
		md = SwiftyMarkdown(string: underscoreSpace)
		XCTAssertEqual(md.attributedString().string, underscoreSpace)
		
		md = SwiftyMarkdown(string: asteriskFullStop)
		XCTAssertEqual(md.attributedString().string, asteriskFullStop)
		
		md = SwiftyMarkdown(string: backtickFullStop)
		XCTAssertEqual(md.attributedString().string, backtickFullStop)
		
		md = SwiftyMarkdown(string: underscoreFullStop)
		XCTAssertEqual(md.attributedString().string, underscoreFullStop)
		
		md = SwiftyMarkdown(string: asteriskComma)
		XCTAssertEqual(md.attributedString().string, asteriskComma)
		
		md = SwiftyMarkdown(string: backtickComma)
		XCTAssertEqual(md.attributedString().string, backtickComma)
		
		md = SwiftyMarkdown(string: underscoreComma)
		XCTAssertEqual(md.attributedString().string, underscoreComma)
		
		md = SwiftyMarkdown(string: asteriskWithBold)
		XCTAssertEqual(md.attributedString().string, "A bold word followed by an asterisk *")
		
		md = SwiftyMarkdown(string: backtickWithCode)
		XCTAssertEqual(md.attributedString().string, "A code word followed by a backtick `")
		
		md = SwiftyMarkdown(string: underscoreWithItalic)
		XCTAssertEqual(md.attributedString().string, "An italic word followed by an underscore _")
		
	}
	
	
	func testForLinks() {
		
		var challenge = TokenTest(input: "[Link at start](http://voyagetravelapps.com/)", output: "Link at start", tokens: [
			Token(type: .string, inputString: "Link at start", characterStyles: [CharacterStyle.link])
		])
		var results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		if let existentOpen = results.tokens.filter({ $0.type == .string && (($0.characterStyles as? [CharacterStyle])?.contains(.link) ?? false) }).first {
			XCTAssertEqual(existentOpen.metadataString, "http://voyagetravelapps.com/")
		} else {
			XCTFail("Failed to find an open link tag")
		}

		
		challenge = TokenTest(input: "A [Link](http://voyagetravelapps.com/)", output: "A Link", tokens: [
			Token(type: .string, inputString: "A ", characterStyles: []),
			Token(type: .string, inputString: "Link", characterStyles: [CharacterStyle.link])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		
		challenge = TokenTest(input: "[Link 1](http://voyagetravelapps.com/), [Link 2](https://www.neverendingvoyage.com/)", output: "Link 1, Link 2", tokens: [
			Token(type: .string, inputString: "Link 1", characterStyles: [CharacterStyle.link]),
			Token(type: .string, inputString: ", ", characterStyles: []),
			Token(type: .string, inputString: "Link 2", characterStyles: [CharacterStyle.link])
		])
		
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		var links = results.tokens.filter({ $0.type == .string && (($0.characterStyles as? [CharacterStyle])?.contains(.link) ?? false) })
		XCTAssertEqual(links.count, 2)
		XCTAssertEqual(links[0].metadataString, "http://voyagetravelapps.com/")
		XCTAssertEqual(links[1].metadataString, "https://www.neverendingvoyage.com/")
		
		challenge = TokenTest(input: "Email us at [simon@voyagetravelapps.com](mailto:simon@voyagetravelapps.com) Twitter [@VoyageTravelApp](twitter://user?screen_name=VoyageTravelApp)", output: "Email us at simon@voyagetravelapps.com Twitter @VoyageTravelApp", tokens: [
			Token(type: .string, inputString: "Email us at ", characterStyles: []),
			Token(type: .string, inputString: "simon@voyagetravelapps.com", characterStyles: [CharacterStyle.link]),
			Token(type: .string, inputString: " Twitter", characterStyles: []),
			Token(type: .string, inputString: "@VoyageTravelApp", characterStyles: [CharacterStyle.link])
		])
		
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		links = results.tokens.filter({ $0.type == .string && (($0.characterStyles as? [CharacterStyle])?.contains(.link) ?? false) })
		XCTAssertEqual(links.count, 2)
		XCTAssertEqual(links[0].metadataString, "mailto:simon@voyagetravelapps.com")
		XCTAssertEqual(links[1].metadataString, "twitter://user?screen_name=VoyageTravelApp")
	
		challenge = TokenTest(input: "[Link with missing square(http://voyagetravelapps.com/)", output: "[Link with missing square(http://voyagetravelapps.com/)", tokens: [
			Token(type: .string, inputString: "Link with missing square(http://voyagetravelapps.com/)", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "A [Link(http://voyagetravelapps.com/)", output: "A [Link(http://voyagetravelapps.com/)", tokens: [
			Token(type: .string, inputString: "A ", characterStyles: []),
			Token(type: .string, inputString: "[Link(http://voyagetravelapps.com/)", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		
		challenge = TokenTest(input: "[Link with missing parenthesis](http://voyagetravelapps.com/", output: "[Link with missing parenthesis](http://voyagetravelapps.com/", tokens: [
			Token(type: .string, inputString: "[Link with missing parenthesis](", characterStyles: []),
			Token(type: .string, inputString: "http://voyagetravelapps.com/", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		
		challenge = TokenTest(input: "A [Link](http://voyagetravelapps.com/", output: "A [Link](http://voyagetravelapps.com/", tokens: [
			Token(type: .string, inputString: "A ", characterStyles: []),
			Token(type: .string, inputString: "[Link](", characterStyles: []),
			Token(type: .string, inputString: "http://voyagetravelapps.com/", characterStyles: [])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
	
	}
	
	func testLinksWithOtherStyles() {
		var challenge = TokenTest(input: "A **Bold [Link](http://voyagetravelapps.com/)**", output: "A Bold Link", tokens: [
			Token(type: .string, inputString: "A ", characterStyles: []),
			Token(type: .string, inputString: "Bold ", characterStyles: [CharacterStyle.bold]),
			Token(type: .string, inputString: "Link", characterStyles: [CharacterStyle.link, CharacterStyle.bold])
		])
		var results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
//		XCTAssertEqual(results.attributedString.string, challenge.output)
		var links = results.tokens.filter({ $0.type == .string && (($0.characterStyles as? [CharacterStyle])?.contains(.link) ?? false) })
		XCTAssertEqual(links.count, 1)
		if links.count == 1 {
			XCTAssertEqual(links[0].metadataString, "http://voyagetravelapps.com/")
		} else {
			XCTFail("Incorrect link count. Expecting 1, found \(links.count)")
		}
		
		
		challenge = TokenTest(input: "A Bold [**Link**](http://voyagetravelapps.com/)", output: "A Bold Link", tokens: [
			Token(type: .string, inputString: "A Bold ", characterStyles: []),
			Token(type: .string, inputString: "Link", characterStyles: [CharacterStyle.bold, CharacterStyle.link])
		])
		results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		XCTAssertEqual(results.attributedString.string, challenge.output)
		links = results.tokens.filter({ $0.type == .string && (($0.characterStyles as? [CharacterStyle])?.contains(.link) ?? false) })
		XCTAssertEqual(links.count, 1)
		XCTAssertEqual(links[0].metadataString, "http://voyagetravelapps.com/")
	}
	
	func testForImages() {
		let challenge = TokenTest(input: "An ![Image](imageName)", output: "An Image", tokens: [
			Token(type: .string, inputString: "An Image", characterStyles: []),
			Token(type: .string, inputString: "", characterStyles: [CharacterStyle.image])
		])
		let results = self.attempt(challenge)
		XCTAssertEqual(challenge.tokens.count, results.stringTokens.count)
		XCTAssertEqual(results.tokens.map({ $0.outputString }).joined(), challenge.output)
		XCTAssertEqual(results.foundStyles, results.expectedStyles)
		let links = results.tokens.filter({ $0.type == .string && (($0.characterStyles as? [CharacterStyle])?.contains(.image) ?? false) })
		XCTAssertEqual(links.count, 1)
		XCTAssertEqual(links[0].metadataString, "imageName")
	}
}
