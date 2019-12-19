//
//  SwiftyTokeniser.swift
//  SwiftyMarkdown
//
//  Created by Simon Fairbairn on 16/12/2019.
//  Copyright © 2019 Voyage Travel Apps. All rights reserved.
//
import Foundation
import os.log

extension OSLog {
	private static var subsystem = "SwiftyTokeniser"
	static let tokenising = OSLog(subsystem: subsystem, category: "Tokenising")
	static let styling = OSLog(subsystem: subsystem, category: "Styling")
}

// Tag definition
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

public struct CharacterRule : CustomStringConvertible {
	public let openTag : String
	public let intermediateTag : String?
	public let closingTag : String?
	public let escapeCharacter : Character?
	public let styles : [Int : [CharacterStyling]]
	public var maxTags : Int = 1
	public var spacesAllowed : SpaceAllowed = .oneSide
	public var cancels : Cancel = .none
	
	public var description: String {
		return "Character Rule with Open tag: \(self.openTag) and current styles : \(self.styles) "
	}
	
	public init(openTag: String, intermediateTag: String? = nil, closingTag: String? = nil, escapeCharacter: Character? = nil, styles: [Int : [CharacterStyling]] = [:], maxTags : Int = 1, cancels : Cancel = .none) {
		self.openTag = openTag
		self.intermediateTag = intermediateTag
		self.closingTag = closingTag
		self.escapeCharacter = escapeCharacter
		self.styles = styles
		self.maxTags = maxTags
		self.cancels = cancels
	}
}

// Token definition
public enum TokenType {
	case repeatingTag
	case openTag
	case intermediateTag
	case closeTag
	case string
	case escape
	case replacement
}



public struct Token {
	public let id = UUID().uuidString
	public let type : TokenType
	public let inputString : String
	public fileprivate(set) var metadataString : String? = nil
	public fileprivate(set) var characterStyles : [CharacterStyling] = []
	public fileprivate(set) var count : Int = 0
	public fileprivate(set) var shouldSkip : Bool = false
	public fileprivate(set) var tokenIndex : Int = -1
	public fileprivate(set) var isProcessed : Bool = false
	public fileprivate(set) var isMetadata : Bool = false
	public var outputString : String {
		get {
			switch self.type {
			case .repeatingTag:
				if count == 0 {
					return ""
				} else {
					let range = inputString.startIndex..<inputString.index(inputString.startIndex, offsetBy: self.count)
					return String(inputString[range])
				}
			case .openTag, .closeTag, .intermediateTag:
				return (self.isProcessed || self.isMetadata) ? "" : inputString
			case .escape, .string:
				return (self.isProcessed || self.isMetadata) ? "" : inputString
			case .replacement:
				return self.inputString
			}
		}
	}
	public init( type : TokenType, inputString : String, characterStyles : [CharacterStyling] = []) {
		self.type = type
		self.inputString = inputString
		self.characterStyles = characterStyles
	}
	
	func newToken( fromSubstring string: String,  isReplacement : Bool) -> Token {
		var newToken = Token(type: (isReplacement) ? .replacement : .string , inputString: string, characterStyles: self.characterStyles)
		newToken.metadataString = self.metadataString
		newToken.isMetadata = self.isMetadata
		newToken.isProcessed = self.isProcessed
		return newToken
	}
}

extension Sequence where Iterator.Element == Token {
    var oslogDisplay: String {
		return "[\"\(self.map( {  ($0.outputString.isEmpty) ? "\($0.type): \($0.inputString)" : $0.outputString }).joined(separator: "\", \""))\"]"
    }
}

public class SwiftyTokeniser {
	let rules : [CharacterRule]
	var replacements : [String : [Token]] = [:]
	
	public init( with rules : [CharacterRule] ) {
		self.rules = rules
	}
	
