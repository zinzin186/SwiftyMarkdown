//
//  SwiftyMarkdownAttributedStringTests.swift
//  SwiftyMarkdownTests
//
//  Created by Simon Fairbairn on 17/12/2019.
//  Copyright © 2019 Voyage Travel Apps. All rights reserved.
//

import XCTest
@testable import SwiftyMarkdown

class SwiftyMarkdownAttributedStringTests: XCTestCase {
	
	func testThatAttributesAreAppliedCorrectly() {
		
		let string = """
# Heading 1

A more *complicated* example. This one has **it all**. Here is a [link](http://voyagetravelapps.com/).

## Heading 2

## Heading 3

> This one is a blockquote
"""
		let md = SwiftyMarkdown(string: string)
		let attributedString = md.attributedString()
		
		XCTAssertNotNil(attributedString)
		
		XCTAssertEqual(attributedString.string, "Heading 1\nA more complicated example. This one has it all. Here is a link.\nHeading 2\nHeading 3\nThis one is a blockquote")
		
		
	}
	
}
