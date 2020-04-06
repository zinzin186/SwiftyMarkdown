//
//  CharacterRule.swift
//  SwiftyMarkdown
//
//  Created by Simon Fairbairn on 04/02/2020.
//

import Foundation

public enum SpaceAllowed {
	case no
	case bothSides
	case oneSide
	case leadingSide
	case trailingSide
}

public enum Cancel {
	case none
	case allRemaining
	case currentSet
}

public struct v2_CharacterRule {
	public let openTag : String
	public let closeTag : String?
	public let escapeCharacter : Character?
	public let styles : [Int : [CharacterStyling]]
	public let minTags : Int
	public let maxTags : Int
	public let metadataOpen : Character?
	public let metadataClose : Character?
}

public struct CharacterRule : CustomStringConvertible {
	public let openTag : String
	public var closeTag : String? {
		get {
			return self.closingTag
		}
	}
	public let intermediateTag : String?
	public let closingTag : String?
	public let escapeCharacter : Character?
	public let metadataOpen : Character?
	public let metadataClose : Character?
	public let styles : [Int : [CharacterStyling]]
	public var minTags : Int = 1
	public var maxTags : Int = 1
	public var spacesAllowed : SpaceAllowed = .oneSide
	public var cancels : Cancel = .none
	public var metadataLookup : Bool = false
	public var isRepeatingTag : Bool {
		return self.closingTag == nil && self.intermediateTag == nil
	}
	public var tagVarieties : [Int : String]
	public var isSelfContained = false
	
	public var description: String {
		return "Character Rule with Open tag: \(self.openTag) and current styles : \(self.styles) "
	}
	
	public init(openTag: String, intermediateTag: String? = nil, closingTag: String? = nil, escapeCharacter: Character? = nil, styles: [Int : [CharacterStyling]] = [:], minTags : Int = 1, maxTags : Int = 1, cancels : Cancel = .none, metadataLookup : Bool = false, spacesAllowed: SpaceAllowed = .oneSide, metadataOpen : Character? = nil, metadataClose : Character? = nil) {
		self.openTag = openTag
		self.intermediateTag = intermediateTag
		self.closingTag = closingTag
		self.escapeCharacter = escapeCharacter
		self.styles = styles
		self.minTags = minTags
		self.maxTags = maxTags
		self.cancels = cancels
		self.metadataLookup = metadataLookup
		self.spacesAllowed = spacesAllowed
		self.tagVarieties = [:]
		self.metadataOpen = metadataOpen
		self.metadataClose = metadataClose
		for i in minTags...maxTags {
			self.tagVarieties[i] = openTag.repeating(i)
		}
	}
}