	public func process( _ inputString : String ) -> [Token] {
		guard rules.count > 0 else {
			return [Token(type: .string, inputString: inputString)]
		}

		var currentTokens : [Token] = []
		var mutableRules = self.rules
		while !mutableRules.isEmpty {
			let nextRule = mutableRules.removeFirst()
			os_log("------------------------------", log: .tokenising, type: .info)
			os_log("RULE: %@", log: OSLog.tokenising, type:.info , nextRule.description)
			os_log("Applying rule to : %@", log: OSLog.tokenising, type:.info , currentTokens.oslogDisplay )
	
			if currentTokens.isEmpty {
				// This means it's the first time through
				currentTokens = self.applyStyles(to: self.scan(inputString, with: nextRule), usingRule: nextRule)
				continue
			}
			
			var outerStringTokens : [Token] = []
			var innerStringTokens : [Token] = []
			var isOuter = true
			for idx in 0..<currentTokens.count {
				let nextToken = currentTokens[idx]
				if nextToken.type == .openTag && nextToken.isProcessed {
					isOuter = false
				}
				if nextToken.type == .closeTag {
					
					let ref = UUID().uuidString
					outerStringTokens.append(Token(type: .replacement, inputString: ref))

					innerStringTokens.append(nextToken)
					self.replacements[ref] = self.handleReplacementTokens(innerStringTokens, with: nextRule)
					
					innerStringTokens.removeAll()
					isOuter = true
					continue
				}
				(isOuter) ? outerStringTokens.append(nextToken) : innerStringTokens.append(nextToken)
			}
			
			currentTokens = self.handleReplacementTokens(outerStringTokens, with: nextRule)
			
			var finalTokens : [Token] = []
			for token in currentTokens {
				guard token.type == .replacement else {
					finalTokens.append(token)
					continue
				}
				if let hasReplacement = self.replacements[token.inputString] {
					for var repToken in hasReplacement {
						guard repToken.type == .string else {
							finalTokens.append(repToken)
							continue
						}
						repToken.characterStyles.append(contentsOf: token.characterStyles)
						finalTokens.append(repToken)
					}
				}
			}
			currentTokens = finalTokens
			
			
			// Each string could have additional tokens within it, so they have to be scanned as well with the current rule.
			// The one string token might then be exploded into multiple more tokens
		}

		
		
		os_log("Final output: %@", log: .tokenising, type: .info, currentTokens.oslogDisplay)
		os_log("=====RULE PROCESSING COMPLETE=====", log: .tokenising, type: .info)
		os_log("==================================", log: .tokenising, type: .info)
		
		return currentTokens
	}
	
