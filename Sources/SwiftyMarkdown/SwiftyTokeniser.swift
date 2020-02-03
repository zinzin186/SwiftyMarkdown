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
	static let performance = OSLog(subsystem: subsystem, category: "Peformance")
}

// Tag definition
public protocol CharacterStyling {
	func isEqualTo( _ other : CharacterStyling ) -> Bool
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
	public var minTags : Int = 1
	public var maxTags : Int = 1
	public var spacesAllowed : SpaceAllowed = .oneSide
	public var cancels : Cancel = .none
	
	public var tagVarieties : [Int : String]
	
	public var description: String {
		return "Character Rule with Open tag: \(self.openTag) and current styles : \(self.styles) "
	}
	
	public init(openTag: String, intermediateTag: String? = nil, closingTag: String? = nil, escapeCharacter: Character? = nil, styles: [Int : [CharacterStyling]] = [:], minTags : Int = 1, maxTags : Int = 1, cancels : Cancel = .none) {
		self.openTag = openTag
		self.intermediateTag = intermediateTag
		self.closingTag = closingTag
		self.escapeCharacter = escapeCharacter
		self.styles = styles
		self.minTags = minTags
		self.maxTags = maxTags
		self.cancels = cancels
		
		self.tagVarieties = [:]
		for i in minTags...maxTags {
			self.tagVarieties[i] = openTag.repeating(i)
		}
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
	public fileprivate(set) var group : Int = 0
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
				if count <= 0 {
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
		if type == .repeatingTag {
			self.count = inputString.count
		}
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

enum TagState {
	case none
	case open
	case intermediate
	case closed
}

struct TagString {
	var state : TagState = .none
	var preOpenString = ""
	var openTagString : [String] = []
	var intermediateString = ""
	var intermediateTagString = ""
	var metadataString = ""
	var closedTagString : [String] = []
	var postClosedString = ""
	
	let rule : CharacterRule
	var tokenGroup = 0
	
	init( with rule : CharacterRule ) {
		self.rule = rule
	}
	
	mutating func append( _ string : String? ) {
		guard let existentString = string else {
			return
		}
		switch self.state {
		case .none:
			self.preOpenString += existentString
		case .open:
			self.intermediateString += existentString
		case .intermediate:
			self.metadataString += existentString
		case .closed:
			self.postClosedString += existentString
		}
	}
	
	mutating func handleRepeatingTags( _ tokenGroup : [TokenGroup] ) {
		var availableCount = self.rule.maxTags
		var sameOpenGroup = false
		for token in tokenGroup {
			
			switch token.state {
			case .none:
				self.append(token.string)
				if self.state == .closed {
					self.state = .none
				}
			case .open:
				switch self.state {
				case .none:
					self.openTagString.append(token.string)
					self.state = .open
					availableCount = self.rule.maxTags - token.string.count
					sameOpenGroup = true
				case .open:
					if availableCount > 0 {
						if sameOpenGroup {
							self.openTagString.append(token.string)
							availableCount = self.rule.maxTags - token.string.count
						} else {
							self.closedTagString.append(token.string)
							self.state = .closed
						}
					} else {
						self.append(token.string)
					}

				case .intermediate:
					self.preOpenString += self.openTagString.joined() + token.string
				case .closed:
					self.append(token.string)
				}
			case .intermediate:
				switch self.state {
				case .none:
					self.preOpenString += token.string
				case .open:
					self.intermediateTagString += token.string
					self.state = .intermediate
				case .intermediate:
					self.metadataString += token.string
				case .closed:
					self.postClosedString += token.string
				}
				
			case .closed:
				switch self.state {
				case .intermediate:
					self.closedTagString.append(token.string)
					self.state = .closed
				case .closed:
					self.postClosedString += token.string
				case .open:
					if self.rule.intermediateTag == nil {
						self.closedTagString.append(token.string)
						self.state = .closed
					} else {
						self.preOpenString += self.openTagString.joined()
						self.preOpenString += self.intermediateString
						self.preOpenString += token.string
						self.intermediateString = ""
						self.openTagString.removeAll()
					}
				case .none:
					self.preOpenString += token.string
				}
			}
		}
		if !self.openTagString.isEmpty && self.rule.closingTag == nil && self.state != .closed {
			self.state = .open
		}
	}
	
	mutating func handleRegularTags( _ tokenGroup : [TokenGroup] ) {
		for token in tokenGroup {
			
			switch token.state {
			case .none:
				self.append(token.string)
				if self.state == .closed {
					self.state = .none
				}
			case .open:
				switch self.state {
				case .none:
					self.openTagString.append(token.string)
					self.state = .open
				case .open:
					if self.rule.maxTags == 1, self.openTagString.first == rule.openTag {
						self.preOpenString = self.preOpenString + self.openTagString.joined() + self.intermediateString
						self.intermediateString = ""
						self.openTagString.removeAll()
						self.openTagString.append(token.string)
					} else {
						self.openTagString.append(token.string)
					}
				case .intermediate:
					self.preOpenString += self.openTagString.joined() + token.string
				case .closed:
					self.openTagString.append(token.string)
				}
			case .intermediate:
				switch self.state {
				case .none:
					self.preOpenString += token.string
				case .open:
					self.intermediateTagString += token.string
					self.state = .intermediate
				case .intermediate:
					self.metadataString += token.string
				case .closed:
					self.postClosedString += token.string
				}
				
			case .closed:
				switch self.state {
				case .intermediate:
					self.closedTagString.append(token.string)
					self.state = .closed
				case .closed:
					self.postClosedString += token.string
				case .open:
					if self.rule.intermediateTag == nil {
						self.closedTagString.append(token.string)
						self.state = .closed
					} else {
						self.preOpenString += self.openTagString.joined()
						self.preOpenString += self.intermediateString
						self.preOpenString += token.string
						self.intermediateString = ""
						self.openTagString.removeAll()
					}
				case .none:
					self.preOpenString += token.string
				}
			}
		}
		
	}
	
	mutating func append( contentsOf tokenGroup: [TokenGroup] ) {
		if self.rule.closingTag == nil {
			self.handleRepeatingTags(tokenGroup)
		} else {
			self.handleRegularTags(tokenGroup)
		}
	}
	
	func configureToken(ofType type : TokenType = .string, with string : String ) -> Token {
		var token = Token(type: type, inputString: string)
		token.group = self.tokenGroup
		return token
	}
	
	mutating func reset() {
		self.preOpenString = ""
		self.openTagString.removeAll()
		self.intermediateString = ""
		self.intermediateTagString = ""
		self.metadataString = ""
		self.closedTagString.removeAll()
		self.postClosedString = ""
		
		self.state = .none
	}
	
	mutating func consolidate(with string : String, into tokens : inout [Token]) -> [Token] {
		self.reset()
		guard !string.isEmpty else {
			return tokens
		}
		tokens.append(self.configureToken(with: string))
		return tokens
	}
	
	mutating func tokens(beginningGroupNumberAt group : Int = 0) -> [Token] {
		self.tokenGroup = group
		var tokens : [Token] = []
		
		if self.intermediateString.isEmpty && self.intermediateTagString.isEmpty && self.metadataString.isEmpty {
			let actualString = self.preOpenString + self.openTagString.joined() + self.closedTagString.joined() + self.postClosedString
			return self.consolidate(with: actualString, into: &tokens)
		}
		if self.state == .open && !self.openTagString.isEmpty {
			let actualString = self.preOpenString + self.openTagString.joined() + self.intermediateString
			return self.consolidate(with: actualString, into: &tokens)
		}
		
		if !self.preOpenString.isEmpty {
			tokens.append(self.configureToken(with: self.preOpenString))
		}
		
		for tag in self.openTagString {
			if self.rule.closingTag == nil {
				tokens.append(self.configureToken(ofType: .repeatingTag, with: tag))
			} else {
				tokens.append(self.configureToken(ofType: .openTag, with: tag))
			}
		}
		self.tokenGroup += 1
		if !self.intermediateString.isEmpty {
			var token = self.configureToken(with: self.intermediateString)
			token.metadataString = (self.metadataString.isEmpty) ? nil : self.metadataString
			tokens.append(token)
		}
		if !self.intermediateTagString.isEmpty {
			tokens.append(self.configureToken(ofType: .intermediateTag, with: self.intermediateTagString))
		}
		
		self.tokenGroup += 1
		
		if !self.metadataString.isEmpty {
			tokens.append(self.configureToken(with: self.metadataString))
		}
		var remainingTags = ( self.rule.closingTag == nil ) ? self.openTagString.joined() : ""
		for tag in self.closedTagString {
			if self.rule.closingTag == nil {
				remainingTags = remainingTags.replacingOccurrences(of: tag, with: "")
				tokens.append(self.configureToken(ofType: .repeatingTag, with: tag))
			} else {
				tokens.append(self.configureToken(ofType: .closeTag, with: tag))
			}
		}
		if !self.postClosedString.isEmpty {
			tokens.append(self.configureToken(with: self.postClosedString))
		}
		
		self.reset()
		
		if !remainingTags.isEmpty {
			self.state = .open
		}
		
		return tokens
	}
}

struct TokenGroup {
	enum TokenGroupType {
		case string
		case tag
		case escape
	}
	
	let string : String
	let isEscaped : Bool
	let type : TokenGroupType
	var state : TagState = .none
}

public class SwiftyTokeniser {
	let rules : [CharacterRule]
	var replacements : [String : [Token]] = [:]
	
	var currentRunTime : TimeInterval = 0
	var totalTime : TimeInterval = 0
	var enableLog = (ProcessInfo.processInfo.environment["SwiftyTokeniserLogging"] != nil)
	var enablePerformanceLog = (ProcessInfo.processInfo.environment["SwiftyTokeniserPerformanceLogging"] != nil)
	
	public init( with rules : [CharacterRule] ) {
		self.rules = rules
		if enablePerformanceLog {
			self.totalTime = Date.timeIntervalSinceReferenceDate
			os_log("--- TIMER: Tokeniser initialised", log: .performance, type: .info)
		}

	}
	
	deinit {
		if enablePerformanceLog {
			os_log("--- TIMER (Tokeniser deinitialised): %f", log: .performance, type: .info, Date.timeIntervalSinceReferenceDate - self.totalTime)
		}
	}
	
	
	/// This goes through every CharacterRule in order and applies it to the input string, tokenising the string
	/// if there are any matches.
	///
	/// The for loop in the while loop (yeah, I know) is there to separate strings from within tags to
	/// those outside them.
	///
	/// e.g. "A string with a \[link\]\(url\) tag" would have the "link" text tokenised separately.
	///
	/// This is to prevent situations like **\[link**\](url) from returing a bold string.
	///
	/// - Parameter inputString: A string to have the CharacterRules in `self.rules` applied to
	public func process( _ inputString : String ) -> [Token] {
		guard rules.count > 0 else {
			return [Token(type: .string, inputString: inputString)]
		}
		
		var currentTokens : [Token] = []
		var mutableRules = self.rules
		
		self.totalTime = Date().timeIntervalSinceReferenceDate
		
		if enablePerformanceLog {
			self.currentRunTime = Date().timeIntervalSinceReferenceDate
			os_log("TIMER (total run time): %f", log: .performance, type: .info, Date().timeIntervalSinceReferenceDate - self.totalTime)
		}
		
		while !mutableRules.isEmpty {
			let nextRule = mutableRules.removeFirst()
			
			if enableLog {
				os_log("------------------------------", log: .tokenising, type: .info)
				os_log("RULE: %@", log: OSLog.tokenising, type:.info , nextRule.description)
			}
			if enablePerformanceLog {
				os_log("TIMER (start rule %@): %f", log: .performance, type: .info, nextRule.openTag, Date().timeIntervalSinceReferenceDate - self.currentRunTime)
			}

			
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
					if enableLog {
						os_log("Found replacement for %@", log: .tokenising, type: .info, token.inputString)
					}
					
					for var repToken in hasReplacement {
						guard repToken.type == .string else {
							finalTokens.append(repToken)
							continue
						}
						for style in token.characterStyles {
							if !repToken.characterStyles.contains(where: { $0.isEqualTo(style)}) {
								repToken.characterStyles.append(contentsOf: token.characterStyles)
							}
						}
						
						finalTokens.append(repToken)
					}
				}
			}
			currentTokens = finalTokens
			
			// Each string could have additional tokens within it, so they have to be scanned as well with the current rule.
			// The one string token might then be exploded into multiple more tokens
		}
		
		if enablePerformanceLog {
			os_log("TIMER (finished all rules): %f", log: .performance, type: .info, Date().timeIntervalSinceReferenceDate - self.currentRunTime)
		}
		
		if enableLog {
			os_log("=====RULE PROCESSING COMPLETE=====", log: .tokenising, type: .info)
			os_log("==================================", log: .tokenising, type: .info)
		}
		
		return currentTokens
	}
	
	
	
	/// In order to reinsert the original replacements into the new string token, the replacements
	/// need to be searched for in the incoming string one by one.
	///
	/// Using the `newToken(fromSubstring:isReplacement:)` function ensures that any metadata and character styles
	/// are passed over into the newly created tokens.
	///
	/// E.g. A string token that has an `outputString` of "This string AAAAA-BBBBB-CCCCC replacements", with
	/// a characterStyle of `bold` for the entire string, needs to be separated into the following tokens:
	///
	/// - `string`: "This string "
	/// - `replacement`: "AAAAA-BBBBB-CCCCC"
	/// - `string`: " replacements"
	///
	/// Each of these need to have a character style of `bold`.
	///
	/// - Parameters:
	///   - replacements: An array of `replacement` tokens
	///   - token: The new `string` token that may contain replacement IDs contained in the `replacements` array
	func reinsertReplacements(_ replacements : [Token], from stringToken : Token ) -> [Token] {
		guard !stringToken.outputString.isEmpty && !replacements.isEmpty else {
			return [stringToken]
		}
		var outputTokens : [Token] = []
		let scanner = Scanner(string: stringToken.outputString)
		scanner.charactersToBeSkipped = nil
		
		// Remove any replacements that don't appear in the incoming string
		var repTokens = replacements.filter({ stringToken.outputString.contains($0.inputString) })
		
		var testString = "\n"
		while !scanner.isAtEnd {
			var outputString : String = ""
			if repTokens.count > 0 {
				testString = repTokens.removeFirst().inputString
			}
			
			if #available(iOS 13.0, OSX 10.15, watchOS 6.0, tvOS 13.0, *) {
				if let nextString = scanner.scanUpToString(testString) {
					outputString = nextString
					outputTokens.append(stringToken.newToken(fromSubstring: outputString, isReplacement: false))
					if let outputToken = scanner.scanString(testString) {
						outputTokens.append(stringToken.newToken(fromSubstring: outputToken, isReplacement: true))
					}
				} else if let outputToken = scanner.scanString(testString) {
					outputTokens.append(stringToken.newToken(fromSubstring: outputToken, isReplacement: true))
				}
			} else {
				var oldString : NSString? = nil
				var tokenString : NSString? = nil
				scanner.scanUpTo(testString, into: &oldString)
				if let nextString = oldString {
					outputString = nextString as String
					outputTokens.append(stringToken.newToken(fromSubstring: outputString, isReplacement: false))
					scanner.scanString(testString, into: &tokenString)
					if let outputToken = tokenString as String? {
						outputTokens.append(stringToken.newToken(fromSubstring: outputToken, isReplacement: true))
					}
				} else {
					scanner.scanString(testString, into: &tokenString)
					if let outputToken = tokenString as String? {
						outputTokens.append(stringToken.newToken(fromSubstring: outputToken, isReplacement: true))
					}
				}
			}
		}
		return outputTokens
	}
	
	
	/// This function is necessary because a previously tokenised string might have
	///
	/// Consider a previously tokenised string, where AAAAA-BBBBB-CCCCC represents a replaced \[link\](url) instance.
	///
	/// The incoming tokens will look like this:
	///
	/// - `string`: "A \*\*Bold"
	/// - `replacement` : "AAAAA-BBBBB-CCCCC"
	/// - `string`: " with a trailing string**"
	///
	///	However, because the scanner can only tokenise individual strings, passing in the string values
	///	of these tokens individually and applying the styles will not correctly detect the starting and
	///	ending `repeatingTag` instances. (e.g. the scanner will see "A \*\*Bold", and then "AAAAA-BBBBB-CCCCC",
	///	and finally " with a trailing string\*\*")
	///
	///	The strings need to be combined, so that they form a single string:
	///	A \*\*Bold AAAAA-BBBBB-CCCCC with a trailing string\*\*.
	///	This string is then parsed and tokenised so that it looks like this:
	///
	/// - `string`: "A "
	///	- `repeatingTag`: "\*\*"
	///	- `string`: "Bold AAAAA-BBBBB-CCCCC with a trailing string"
	///	- `repeatingTag`: "\*\*"
	///
	///	Finally, the replacements from the original incoming token array are searched for and pulled out
	///	of this new string, so the final result looks like this:
	///
	/// - `string`: "A "
	///	- `repeatingTag`: "\*\*"
	///	- `string`: "Bold "
	///	- `replacement`: "AAAAA-BBBBB-CCCCC"
	///	- `string`: " with a trailing string"
	///	- `repeatingTag`: "\*\*"
	///
	/// - Parameters:
	///   - tokens: The tokens to be combined, scanned, re-tokenised, and merged
	///   - rule: The character rule currently being applied
	func scanReplacementTokens( _ tokens : [Token], with rule : CharacterRule ) -> [Token] {
		guard tokens.count > 0 else {
			return []
		}
		
		let combinedString = tokens.map({ $0.outputString }).joined()
		
		let nextTokens = self.scan(combinedString, with: rule)
		var replacedTokens = self.applyStyles(to: nextTokens, usingRule: rule)
		
		/// It's necessary here to check to see if the first token (which will always represent the styles
		/// to be applied from previous scans) has any existing metadata or character styles and apply them
		/// to *all* the string and replacement tokens found by the new scan.
		for idx in 0..<replacedTokens.count {
			guard replacedTokens[idx].type == .string || replacedTokens[idx].type == .replacement else {
				continue
			}
			if tokens.first!.metadataString != nil && replacedTokens[idx].metadataString == nil {
				replacedTokens[idx].metadataString = tokens.first!.metadataString
			}
			replacedTokens[idx].characterStyles.append(contentsOf: tokens.first!.characterStyles)
		}
		
		// Swap the original replacement tokens back in
		let replacements = tokens.filter({ $0.type == .replacement })
		var outputTokens : [Token] = []
		for token in replacedTokens {
			guard token.type == .string else {
				outputTokens.append(token)
				continue
			}
			outputTokens.append(contentsOf: self.reinsertReplacements(replacements, from: token))
		}
		
		return outputTokens
	}
	
	
	
