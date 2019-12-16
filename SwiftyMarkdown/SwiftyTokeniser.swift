//
//  SwiftyTokeniser.swift
//  SwiftyMarkdown
//
//  Created by Simon Fairbairn on 16/12/2019.
//  Copyright © 2019 Voyage Travel Apps. All rights reserved.
//

import Foundation

public protocol CharacterStyling {
	
}

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

public struct SwiftyTagging {
	public let openTag : String
	public let intermediateTag : String?
	public let closingTag : String?
	public let escapeString : String?
	public let styles : [Int : [CharacterStyling]]
	public var maxTags : Int = 1
	public var spacesAllowed : SpaceAllowed = .oneSide
	public var cancels : Cancel = .none
	
	public init(openTag: String, intermediateTag: String? = nil, closingTag: String? = nil, escapeString: String? = nil, styles: [Int : [CharacterStyling]] = [:], maxTags : Int = 1) {
		self.openTag = openTag
		self.intermediateTag = intermediateTag
		self.closingTag = closingTag
		self.escapeString = escapeString
		self.styles = styles
		self.maxTags = maxTags
	}
}

// Token definition
public enum TokenType {
	case openTag
	case intermediateTag
	case closeTag
	case string
	case escape
}



public struct Token {
	public let id = UUID().uuidString
	public let type : TokenType
	public let inputString : String
	public var characterStyles : [CharacterStyling] = []
	public var count : Int = 0
	public var shouldSkip : Bool = false
	public var outputString : String {
		get {
			switch self.type {
			case .openTag, .closeTag, .intermediateTag:
				if count == 0 {
					return ""
				} else {
					let range = inputString.startIndex..<inputString.index(inputString.startIndex, offsetBy: self.count)
					return String(inputString[range])
				}
			default:
				return inputString
			}
		}
	}
	public init( type : TokenType, inputString : String, characterStyles : [CharacterStyling] = []) {
		self.type = type
		self.inputString = inputString
		self.characterStyles = characterStyles
	}
}

public class SwiftyTokeniser {
	let rules : [SwiftyTagging]
	
	public init( with rules : [SwiftyTagging] ) {
		self.rules = rules
	}
	
	public func process( _ inputString : String ) -> [Token] {
		guard rules.count > 0 else {
			return [Token(type: .string, inputString: inputString)]
		}
		var tagLookup : [String : [Int : [CharacterStyling]]] = [:]
		var finalTokens : [Token] = []
		var mutableRules = self.rules
		let firstRule = mutableRules.removeFirst()
		tagLookup[firstRule.openTag] = firstRule.styles
		var tokens = self.scan(inputString, with: firstRule)
		if firstRule.cancels != .allRemaining {
			while !mutableRules.isEmpty {
				let nextRule = mutableRules.removeFirst()
				tagLookup[nextRule.openTag] = nextRule.styles
				var newTokens : [Token] = []
				for token in tokens {
					switch token.type {
					case .string:
						newTokens.append(contentsOf: self.scan(token.outputString, with: nextRule))
					default:
						newTokens.append(token)
					}
				}
				tokens = newTokens
	//			let tokens = self.scan(string, with: rule)
				switch nextRule.cancels {
				case .allRemaining:
					break
				default:
					continue
				}
			}
		}

		var mutableTokens : [Token] = tokens
		for (idx, token) in tokens.enumerated() {
			switch token.type {
			case .escape:
				print( "Found escape (\(token.inputString))" )
				finalTokens.append(token)
			case .openTag:
				
				let theToken = mutableTokens[idx]
				print ("Found open tag with tag count \(theToken.count) tags: \(theToken.inputString)" )
				guard theToken.count > 0 else {
					finalTokens.append(theToken)
					continue
				}
				
				let startIdx = idx
				var endIdx : Int? = nil

				if let nextTokenIdx = mutableTokens.firstIndex(where: { $0.inputString == theToken.inputString && $0.type == theToken.type && $0.count == theToken.count && $0.id != theToken.id }) {
					endIdx = nextTokenIdx
				}
				guard let existentEnd = endIdx else {
					finalTokens.append(theToken)
					continue
				}
				
				let styles : [CharacterStyling] = tagLookup[String(theToken.inputString.first!)]?[theToken.count] ?? []
				for i in startIdx..<existentEnd {
					var otherTokens = mutableTokens[i]
					for style in styles {
						otherTokens.characterStyles.append(style)
					}
					mutableTokens[i] = otherTokens
				}
				var newToken = theToken
				newToken.count = 0
				finalTokens.append(newToken)
				mutableTokens[idx] = newToken
				
				var closeToken = mutableTokens[existentEnd]
				closeToken.count = 0
				mutableTokens[existentEnd] = closeToken
				
			case .string:
				let theToken = mutableTokens[idx]
				print ("Found String: \(theToken.inputString)" )
				finalTokens.append(theToken)
			default:
				break
			}
		}
		return finalTokens
		
	}
	
