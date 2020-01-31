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

class SwiftyMarkdownLinkTests: XCTestCase {
	
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
		
		challenge = TokenTest(input: "[Link1](http://voyagetravelapps.com/) **bold** [Link2](http://voyagetravelapps.com/)", output: "Link1 bold Link2",  tokens: [
			Token(type: .string, inputString: "Link1", characterStyles: [CharacterStyle.link]),
			Token(type: .string, inputString: " ", characterStyles: []),
			Token(type: .string, inputString: "bold", characterStyles: [CharacterStyle.bold]),
			Token(type: .string, inputString: " ", characterStyles: []),
			Token(type: .string, inputString: "Link2", characterStyles: [CharacterStyle.link])
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