	func scanReplacements(_ replacements : [Token], in token : Token ) -> [Token] {
		guard !token.outputString.isEmpty && !replacements.isEmpty else {
			return [token]
		}
		
		
		var outputTokens : [Token] = []
		let scanner = Scanner(string: token.outputString)
		scanner.charactersToBeSkipped = nil
		var repTokens = replacements
		while !scanner.isAtEnd {
			var outputString : String = ""
			var testString = "\n"
			if repTokens.count > 0 {
				testString = repTokens.removeFirst().inputString
			}
			
			if #available(iOS 13.0, *) {
				if let nextString = scanner.scanUpToString(testString) {
					outputString = nextString
					outputTokens.append(token.newToken(fromSubstring: outputString, isReplacement: false))
					if let outputToken = scanner.scanString(testString) {
						outputTokens.append(token.newToken(fromSubstring: outputToken, isReplacement: true))
					}
				} else if let outputToken = scanner.scanString(testString) {
					outputTokens.append(token.newToken(fromSubstring: outputToken, isReplacement: true))
				}
			} else {
				var oldString : NSString? = nil
				var tokenString : NSString? = nil
				scanner.scanUpTo(testString, into: &oldString)
				if let nextString = oldString {
					outputString = nextString as String
					outputTokens.append(token.newToken(fromSubstring: outputString, isReplacement: false))
					scanner.scanString(testString, into: &tokenString)
					if let outputToken = tokenString as String? {
						outputTokens.append(token.newToken(fromSubstring: outputToken, isReplacement: true))
					}
				} else {
					scanner.scanString(testString, into: &tokenString)
					if let outputToken = tokenString as String? {
						outputTokens.append(token.newToken(fromSubstring: outputToken, isReplacement: true))
					}
				}
			}
		}
		return outputTokens
	}
	
	func scanReplacementTokens( _ tokens : [Token], with rule : CharacterRule ) -> [Token] {
		guard tokens.count > 0 else {
			return []
		}
		
		let combinedString = tokens.map({ $0.outputString }).joined()
		
		let nextTokens = self.scan(combinedString, with: rule)
		var replacedTokens = self.applyStyles(to: nextTokens, usingRule: rule)
		
		for idx in 0..<replacedTokens.count {
			guard replacedTokens[idx].type == .string || replacedTokens[idx].type == .replacement else {
				continue
			}
			if tokens.first!.metadataString != nil && replacedTokens[idx].metadataString == nil {
				replacedTokens[idx].metadataString = tokens.first!.metadataString
			}
			replacedTokens[idx].characterStyles.append(contentsOf: tokens.first!.characterStyles)
		}
		
		// Swap replacement tokens back in, remembering to apply newly found styles to the replacement token
		let replacements = tokens.filter({ $0.type == .replacement })
		var outputTokens : [Token] = []
		for token in replacedTokens {
			guard token.type == .string else {
				outputTokens.append(token)
				continue
			}
			outputTokens.append(contentsOf: self.scanReplacements(replacements, in: token))
		}
		
		return outputTokens
	}
	
	func handleReplacementTokens( _ incomingTokens : [Token], with rule : CharacterRule) -> [Token] {
	
		// Online combine string and replacements that are next to each other.
		os_log("Handling replacements: %@", log: .tokenising, type: .info, incomingTokens.oslogDisplay)
		
		var newTokenSet : [Token] = []
		var currentTokenSet : [Token] = []
		for i in 0..<incomingTokens.count {
			guard incomingTokens[i].type == .string || incomingTokens[i].type == .replacement else {
				newTokenSet.append(contentsOf: self.scanReplacementTokens(currentTokenSet, with: rule))
				newTokenSet.append(incomingTokens[i])
				currentTokenSet.removeAll()
				continue
			}
			guard !incomingTokens[i].isProcessed && !incomingTokens[i].isMetadata && !incomingTokens[i].shouldSkip else {
				newTokenSet.append(contentsOf: self.scanReplacementTokens(currentTokenSet, with: rule))
				newTokenSet.append(incomingTokens[i])
				currentTokenSet.removeAll()
				continue
			}
			currentTokenSet.append(incomingTokens[i])
		}
		newTokenSet.append(contentsOf: self.scanReplacementTokens(currentTokenSet, with: rule))
		
		os_log("Replacements: %@", log: .tokenising, type: .info, newTokenSet.oslogDisplay)

		return newTokenSet
	}
	
	
	func handleClosingTagFromOpenTag(withIndex index : Int, in tokens: inout [Token], following rule : CharacterRule ) {
		
		guard rule.closingTag != nil else {
			return
		}
		guard let closeTokenIdx = tokens.firstIndex(where: { $0.type == .closeTag && !$0.isProcessed }) else {
			return
		}
		
		var metadataIndex = index
		// If there's an intermediate tag, get the index of that
		if rule.intermediateTag != nil {
			guard let nextTokenIdx = tokens.firstIndex(where: { $0.type == .intermediateTag  && !$0.isProcessed }) else {
				return
			}
			metadataIndex = nextTokenIdx
			let styles : [CharacterStyling] = rule.styles[1] ?? []
			for i in index..<nextTokenIdx {
				for style in styles {
					tokens[i].characterStyles.append(style)
				}
			}
		}

		var metadataString : String = ""
		for i in metadataIndex..<closeTokenIdx {
			if tokens[i].type == .string {
				metadataString.append(tokens[i].outputString)
				tokens[i].isMetadata = true
			}
		}
		
		for i in index..<metadataIndex {
			if tokens[i].type == .string {
				tokens[i].metadataString = metadataString
			}
		}
		
		tokens[closeTokenIdx].isProcessed = true
		tokens[metadataIndex].isProcessed = true
		tokens[index].isProcessed = true
	}
	
	
	func applyStyles( to tokens : [Token], usingRule rule : CharacterRule ) -> [Token] {
		var mutableTokens : [Token] = tokens
		
		os_log("Applying styles to tokens: %@", log: .tokenising, type: .info,  tokens.oslogDisplay )
		for idx in 0..<mutableTokens.count {
			let token = mutableTokens[idx]
			switch token.type {
			case .escape:
				os_log("Found escape: %@", log: .tokenising, type: .info, token.inputString )
			case .repeatingTag:
				let theToken = mutableTokens[idx]
				os_log("Found repeating tag with tag count: %i, tags: %@, current rule open tag: %@", log: .tokenising, type: .info, theToken.count, theToken.inputString, rule.openTag )
				
				guard theToken.count > 0 else {
					continue
				}
				
				let startIdx = idx
				var endIdx : Int? = nil
				
				if let nextTokenIdx = mutableTokens.firstIndex(where: { $0.inputString == theToken.inputString && $0.type == theToken.type && $0.count == theToken.count && $0.id != theToken.id }) {
					endIdx = nextTokenIdx
				}
				guard let existentEnd = endIdx else {
					continue
				}
				
				let styles : [CharacterStyling] = rule.styles[theToken.count] ?? []
				for i in startIdx..<existentEnd {
					for style in styles {
						mutableTokens[i].characterStyles.append(style)
					}
					if rule.cancels == .allRemaining {
						mutableTokens[i].shouldSkip = true
					}
				}
				mutableTokens[idx].count = 0
				mutableTokens[existentEnd].count = 0
			case .openTag:
				let theToken = mutableTokens[idx]
				os_log("Found repeating tag with tags: %@, current rule open tag: %@", log: .tokenising, type: .info, theToken.inputString, rule.openTag )
								
				guard rule.closingTag != nil else {
					
					// If there's an intermediate tag, get the index of that
					
					// Get the index of the closing tag
					
					continue
				}
				self.handleClosingTagFromOpenTag(withIndex: idx, in: &mutableTokens, following: rule)
				
				
			case .intermediateTag:
				let theToken = mutableTokens[idx]
				os_log("Found intermediate tag with tag count: %i, tags: %@", log: .tokenising, type: .info, theToken.count, theToken.inputString )
				
			case .closeTag:
				let theToken = mutableTokens[idx]
				os_log("Found close tag with tag count: %i, tags: %@", log: .tokenising, type: .info, theToken.count, theToken.inputString )
				
			case .string:
				let theToken = mutableTokens[idx]
				if theToken.isMetadata {
					os_log("Found Metadata: %@", log: .tokenising, type: .info, theToken.inputString )
				} else {
					os_log("Found String: %@", log: .tokenising, type: .info, theToken.inputString )
				}
				
				if let hasMetadata = theToken.metadataString {
					os_log("...with metadata: %@", log: .tokenising, type: .info, hasMetadata )
				}
			case .replacement:
				os_log("Found replacement with ID: %@", log: .tokenising, type: .info, mutableTokens[idx].inputString )
			}
		}
		return mutableTokens
	}
	
	
	func scan( _ string : String, with rule : CharacterRule) -> [Token] {
		let scanner = Scanner(string: string)
		scanner.charactersToBeSkipped = nil
		var tokens : [Token] = []
		var set = CharacterSet(charactersIn: "\(rule.openTag)\(rule.intermediateTag ?? "")\(rule.closingTag ?? "")")
		if let existentEscape = rule.escapeCharacter {
			set.insert(charactersIn: String(existentEscape))
		}
		
		var openTagFound = false
		var openingString = ""
		while !scanner.isAtEnd {
			
			if #available(iOS 13.0, OSX 10.15, watchOS 6.0, tvOS 13.0, *) {
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
			if #available(iOS 13.0, OSX 10.15, watchOS 6.0, tvOS 13.0, *) {
				lastChar = ( scanner.currentIndex > string.startIndex ) ? String(string[string.index(before: scanner.currentIndex)..<scanner.currentIndex]) : nil
			} else {
				let scanLocation = string.index(string.startIndex, offsetBy: scanner.scanLocation)
				lastChar = ( scanLocation > string.startIndex ) ? String(string[string.index(before: scanLocation)..<scanLocation]) : nil
			}
			let maybeFoundChars : String?
			if #available(iOS 13.0, OSX 10.15, watchOS 6.0, tvOS 13.0, *) {
				maybeFoundChars = scanner.scanCharacters(from: set )
			} else {
				var string : NSString?
				scanner.scanCharacters(from: set, into: &string)
				maybeFoundChars = string as String?
			}
			
			let nextChar : String?
			if #available(iOS 13.0, OSX 10.15,  watchOS 6.0,tvOS 13.0, *) {
				 nextChar = (scanner.currentIndex != string.endIndex) ? String(string[scanner.currentIndex]) : nil
			} else {
				let scanLocation = string.index(string.startIndex, offsetBy: scanner.scanLocation)
				nextChar = (scanLocation != string.endIndex) ? String(string[scanLocation]) : nil
			}
			
			guard let foundChars = maybeFoundChars else {
				tokens.append(Token(type: .string, inputString: "\(openingString)"))
				openingString = ""
				continue
			}
			
			if !validateSpacing(nextCharacter: nextChar, previousCharacter: lastChar, with: rule) {
				let escapeString = String("\(rule.escapeCharacter ?? Character(""))")
				var escaped = foundChars.replacingOccurrences(of: "\(escapeString)\(rule.openTag)", with: rule.openTag)
				if let hasIntermediateTag = rule.intermediateTag {
					escaped = foundChars.replacingOccurrences(of: "\(escapeString)\(hasIntermediateTag)", with: hasIntermediateTag)
				}
				if let existentClosingTag = rule.closingTag {
					escaped = foundChars.replacingOccurrences(of: "\(escapeString)\(existentClosingTag)", with: existentClosingTag)
				}
				
				openingString.append(escaped)
				continue
			}

			var cumulativeString = ""
			var openString = ""
			var intermediateString = ""
			var closedString = ""
			var maybeEscapeNext = false
			
			
			func addToken( for type : TokenType ) {
				var inputString : String
				switch type {
				case .openTag:
					inputString = openString
				case .intermediateTag:
					inputString = intermediateString
				case .closeTag:
					inputString = closedString
				default:
					inputString = ""
				}
				guard !inputString.isEmpty else {
					return
				}
				if !openingString.isEmpty {
					tokens.append(Token(type: .string, inputString: "\(openingString)"))
					openingString = ""
				}
				let actualType : TokenType = ( rule.intermediateTag == nil && rule.closingTag == nil ) ? .repeatingTag : type
				
				var token = Token(type: actualType, inputString: inputString)
				if rule.closingTag == nil {
					token.count = inputString.count
				}
				
				tokens.append(token)
				
				switch type {
				case .openTag:
					openString = ""
				case .intermediateTag:
					intermediateString = ""
				case .closeTag:
					closedString = ""
				default:
					break
				}
			}
			
			// Here I am going through and adding the characters in the found set to a cumulative string.
			// If there is an escape character, then the loop stops and any open tags are tokenised.
			for char in foundChars {
				cumulativeString.append(char)
				if maybeEscapeNext {
					
					var escaped = cumulativeString
					if String(char) == rule.openTag || String(char) == rule.intermediateTag || String(char) == rule.closingTag {
						escaped = String(cumulativeString.replacingOccurrences(of: String(rule.escapeCharacter ?? Character("")), with: ""))
					}
					
					openingString.append(escaped)
					cumulativeString = ""
					maybeEscapeNext = false
				}
				if let existentEscape = rule.escapeCharacter {
					if cumulativeString == String(existentEscape) {
						maybeEscapeNext = true
						addToken(for: .openTag)
						addToken(for: .intermediateTag)
						addToken(for: .closeTag)
						continue
					}
				}
				
				
				if cumulativeString == rule.openTag {
					openString.append(char)
					cumulativeString = ""
					openTagFound = true
				} else if cumulativeString == rule.intermediateTag, openTagFound {
					intermediateString.append(cumulativeString)
					cumulativeString = ""
				} else if cumulativeString == rule.closingTag, openTagFound {
					closedString.append(char)
					cumulativeString = ""
					openTagFound = false
				}
			}
			// If we're here, it means that an escape character was found but without a corresponding
			// tag, which means it might belong to a different rule.
			// It should be added to the next group of regular characters
			
			addToken(for: .openTag)
			addToken(for: .intermediateTag)
			addToken(for: .closeTag)
			openingString.append( cumulativeString )
		}
		
		if !openingString.isEmpty {
			tokens.append(Token(type: .string, inputString: "\(openingString)"))
		}
		
		return tokens
	}
	
	func validateSpacing( nextCharacter : String?, previousCharacter : String?, with rule : CharacterRule ) -> Bool {
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
