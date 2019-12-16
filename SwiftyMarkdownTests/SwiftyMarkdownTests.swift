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
		
		let att = attributedString.attribute(.font, at: 0, effectiveRange: nil)
		XCTAssertNotNil(att)
		
	}
	
	func testThatRegularTraitsAreParsedCorrectly() {

		let challenge1 = TokenTest(input: "**A bold string**", output: "A bold string",  tokens: [
			Token(type: .string, inputString: "A bold string", characterStyles: [CharacterStyle.bold])
		])
		self.attempt(challenge1)
		
		let challenge2 = TokenTest(input: "A string with a **bold** word", output: "A string with a bold word",  tokens: [
			Token(type: .string, inputString: "A string with a ", characterStyles: []),
			Token(type: .string, inputString: "bold", characterStyles: [CharacterStyle.bold]),
			Token(type: .string, inputString: " word", characterStyles: [])
		])
		self.attempt(challenge2)
		
		
		let codeAtStartOfString = "`Code (should not be indented)`"
		let codeWithinString = "A string with `code` (should not be indented)"
		let italicAtStartOfString = "*An italicised string*"
		let italicWithinString = "A string with *italicised* text"
		
		let multipleBoldWords = "__A bold string__ with a **mix** **of** bold __styles__"
		let multipleCodeWords = "`A code string` with multiple `code` `instances`"
		let multipleItalicWords = "_An italic string_ with a *mix* _of_ italic *styles*"
		
		let longMixedString = "_An italic string_, **follwed by a bold one**, `with some code`, \\*\\*and some\\*\\* \\_escaped\\_ \\`characters\\`, `ending` *with* __more__ variety."
		
		
		var md = SwiftyMarkdown(string: codeAtStartOfString)
		XCTAssertEqual(md.attributedString().string, "Code (should not be indented)")
		
		md = SwiftyMarkdown(string: codeWithinString)
		XCTAssertEqual(md.attributedString().string, "A string with code (should not be indented)")
		
		md = SwiftyMarkdown(string: italicAtStartOfString)
		XCTAssertEqual(md.attributedString().string, "An italicised string")
		
		md = SwiftyMarkdown(string: italicWithinString)
		XCTAssertEqual(md.attributedString().string, "A string with italicised text")
		
		md = SwiftyMarkdown(string: multipleBoldWords)
		XCTAssertEqual(md.attributedString().string, "A bold string with a mix of bold styles")
		
		md = SwiftyMarkdown(string: multipleCodeWords)
		XCTAssertEqual(md.attributedString().string, "A code string with multiple code instances")
		
		md = SwiftyMarkdown(string: multipleItalicWords)
		XCTAssertEqual(md.attributedString().string, "An italic string with a mix of italic styles")

		md = SwiftyMarkdown(string: longMixedString)
		XCTAssertEqual(md.attributedString().string, "An italic string, follwed by a bold one, with some code, **and some** _escaped_ `characters`, ending with more variety.")
		
	}
	
	func testThatMarkdownMistakesAreHandledAppropriately() {
		let mismatchedBoldCharactersAtStart = "**This should be bold*"
		let mismatchedBoldCharactersWithin = "A string *that should be italic**"
		
		var md = SwiftyMarkdown(string: mismatchedBoldCharactersAtStart)
		XCTAssertEqual(md.attributedString().string, "This should be bold")
		
		md = SwiftyMarkdown(string: mismatchedBoldCharactersWithin)
		XCTAssertEqual(md.attributedString().string, "A string that should be italic")
		
	}
	
	func testThatEscapedCharactersAreEscapedCorrectly() {
		let escapedBoldAtStart = "\\*\\*A normal string\\*\\*"
		let escapedBoldWithin = "A string with \\*\\*escaped\\*\\* asterisks"
		
		let escapedItalicAtStart = "\\_A normal string\\_"
		let escapedItalicWithin = "A string with \\_escaped\\_ underscores"
		
		let escapedBackticksAtStart = "\\`A normal string\\`"
		let escapedBacktickWithin = "A string with \\`escaped\\` backticks"
		
		let oneEscapedAsteriskOneNormalAtStart = "\\**A normal string\\**"
		let oneEscapedAsteriskOneNormalWithin = "A string with \\**escaped\\** asterisks"
		
		let oneEscapedAsteriskTwoNormalAtStart = "\\***A normal string*\\**"
		let oneEscapedAsteriskTwoNormalWithin = "A string with *\\**escaped**\\* asterisks"
		
		var md = SwiftyMarkdown(string: escapedBoldAtStart)
		XCTAssertEqual(md.attributedString().string, "**A normal string**")

		md = SwiftyMarkdown(string: escapedBoldWithin)
		XCTAssertEqual(md.attributedString().string, "A string with **escaped** asterisks")
		
		md = SwiftyMarkdown(string: escapedItalicAtStart)
		XCTAssertEqual(md.attributedString().string, "_A normal string_")
		
		md = SwiftyMarkdown(string: escapedItalicWithin)
		XCTAssertEqual(md.attributedString().string, "A string with _escaped_ underscores")
		
		md = SwiftyMarkdown(string: escapedBackticksAtStart)
		XCTAssertEqual(md.attributedString().string, "`A normal string`")
		
		md = SwiftyMarkdown(string: escapedBacktickWithin)
		XCTAssertEqual(md.attributedString().string, "A string with `escaped` backticks")
		
		md = SwiftyMarkdown(string: oneEscapedAsteriskOneNormalAtStart)
		XCTAssertEqual(md.attributedString().string, "*A normal string*")
		
		md = SwiftyMarkdown(string: oneEscapedAsteriskOneNormalWithin)
		XCTAssertEqual(md.attributedString().string, "A string with *escaped* asterisks")
		
		md = SwiftyMarkdown(string: oneEscapedAsteriskTwoNormalAtStart)
		XCTAssertEqual(md.attributedString().string, "*A normal string*")
		
		md = SwiftyMarkdown(string: oneEscapedAsteriskTwoNormalWithin)
		XCTAssertEqual(md.attributedString().string, "A string with *escaped* asterisks")
		
	}
	
	func testThatAsterisksAndUnderscoresNotAttachedToWordsAreNotRemoved() {
		let asteriskSpace = """
An asterisk followed by a space: *
Line break
"""
		let backtickSpace = "A backtick followed by a space: ` "
		let underscoreSpace = "An underscore followed by a space: _ "

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
		XCTAssertEqual(md.attributedString().string, "A bold word followed by an asterisk * ")
		
		md = SwiftyMarkdown(string: backtickWithCode)
		XCTAssertEqual(md.attributedString().string, "A code word followed by a backtick ` ")
		
		md = SwiftyMarkdown(string: underscoreWithItalic)
		XCTAssertEqual(md.attributedString().string, "An italic word followed by an underscore _ ")
		
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