	/// This function ensures that only concurrent `string` and `replacement` tokens are processed together.
	///
	/// i.e. If there is an existing `repeatingTag` token between two strings, then those strings will be
	/// processed individually. This prevents incorrect parsing of strings like "\*\*\_Should only be bold\*\*\_"
	///
	/// - Parameters:
	///   - incomingTokens: A group of tokens whose string tokens and replacement tokens should be combined and re-tokenised
	///   - rule: The current rule being processed
	func handleReplacementTokens( _ incomingTokens : [Token], with rule : CharacterRule) -> [Token] {
		
		// Only combine string and replacements that are next to each other.
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
					if !tokens[i].characterStyles.contains(where: { $0.isEqualTo(style )}) {
						tokens[i].characterStyles.append(style)
					}
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
	
	
	/// This is here to manage how opening tags are matched with closing tags when they're all the same
	/// character.
	///
	/// Of course, because Markdown is about as loose as a spec can be while still being considered any
	/// kind of spec, the number of times this character repeats causes different effects. Then there
	/// is the ill-defined way it should work if the number of opening and closing tags are different.
	///
	/// - Parameters:
	///   - index: The index of the current token in the loop
	///   - tokens: An inout variable of the loop tokens of interest
	///   - rule: The character rule being applied
	func handleClosingTagFromRepeatingTag(withIndex index : Int, in tokens: inout [Token], following rule : CharacterRule) {
		let theToken = tokens[index]
		
		if enableLog {
			os_log("Found repeating tag with tag count: %i, tags: %@, current rule open tag: %@", log: .tokenising, type: .info, theToken.count, theToken.inputString, rule.openTag )
		}
		
		guard theToken.count > 0 else {
			return
		}
		
		let startIdx = index
		var endIdx : Int? = nil
		
		let maxCount = (theToken.count > rule.maxTags) ? rule.maxTags : theToken.count
		// Try to find exact match first
		if let nextTokenIdx = tokens.firstIndex(where: { $0.inputString.first == theToken.inputString.first && $0.type == theToken.type && $0.count == theToken.count && $0.id != theToken.id && !$0.isProcessed && $0.group != theToken.group }) {
			endIdx = nextTokenIdx
		}
		
		if endIdx == nil, let nextTokenIdx = tokens.firstIndex(where: { $0.inputString.first == theToken.inputString.first && $0.type == theToken.type && $0.count >= 1 && $0.id != theToken.id  && !$0.isProcessed }) {
			endIdx = nextTokenIdx
		}
		guard let existentEnd = endIdx else {
			return
		}
		
		
		let styles : [CharacterStyling] = rule.styles[maxCount] ?? []
		for i in startIdx..<existentEnd {
			for style in styles {
				if !tokens[i].characterStyles.contains(where: { $0.isEqualTo(style )}) {
					tokens[i].characterStyles.append(style)
				}
			}
			if rule.cancels == .allRemaining {
				tokens[i].shouldSkip = true
			}
		}
		
		let maxEnd = (tokens[existentEnd].count > rule.maxTags) ? rule.maxTags : tokens[existentEnd].count
		tokens[index].count = theToken.count - maxEnd
		tokens[existentEnd].count = tokens[existentEnd].count - maxEnd
		if maxEnd < rule.maxTags {
			self.handleClosingTagFromRepeatingTag(withIndex: index, in: &tokens, following: rule)
		} else {
			tokens[existentEnd].isProcessed = true
			tokens[index].isProcessed = true
		}
		
		
	}
	
	func applyStyles( to tokens : [Token], usingRule rule : CharacterRule ) -> [Token] {
		var mutableTokens : [Token] = tokens
		
		if enableLog {
			os_log("Applying styles to tokens: %@", log: .tokenising, type: .info,  tokens.oslogDisplay )
		}
		for idx in 0..<mutableTokens.count {
			let token = mutableTokens[idx]
			switch token.type {
			case .escape:
				if enableLog {
					os_log("Found escape: %@", log: .tokenising, type: .info, token.inputString )
				}
			case .repeatingTag:
				let theToken = mutableTokens[idx]
				self.handleClosingTagFromRepeatingTag(withIndex: idx, in: &mutableTokens, following: rule)
				if enableLog {
					os_log("Found repeating tag with tags: %@, current rule open tag: %@", log: .tokenising, type: .info, theToken.inputString, rule.openTag )
				}
			case .openTag:
				let theToken = mutableTokens[idx]
				if enableLog {
					os_log("Found open tag with tags: %@, current rule open tag: %@", log: .tokenising, type: .info, theToken.inputString, rule.openTag )
				}
				
				guard rule.closingTag != nil else {
					
					// If there's an intermediate tag, get the index of that
					
					// Get the index of the closing tag
					
					continue
				}
				self.handleClosingTagFromOpenTag(withIndex: idx, in: &mutableTokens, following: rule)
				
				
			case .intermediateTag:
				let theToken = mutableTokens[idx]
				if enableLog {
					os_log("Found intermediate tag with tag count: %i, tags: %@", log: .tokenising, type: .info, theToken.count, theToken.inputString )
				}
				
			case .closeTag:
				let theToken = mutableTokens[idx]
				if enableLog {
					os_log("Found close tag with tag count: %i, tags: %@", log: .tokenising, type: .info, theToken.count, theToken.inputString )
				}
				
			case .string:
				let theToken = mutableTokens[idx]
				if enableLog {
					if theToken.isMetadata {
						os_log("Found Metadata: %@", log: .tokenising, type: .info, theToken.inputString )
					} else {
						os_log("Found String: %@", log: .tokenising, type: .info, theToken.inputString )
					}
					if let hasMetadata = theToken.metadataString {
						os_log("...with metadata: %@", log: .tokenising, type: .info, hasMetadata )
					}
				}
				
			case .replacement:
				if enableLog {
					os_log("Found replacement with ID: %@", log: .tokenising, type: .info, mutableTokens[idx].inputString )
				}
			}
		}
		return mutableTokens
	}
	
	
	func scanSpacing( _ scanner : Scanner, usingCharactersIn set : CharacterSet ) -> (preTag : String?, foundChars : String?, postTag : String?) {
		if enablePerformanceLog {
			os_log("TIMER (scan space)  : %f", log: .performance, type: .info, Date().timeIntervalSinceReferenceDate - self.currentRunTime)
		}
		let lastChar : String?
		if #available(iOS 13.0, OSX 10.15, watchOS 6.0, tvOS 13.0, *) {
			lastChar = ( scanner.currentIndex > scanner.string.startIndex ) ? String(scanner.string[scanner.string.index(before: scanner.currentIndex)..<scanner.currentIndex]) : nil
		} else {
			if let scanLocation = scanner.string.index(scanner.string.startIndex, offsetBy: scanner.scanLocation, limitedBy: scanner.string.endIndex) {
				lastChar = ( scanLocation > scanner.string.startIndex ) ? String(scanner.string[scanner.string.index(before: scanLocation)..<scanLocation]) : nil
			} else {
				lastChar = nil
			}
			
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
			nextChar = (scanner.currentIndex != scanner.string.endIndex) ? String(scanner.string[scanner.currentIndex]) : nil
		} else {
			if let scanLocation = scanner.string.index(scanner.string.startIndex, offsetBy: scanner.scanLocation, limitedBy: scanner.string.endIndex) {
				nextChar = (scanLocation != scanner.string.endIndex) ? String(scanner.string[scanLocation]) : nil
			} else {
				nextChar = nil
			}
		}
		if enablePerformanceLog {
			os_log("TIMER (end space)   : %f", log: .performance, type: .info, Date().timeIntervalSinceReferenceDate - self.currentRunTime)
		}
		
		return (lastChar, maybeFoundChars, nextChar)
	}
	
