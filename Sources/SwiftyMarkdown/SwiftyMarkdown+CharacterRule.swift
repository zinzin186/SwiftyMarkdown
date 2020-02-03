//
//  SwiftyMarkdown+CharacterRule.swift
//  SwiftyMarkdown
//
//  Created by Simon Fairbairn on 04/02/2020.
//

import Foundation

public extension CharacterRule {
	init( openTag : String, intermediateTag : String, closingTag : String, escapeCharacter: Character? = nil, styles: [Int : [CharacterStyling]] = [:], metadataLookup : Bool ) {
		self.openTag = openTag
		self.intermediateTag = intermediateTag
		self.closingTag = closingTag
		self.escapeCharacter = escapeCharacter
		self.styles = styles
		self.minTags = 1
		self.maxTags = 1
		self.cancels = .none
		self.metadataLookup = metadataLookup
		self.tagVarieties = [:]
		for i in minTags...maxTags {
			self.tagVarieties[i] = openTag.repeating(i)
		}
	}
}