	func scan( _ string : String, with rule : SwiftyTagging) -> [Token] {
		let scanner = Scanner(string: string)
		scanner.charactersToBeSkipped = nil
		var tokens : [Token] = []
		let set = CharacterSet(charactersIn: "\(rule.openTag)\(rule.intermediateTag ?? "")\(rule.closingTag ?? "")\(rule.escapeString ?? "")")
		var openingString = ""
		while !scanner.isAtEnd {
			
			if #available(iOS 13.0, *) {
				if let start = scanner.scanUpToCharacters(from: set) {
					openingString.append(start)
				}
			} else {
				var string : NSString?
				scanner.scanUpToCharacters(from: set, into: &string)
				if let existentString = string as String? {
					openingString.append(existentString)
				}
				// Fallback on earlier versions
			}
			
			let lastChar : String?
			if #available(iOS 13.0, *) {
				lastChar = ( scanner.currentIndex > string.startIndex ) ? String(string[string.index(before: scanner.currentIndex)..<scanner.currentIndex]) : nil
			} else {
				let scanLocation = string.index(string.startIndex, offsetBy: scanner.scanLocation)
				lastChar = ( scanLocation > string.startIndex ) ? String(string[string.index(before: scanLocation)..<scanLocation]) : nil
			}
			let maybeFoundChars : String?
			if #available(iOS 13.0, *) {
				maybeFoundChars = scanner.scanCharacters(from: set )
			} else {
				var string : NSString?
				scanner.scanCharacters(from: set, into: &string)
				maybeFoundChars = string as String?
			}
			
			let nextChar : String?
			if #available(iOS 13.0, *) {
				 nextChar = (scanner.currentIndex != string.endIndex) ? String(string[scanner.currentIndex]) : nil
			} else {
				let scanLocation = string.index(string.startIndex, offsetBy: scanner.scanLocation)
				nextChar = (scanLocation != string.endIndex) ? String(string[scanLocation]) : nil
			}
			
			guard let foundChars = maybeFoundChars else {
				tokens.append(Token(type: .string, inputString: "\(openingString)"))
				continue
			}
			
			
			
			if !validateSpacing(nextCharacter: nextChar, previousCharacter: lastChar, with: rule) {
				var escaped = foundChars.replacingOccurrences(of: "\(rule.escapeString ?? "")\(rule.openTag)", with: rule.openTag)
				if let hasIntermediateTag = rule.intermediateTag {
					escaped = foundChars.replacingOccurrences(of: "\(rule.escapeString ?? "")\(hasIntermediateTag)", with: hasIntermediateTag)
				}
				if let existentClosingTag = rule.closingTag {
					escaped = foundChars.replacingOccurrences(of: "\(rule.escapeString ?? "")\(existentClosingTag)", with: existentClosingTag)
				}
				
				openingString.append(escaped)
				continue
			}
			if !openingString.isEmpty {
				tokens.append(Token(type: .string, inputString: "\(openingString)"))
				openingString = ""
			}
			
			
			var cumulativeString = ""
			var openString = ""
			var closedString = ""
			var maybeEscapeNext = false
			
			func addToken( for type : TokenType ) {
				var inputString : String
				switch type {
				case .openTag:
					inputString = openString
				case .closeTag:
					inputString = closedString
				default:
					inputString = ""
				}
				guard !inputString.isEmpty else {
					return
				}
				var token = Token(type: type, inputString: inputString)
				token.count = inputString.count
				tokens.append(token)
				
				switch type {
				case .openTag:
					openString = ""
				case .closeTag:
					closedString = ""
				default:
					break
				}
			}
			
			
			for char in foundChars {
				cumulativeString.append(char)
				if maybeEscapeNext {
					
					var escaped = cumulativeString
					if String(char) == rule.openTag || String(char) == rule.intermediateTag || String(char) == rule.closingTag {
						escaped = String(cumulativeString.replacingOccurrences(of: rule.escapeString ?? "", with: ""))
					}
					
					tokens.append(Token(type: .string, inputString: escaped ))
					cumulativeString = ""
					maybeEscapeNext = false
				}
				
				if cumulativeString == rule.escapeString {
					maybeEscapeNext = true
					addToken(for: .openTag)
					addToken(for: .closeTag)
					continue
				}
				
				if cumulativeString == rule.openTag {
					openString.append(char)
					cumulativeString = ""
				} else if cumulativeString == rule.closingTag {
					closedString.append(char)
					cumulativeString = ""
				}
			}
			
			// If we're here, it means that an escape character was found but without a corresponding
			// tag, which means it might belong to a different rule.
			// It should be added to the next group of regular characters
			if maybeEscapeNext {
				openingString.append( cumulativeString )
			}
			addToken(for: .openTag)
			addToken(for: .closeTag)
		
		}
		return tokens
	}
	
	func validateSpacing( nextCharacter : String?, previousCharacter : String?, with rule : SwiftyTagging ) -> Bool {
		switch rule.spacesAllowed {
		case .leadingSide:
			guard nextCharacter != nil else {
				return true
			}
			if nextCharacter == " "  {
				return false
			}
		case .trailingSide:
			guard previousCharacter != nil else {
				return true
			}
			if previousCharacter == " " {
				return false
			}
		case .no:
			switch (previousCharacter, nextCharacter) {
			case (nil, nil), ( " ", _ ), (  _, " " ):
				return false
			default:
				return true
			}
		
		case .oneSide:
			switch (previousCharacter, nextCharacter) {
			case  (nil, " " ), (" ", nil), (" ", " " ):
				return false
			default:
				return true
			}
		default:
			break
		}
		return true
	}
	
}