	func getTokenGroups( for string : inout String, with rule : CharacterRule, shouldEmpty : Bool = false ) -> [TokenGroup] {
		if string.isEmpty {
			return []
		}
		var groups : [TokenGroup] 	= []
		
		if string.contains(rule.openTag) {
			if shouldEmpty || string == rule.tagVarieties[rule.maxTags]{
				var token = TokenGroup(string: string, isEscaped: false, type: .tag)
				token.state = .open
				groups.append(token)
				string.removeAll()
			}
			
		} else if let intermediateString = rule.intermediateTag, string.contains(intermediateString)  {
			
			if let range = string.range(of: intermediateString) {
				let prior = string[string.startIndex..<range.lowerBound]
				let tag = string[range]
				let following = string[range.upperBound..<string.endIndex]
				if !prior.isEmpty {
					groups.append(TokenGroup(string: String(prior), isEscaped: false, type: .string))
				}
				var token = TokenGroup(string: String(tag), isEscaped: false, type: .tag)
				token.state = .intermediate
				groups.append(token)
				if !following.isEmpty {
					groups.append(TokenGroup(string: String(following), isEscaped: false, type: .string))
				}
				string.removeAll()
			}
		} else if let closingTag = rule.closingTag, closingTag.contains(string) {
			var token = TokenGroup(string: string, isEscaped: false, type: .tag)
			token.state = .closed
			groups.append(token)
			string.removeAll()
		}
		
		if shouldEmpty && !string.isEmpty {
			let token = TokenGroup(string: string, isEscaped: false, type: .tag)
			groups.append(token)
			string.removeAll()
		}
		return groups
	}
	
