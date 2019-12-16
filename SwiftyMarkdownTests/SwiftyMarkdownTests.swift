//
//  SwiftyMarkdownTests.swift
//  SwiftyMarkdownTests
//
//  Created by Simon Fairbairn on 05/03/2016.
//  Copyright © 2016 Voyage Travel Apps. All rights reserved.
//

import XCTest
@testable import SwiftyMarkdown

class SwiftyMarkdownTests: XCTestCase {
    
	
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	struct StringTest {
		let input : String
		let expectedOutput : String
		var acutalOutput : String = ""
	}
	
	struct TokenTest {
		let input : String
		let output : String
		let tokens : [Token]
	}
	
	func testThatOctothorpeHeadersAreHandledCorrectly() {
		
		let heading1 = StringTest(input: "# Heading 1", expectedOutput: "Heading 1")
		var smd = SwiftyMarkdown(string:heading1.input )
		XCTAssertEqual(smd.attributedString().string, heading1.expectedOutput)
		
		let heading2 = StringTest(input: "## Heading 2", expectedOutput: "Heading 2")
		smd = SwiftyMarkdown(string:heading2.input )
		XCTAssertEqual(smd.attributedString().string, heading2.expectedOutput)
		
		let heading3 = StringTest(input: "### #Heading #3", expectedOutput: "#Heading #3")
		smd = SwiftyMarkdown(string:heading3.input )
		XCTAssertEqual(smd.attributedString().string, heading3.expectedOutput)
		
		let heading4 = StringTest(input: "  #### #Heading 4 ####", expectedOutput: "#Heading 4")
		smd = SwiftyMarkdown(string:heading4.input )
		XCTAssertEqual(smd.attributedString().string, heading4.expectedOutput)
		
		let heading5 = StringTest(input: " ##### Heading 5 ####   ", expectedOutput: "Heading 5 ####")
		smd = SwiftyMarkdown(string:heading5.input )
		XCTAssertEqual(smd.attributedString().string, heading5.expectedOutput)
		
		let heading6 = StringTest(input: " ##### Heading 5 #### More ", expectedOutput: "Heading 5 #### More")
		smd = SwiftyMarkdown(string:heading6.input )
		XCTAssertEqual(smd.attributedString().string, heading6.expectedOutput)
		
		let heading7 = StringTest(input: "# **Bold Header 1** ", expectedOutput: "Bold Header 1")
		smd = SwiftyMarkdown(string:heading7.input )
		XCTAssertEqual(smd.attributedString().string, heading7.expectedOutput)
		
		let heading8 = StringTest(input: "## Header 2 _With Italics_", expectedOutput: "Header 2 With Italics")
		smd = SwiftyMarkdown(string:heading8.input )
		XCTAssertEqual(smd.attributedString().string, heading8.expectedOutput)
		
		let heading9 = StringTest(input: "    # Heading 1", expectedOutput: "# Heading 1")
		smd = SwiftyMarkdown(string:heading9.input )
		XCTAssertEqual(smd.attributedString().string, heading9.expectedOutput)

		let allHeaders = [heading1, heading2, heading3, heading4, heading5, heading6, heading7, heading8, heading9]
		smd = SwiftyMarkdown(string: allHeaders.map({ $0.input }).joined(separator: "\n"))
		XCTAssertEqual(smd.attributedString().string, allHeaders.map({ $0.expectedOutput}).joined(separator: "\n"))
		
		let headerString = StringTest(input: "# Header 1\n## Header 2 ##\n### Header 3 ### \n#### Header 4#### \n##### Header 5\n###### Header 6", expectedOutput: "Header 1\nHeader 2\nHeader 3\nHeader 4\nHeader 5\nHeader 6")
		smd = SwiftyMarkdown(string: headerString.input)
		XCTAssertEqual(smd.attributedString().string, headerString.expectedOutput)
		
		let headerStringWithBold = StringTest(input: "# **Bold Header 1**", expectedOutput: "Bold Header 1")
		smd = SwiftyMarkdown(string: headerStringWithBold.input)
		XCTAssertEqual(smd.attributedString().string, headerStringWithBold.expectedOutput )
		
		let headerStringWithItalic = StringTest(input: "## Header 2 _With Italics_", expectedOutput: "Header 2 With Italics")
		smd = SwiftyMarkdown(string: headerStringWithItalic.input)
		XCTAssertEqual(smd.attributedString().string, headerStringWithItalic.expectedOutput)
		
	}

	
	func testThatUndelinedHeadersAreHandledCorrectly() {

		let h1String = StringTest(input: "Header 1\n===\nSome following text", expectedOutput: "Header 1\nSome following text")
		var md = SwiftyMarkdown(string: h1String.input)
		XCTAssertEqual(md.attributedString().string, h1String.expectedOutput)
		
		let h2String = StringTest(input: "Header 2\n---\nSome following text", expectedOutput: "Header 2\nSome following text")
		md = SwiftyMarkdown(string: h2String.input)
		XCTAssertEqual(md.attributedString().string, h2String.expectedOutput)
		
		let h1StringWithBold = StringTest(input: "Header 1 **With Bold**\n===\nSome following text", expectedOutput: "Header 1 With Bold\nSome following text")
		md = SwiftyMarkdown(string: h1StringWithBold.input)
		XCTAssertEqual(md.attributedString().string, h1StringWithBold.expectedOutput)
		
		let h2StringWithItalic = StringTest(input: "Header 2 _With Italic_\n---\nSome following text", expectedOutput: "Header 2 With Italic\nSome following text")
		md = SwiftyMarkdown(string: h2StringWithItalic.input)
		XCTAssertEqual(md.attributedString().string, h2StringWithItalic.expectedOutput)
		
		let h2StringWithCode = StringTest(input: "Header 2 `With Code`\n---\nSome following text", expectedOutput: "Header 2 With Code\nSome following text")
		md = SwiftyMarkdown(string: h2StringWithCode.input)
		XCTAssertEqual(md.attributedString().string, h2StringWithCode.expectedOutput)
	}
	
