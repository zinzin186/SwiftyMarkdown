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


public enum EscapeCharacterRule {
	case keep
	case remove
}

public struct EscapeCharacter {
	let character : Character
	let rule : EscapeCharacterRule
	public init( character : Character, rule : EscapeCharacterRule ) {
		self.character = character
		self.rule = rule
	}
}

public enum CharacterRuleTagType {
	case open
	case close
	case metadataOpen
	case metadataClose
	case repeating
}


public struct CharacterRuleTag {
	let tag : String
	let escapeCharacters : [EscapeCharacter]
	let type : CharacterRuleTagType
	let min : Int
	let max : Int
	
	public init( tag : String, type : CharacterRuleTagType, escapeCharacters : [EscapeCharacter] = [EscapeCharacter(character: "\\", rule: .remove)], min : Int = 1, max : Int = 1) {
		self.tag = tag
		self.type = type
		self.escapeCharacters = escapeCharacters
		self.min = min
		self.max = max
	}
	
	public func escapeCharacter( for character : Character ) -> EscapeCharacter? {
		return self.escapeCharacters.filter({ $0.character == character }).first
	}
}

public struct CharacterRule : CustomStringConvertible {
	

	public let tags : [CharacterRuleTag]
	public let styles : [Int : [CharacterStyling]]
	public var minTags : Int = 1
	public var maxTags : Int = 1
	public var spacesAllowed : SpaceAllowed = .oneSide
	public var cancels : Cancel = .none
	public var metadataLookup : Bool = false
	public var isRepeatingTag : Bool {
		return self.primaryTag.type == .repeating
	}
	public var isSelfContained = false
	
	public var description: String {
		return "Character Rule with Open tag: \(self.primaryTag.tag) and current styles : \(self.styles) "
	}
	
	public let primaryTag : CharacterRuleTag
	
	public func tag( for type : CharacterRuleTagType ) -> CharacterRuleTag? {
		return self.tags.filter({ $0.type == type }).first ?? nil
	}
	
	public init(primaryTag: CharacterRuleTag, otherTags: [CharacterRuleTag], styles: [Int : [CharacterStyling]] = [:], cancels : Cancel = .none, metadataLookup : Bool = false, spacesAllowed: SpaceAllowed = .oneSide, isSelfContained : Bool = false) {
		self.primaryTag = primaryTag
		self.tags = otherTags
		self.styles = styles
		self.cancels = cancels
		self.metadataLookup = metadataLookup
		self.spacesAllowed = spacesAllowed
		self.isSelfContained = isSelfContained
	}
}