	func scan( _ string : String, with rule : CharacterRule) -> [Token] {
		
		
		let scanner = Scanner(string: string)
		scanner.charactersToBeSkipped = nil
		var tokens : [Token] = []
		var set = CharacterSet(charactersIn: "\(rule.openTag)\(rule.intermediateTag ?? "")\(rule.closingTag ?? "")")
		if let existentEscape = rule.escapeCharacter {
			set.insert(charactersIn: String(existentEscape))
		}

		var tagString = TagString(with: rule)
		var tokenGroup = 0
		
		if enablePerformanceLog {
			os_log("TIMER (start scan %@): %f (string: %@)", log: .performance, type: .info, rule.openTag, Date().timeIntervalSinceReferenceDate - self.currentRunTime, string)
		}
		
		if !string.contains( rule.openTag ) {
			return [Token(type: .string, inputString: string)]
		}
		
		while !scanner.isAtEnd {
			if enablePerformanceLog {
				os_log("TIMER (loop start %@): %f", log: .performance, type: .info, rule.openTag, Date().timeIntervalSinceReferenceDate - self.currentRunTime)
			}
			tokenGroup += 1
			if #available(iOS 13.0, OSX 10.15, watchOS 6.0, tvOS 13.0, *) {
				if let start = scanner.scanUpToCharacters(from: set) {
					if enablePerformanceLog {
						os_log("TIMER (first chars)  : %f", log: .performance, type: .info, Date().timeIntervalSinceReferenceDate - self.currentRunTime)
					}
					tagString.append(start)
				}
			} else {
				var string : NSString?
				scanner.scanUpToCharacters(from: set, into: &string)
				if let existentString = string as String? {
					tagString.append(existentString)
				}
			}
			
			// The end of the string
			let spacing = self.scanSpacing(scanner, usingCharactersIn: set)
			guard let foundTag = spacing.foundChars else {
				continue
			}
			
			if foundTag == rule.openTag && foundTag.count < rule.minTags {
				tagString.append(foundTag)
				continue
			}
			
			if !validateSpacing(nextCharacter: spacing.postTag, previousCharacter: spacing.preTag, with: rule) {
				let escapeString = String("\(rule.escapeCharacter ?? Character(""))")
				var escaped = foundTag.replacingOccurrences(of: "\(escapeString)\(rule.openTag)", with: rule.openTag)
				if let hasIntermediateTag = rule.intermediateTag {
					escaped = foundTag.replacingOccurrences(of: "\(escapeString)\(hasIntermediateTag)", with: hasIntermediateTag)
				}
				if let existentClosingTag = rule.closingTag {
					escaped = foundTag.replacingOccurrences(of: "\(escapeString)\(existentClosingTag)", with: existentClosingTag)
				}
				tagString.append(escaped)
				continue
			}
			
			
			if enablePerformanceLog {
				os_log("TIMER (found tag %@) : %f", log: .performance, type: .info, rule.openTag, Date().timeIntervalSinceReferenceDate - self.currentRunTime)
			}
			
			if !foundTag.contains(rule.openTag) && !foundTag.contains(rule.intermediateTag ?? "") && !foundTag.contains(rule.closingTag ?? "") {
				tagString.append(foundTag)
				continue
			}
			
			
			var tokenGroups : [TokenGroup] = []
			var escapeCharacter : Character? = nil
			var cumulatedString = ""
			for char in foundTag {
				if let existentEscapeCharacter = escapeCharacter {
					
					// If any of the tags feature the current character
					let escape = String(existentEscapeCharacter)
					let nextTagCharacter = String(char)
					if rule.openTag.contains(nextTagCharacter) || rule.intermediateTag?.contains(nextTagCharacter) ?? false || rule.closingTag?.contains(nextTagCharacter) ?? false {
						tokenGroups.append(TokenGroup(string: nextTagCharacter, isEscaped: true, type: .tag))
						escapeCharacter = nil
					} else if nextTagCharacter == escape {
						// Doesn't apply to this rule
						tokenGroups.append(TokenGroup(string: nextTagCharacter, isEscaped: false, type: .escape))
					}
					
					continue
				}
				if let existentEscape = rule.escapeCharacter {
					if char == existentEscape {
						tokenGroups.append(contentsOf: getTokenGroups(for: &cumulatedString, with: rule, shouldEmpty: true))
						escapeCharacter = char
						continue
					}
				}
				cumulatedString.append(char)
				tokenGroups.append(contentsOf: getTokenGroups(for: &cumulatedString, with: rule))
				
			}
			if let remainingEscape = escapeCharacter {
				tokenGroups.append(TokenGroup(string: String(remainingEscape), isEscaped: false, type: .escape))
			}
			
			tokenGroups.append(contentsOf: getTokenGroups(for: &cumulatedString, with: rule, shouldEmpty: true))
			tagString.append(contentsOf: tokenGroups)
			
			if tagString.state == .closed {
				tokens.append(contentsOf: tagString.tokens(beginningGroupNumberAt : tokenGroup))
			}
		}
		
		tokens.append(contentsOf: tagString.tokens(beginningGroupNumberAt : tokenGroup))
		if enablePerformanceLog {
			os_log("TIMER (end scan %@)  : %f", log: .performance, type: .info, rule.openTag, Date().timeIntervalSinceReferenceDate - self.currentRunTime)
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


extension String {
	func repeating( _ max : Int ) -> String {
		var output = self
		for _ in 1..<max {
			output += self
		}
		return output
	}
}