	func attempt( _ challenge : TokenTest ) {
		let md = SwiftyMarkdown(string: challenge.input)
		let tokeniser = SwiftyTokeniser(with: SwiftyMarkdown.characterRules)
		let tokens = tokeniser.process(challenge.input)
		let stringTokens = tokens.filter({ $0.type == .string })
		XCTAssertEqual(challenge.tokens.count, stringTokens.count)
		XCTAssertEqual(tokens.map({ $0.outputString }).joined(), challenge.output)
		
		let existentTokenStyles = stringTokens.compactMap({ $0.characterStyles as? [CharacterStyle] })
		let expectedStyles = challenge.tokens.compactMap({ $0.characterStyles as? [CharacterStyle] })
		
		XCTAssertEqual(existentTokenStyles, expectedStyles)

		let attributedString = md.attributedString()
		XCTAssertEqual(attributedString.string, challenge.output)
		

		
	}
	
	func testThatRegularTraitsAreParsedCorrectly() {

		let aBoldString = TokenTest(input: "**A bold string**", output: "A bold string",  tokens: [
			Token(type: .string, inputString: "A bold string", characterStyles: [CharacterStyle.bold])
		])
		self.attempt(aBoldString)
		
		let stringWithABoldWord = TokenTest(input: "A string with a **bold** word", output: "A string with a bold word",  tokens: [
			Token(type: .string, inputString: "A string with a ", characterStyles: []),
			Token(type: .string, inputString: "bold", characterStyles: [CharacterStyle.bold]),
			Token(type: .string, inputString: " word", characterStyles: [])
		])
		self.attempt(stringWithABoldWord)
		
		let codeAtStartOfString = TokenTest(input: "`Code (**should** not process internal tags)`", output: "Code (**should** not process internal tags)",  tokens: [
			Token(type: .string, inputString: "Code (**should** not process internal tags) ", characterStyles: [CharacterStyle.code])
		])
		self.attempt(codeAtStartOfString)
		
		let codeWithinString = TokenTest(input: "A string with `code` (should not be indented)", output: "A string with code (should not be indented)", tokens : [
			Token(type: .string, inputString: "A string with ", characterStyles: []),
			Token(type: .string, inputString: "code", characterStyles: [CharacterStyle.code]),
			Token(type: .string, inputString: " (should not be indented)", characterStyles: [])
		])
		self.attempt(codeWithinString)
		
		let italicAtStartOfString = TokenTest(input: "*An italicised string*", output: "An italicised string", tokens : [
			Token(type: .string, inputString: "An italicised string", characterStyles: [CharacterStyle.italic])
		])
		self.attempt(italicAtStartOfString)
		
		let italicWithinString = TokenTest(input: "A string with *italicised* text", output: "A string with italicised text", tokens : [
			Token(type: .string, inputString: "A string with ", characterStyles: []),
			Token(type: .string, inputString: "italicised", characterStyles: [CharacterStyle.italic]),
			Token(type: .string, inputString: " text", characterStyles: [])
		])
		self.attempt(italicWithinString)
		
		let multipleBoldWords = TokenTest(input: "__A bold string__ with a **mix** **of** bold __styles__", output: "A bold string with a mix of bold styles", tokens : [
			Token(type: .string, inputString: "A bold string", characterStyles: [CharacterStyle.bold]),
			Token(type: .string, inputString: "with a ", characterStyles: []),
			Token(type: .string, inputString: "mix", characterStyles: [CharacterStyle.bold]),
			Token(type: .string, inputString: " ", characterStyles: []),
			Token(type: .string, inputString: "of", characterStyles: [CharacterStyle.bold]),
			Token(type: .string, inputString: " bold ", characterStyles: []),
			Token(type: .string, inputString: "styles", characterStyles: [CharacterStyle.bold])
		])
		self.attempt(multipleBoldWords)
		
		let multipleCodeWords = TokenTest(input: "`A code string` with multiple `code` `instances`", output: "A code string with multiple code instances", tokens : [
			Token(type: .string, inputString: "A code string", characterStyles: [CharacterStyle.code]),
			Token(type: .string, inputString: " with multiple ", characterStyles: []),
			Token(type: .string, inputString: "code", characterStyles: [CharacterStyle.code]),
			Token(type: .string, inputString: " ", characterStyles: []),
			Token(type: .string, inputString: "instances", characterStyles: [CharacterStyle.code])
		])
		self.attempt(multipleCodeWords)
		
		let multipleItalicWords = TokenTest(input: "_An italic string_ with a *mix* _of_ italic *styles*", output: "An italic string with a mix of italic styles", tokens : [
			Token(type: .string, inputString: "An italic string", characterStyles: [CharacterStyle.italic]),
			Token(type: .string, inputString: " with a ", characterStyles: []),
			Token(type: .string, inputString: "mix", characterStyles: [CharacterStyle.italic]),
			Token(type: .string, inputString: " ", characterStyles: []),
			Token(type: .string, inputString: "of", characterStyles: [CharacterStyle.italic]),
			Token(type: .string, inputString: " italic ", characterStyles: []),
			Token(type: .string, inputString: "styles", characterStyles: [CharacterStyle.italic])
		])
		self.attempt(multipleItalicWords)
		
		let longMixedString = TokenTest(input: "_An italic string_, **follwed by a bold one**, `with some code`, \\*\\*and some\\*\\* \\_escaped\\_ \\`characters\\`, `ending` *with* __more__ variety.", output: "An italic string, follwed by a bold one, with some code, **and some** _escaped_ `characters`, ending with more variety.", tokens : [
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
		self.attempt(longMixedString)
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
		let escapedBoldAtStart = TokenTest(input: "\\*\\*A normal string\\*\\*", output: "**A normal string**", tokens: [
			Token(type: .string, inputString: "**A normal string**", characterStyles: [])
		])
		self.attempt(escapedBoldAtStart)
		
		let escapedBoldWithin = TokenTest(input: "A string with \\*\\*escaped\\*\\* asterisks", output: "A string with **escaped** asterisks", tokens: [
			Token(type: .string, inputString: "A string with **escaped** asterisks", characterStyles: [])
		])
		self.attempt(escapedBoldWithin)
		
		let escapedItalicAtStart = TokenTest(input: "\\_A normal string\\_", output: "_A normal string_", tokens: [
			Token(type: .string, inputString: "_A normal string_", characterStyles: [])
		])
		self.attempt(escapedItalicAtStart)
		
		let escapedItalicWithin = TokenTest(input: "A string with \\_escaped\\_ underscores", output: "A string with _escaped_ underscores", tokens: [
			Token(type: .string, inputString: "A string with _escaped_ underscores", characterStyles: [])
		])
		self.attempt(escapedItalicWithin)
		
		let escapedBackticksAtStart = TokenTest(input: "\\`A normal string\\`", output: "`A normal string`", tokens: [
			Token(type: .string, inputString: "`A normal string`", characterStyles: [])
		])
		self.attempt(escapedBackticksAtStart)
		
		let escapedBacktickWithin = TokenTest(input: "A string with \\`escaped\\` backticks", output: "A string with `escaped` backticks", tokens: [
			Token(type: .string, inputString: "A string with `escaped` backticks", characterStyles: [])
		])
		self.attempt(escapedBacktickWithin)
		
		let oneEscapedAsteriskOneNormalAtStart = TokenTest(input: "\\**A normal string\\**", output: "*A normal string*", tokens: [
			Token(type: .string, inputString: "*", characterStyles: []),
			Token(type: .string, inputString: "A normal string*", characterStyles: [CharacterStyle.italic]),
		])
		self.attempt(oneEscapedAsteriskOneNormalAtStart)
		
		let oneEscapedAsteriskOneNormalWithin = TokenTest(input: "A string with \\**escaped\\** asterisks", output: "A string with *escaped* asterisks", tokens: [
			Token(type: .string, inputString: "A string with *", characterStyles: []),
			Token(type: .string, inputString: "escaped*", characterStyles: [CharacterStyle.italic]),
			Token(type: .string, inputString: " asterisks", characterStyles: [])
		])
		self.attempt(oneEscapedAsteriskOneNormalWithin)
		
		let oneEscapedAsteriskTwoNormalAtStart = TokenTest(input: "\\***A normal string*\\**", output: "**A normal string*", tokens: [
			Token(type: .string, inputString: "**", characterStyles: []),
			Token(type: .string, inputString: "A normal string", characterStyles: [CharacterStyle.italic]),
			Token(type: .string, inputString: "**", characterStyles: [])
		])
		self.attempt(oneEscapedAsteriskTwoNormalAtStart)
		
		let oneEscapedAsteriskTwoNormalWithin = TokenTest(input: "A string with *\\**escaped**\\* asterisks", output: "A string with **escaped** asterisks", tokens: [
			Token(type: .string, inputString: "A string with **", characterStyles: []),
			Token(type: .string, inputString: "escaped", characterStyles: [CharacterStyle.italic]),
			Token(type: .string, inputString: "** asterisks", characterStyles: [])
		])
		self.attempt(oneEscapedAsteriskTwoNormalWithin)
	
		
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
		
		let linkAtStart = "[Link at start](http://voyagetravelapps.com/)"
		let linkWithin = "A [Link](http://voyagetravelapps.com/)"
		let headerLink = "## [Header link](http://voyagetravelapps.com/)"
		
		let multipleLinks = "[Link 1](http://voyagetravelapps.com/), [Link 2](http://voyagetravelapps.com/)"

		let mailtoAndTwitterLinks = "Email us at [simon@voyagetravelapps.com](mailto:simon@voyagetravelapps.com) Twitter [@VoyageTravelApp](twitter://user?screen_name=VoyageTravelApp)"
		
		let syntaxErrorSquareBracketAtStart = "[Link with missing square(http://voyagetravelapps.com/)"
		let syntaxErrorSquareBracketWithin = "A [Link(http://voyagetravelapps.com/)"
		
		let syntaxErrorParenthesisAtStart = "[Link with missing parenthesis](http://voyagetravelapps.com/"
		let syntaxErrorParenthesisWithin = "A [Link](http://voyagetravelapps.com/"
		
		var md = SwiftyMarkdown(string: linkAtStart)
		XCTAssertEqual(md.attributedString().string, "Link at start")
		
		md = SwiftyMarkdown(string: linkWithin)
		XCTAssertEqual(md.attributedString().string, "A Link")
		
		md = SwiftyMarkdown(string: headerLink)
		XCTAssertEqual(md.attributedString().string, "Header link")
		
		md = SwiftyMarkdown(string: multipleLinks)
		XCTAssertEqual(md.attributedString().string, "Link 1, Link 2")
		
		md = SwiftyMarkdown(string: syntaxErrorSquareBracketAtStart)
		XCTAssertEqual(md.attributedString().string, "[Link with missing square(http://voyagetravelapps.com/)")
		
		md = SwiftyMarkdown(string: syntaxErrorSquareBracketWithin)
		XCTAssertEqual(md.attributedString().string, "A [Link(http://voyagetravelapps.com/)")
		
		md = SwiftyMarkdown(string: syntaxErrorParenthesisAtStart)
		XCTAssertEqual(md.attributedString().string, "[Link with missing parenthesis](http://voyagetravelapps.com/")
		
		md = SwiftyMarkdown(string: syntaxErrorParenthesisWithin)
		XCTAssertEqual(md.attributedString().string, "A [Link](http://voyagetravelapps.com/")
		
		md = SwiftyMarkdown(string: mailtoAndTwitterLinks)
		XCTAssertEqual(md.attributedString().string, "Email us at simon@voyagetravelapps.com Twitter @VoyageTravelApp")
		
	
		
//		let mailtoAndTwitterLinks = "Twitter [@VoyageTravelApp](twitter://user?screen_name=VoyageTravelApp)"
//		let md = SwiftyMarkdown(string: mailtoAndTwitterLinks)
//		XCTAssertEqual(md.attributedString().string, "Twitter @VoyageTravelApp")
	}
	
    /*
        The reason for this test is because the list of items dropped every other item in bullet lists marked with "-"
        The faulty result was: "A cool title\n \n- Här har vi svenska ÅÄÖåäö tecken\n \nA Link"
        As you can see, "- Point number one" and "- Point number two" are mysteriously missing.
        It incorrectly identified rows as `Alt-H2` 
     */
    func testInternationalCharactersInList() {
        
        let expected = "A cool title\n \n- Point number one\n- Här har vi svenska ÅÄÖåäö tecken\n- Point number two\n \nA Link"
        let input = "# A cool title\n\n- Point number one\n- Här har vi svenska ÅÄÖåäö tecken\n- Point number two\n\n[A Link](http://dooer.com)"
        let output = SwiftyMarkdown(string: input).attributedString().string

        XCTAssertEqual(output, expected)
        
    }
	
	func testReportedCrashingStrings() {
		let text = "[**\\!bang**](https://duckduckgo.com/bang) "
		let expected = "\\!bang"
		let output = SwiftyMarkdown(string: text).attributedString().string
		XCTAssertEqual(output, expected)
	}
	
}
