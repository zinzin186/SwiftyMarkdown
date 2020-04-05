//
//  File.swift
//  
//
//  Created by Simon Fairbairn on 04/04/2020.
//

//
//  SwiftyScanner.swift
//  SwiftyMarkdown
//
//  Created by Simon Fairbairn on 04/02/2020.
//

import Foundation
import os.log

class SwiftyScannerNonRepeating : SwiftyScanning {
	var state : TagState = .none
	var preOpenString = ""
	var openTagString : [String] = []
	var intermediateString = ""
	var intermediateTagString = ""
	var metadataString = ""
	var closedTagString : [String] = []
	var postClosedString = ""
	
	
	var tokenGroup = 0
	
	

	
	func append( _ string : String? ) {
		guard let existentString = string else {
			return
		}
		self.stringList.append(existentString)
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
	
	func handleRegularTags( _ tokenGroup : [TokenGroup] ) {
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
	
	func append( contentsOf tokenGroup: [TokenGroup] ) {
		self.handleRegularTags(tokenGroup)
	}
	
	func configureToken(ofType type : TokenType = .string, with string : String ) -> Token {
		var token = Token(type: type, inputString: string)
		token.group = self.tokenGroup
		return token
	}
	
	func reset() {
		self.preOpenString = ""
		self.openTagString.removeAll()
		self.intermediateString = ""
		self.intermediateTagString = ""
		self.metadataString = ""
		self.closedTagString.removeAll()
		self.postClosedString = ""
		
		self.state = .none
	}
	
	func consolidate(with string : String, into tokens : inout [Token]) -> [Token] {
		self.reset()
		guard !string.isEmpty else {
			return tokens
		}
		tokens.append(self.configureToken(with: string))
		return tokens
	}
	
	func tokens(beginningGroupNumberAt group : Int = 0) -> [Token] {
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
			if self.rule.isRepeatingTag {
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
			var token = Token(type: .string, inputString: self.metadataString)
			token.group = self.tokenGroup
			tokens.append(token)
		}
		var remainingTags = ( self.rule.closingTag == nil ) ? self.openTagString.joined() : ""
		for tag in self.closedTagString {
			if self.rule.isRepeatingTag {
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
	
	
	
	func groups( inString string : inout String, forTag tag : String, state : TagState ) -> [TokenGroup] {
		var groups : [TokenGroup] = []
		
		var stringList : [String] = []
		
		while string.range(of: tag) != nil {
			guard let range = string.range(of: tag) else {
				break
			}
			let beforeTag = String(string[string.startIndex..<range.lowerBound])
			if !beforeTag.isEmpty {
				stringList.append(beforeTag)
			}
			let tag = string[range]
			stringList.append(String(tag))
			string.removeSubrange(string.startIndex..<range.upperBound)
		}
		if !string.isEmpty {
			stringList.append(string)
			string.removeAll()
		}
		
		if state == .open {
			stringList = stringList.reversed()
		}
		var tagFound = false
		for item in stringList {
			if item == tag && !tagFound {
				var token = TokenGroup(string: item, isEscaped: false, type: .tag)
				token.state = state
				tagFound = true
				groups.append(token)
				continue
			}
			if item == rule.openTag && state == .closed {
				var token = TokenGroup(string: item, isEscaped: false, type: .tag)
				token.state = .open
				groups.append(token)
				self.state = .open
				continue
			}
			groups.append(TokenGroup(string: String(item), isEscaped: false, type: .string))
		}

		return (state == .open) ? groups.reversed() : groups
	}
	
	
	func getTokenGroups( for string : inout String, with rule : CharacterRule, shouldEmpty : Bool = false ) -> [TokenGroup] {
		if string.isEmpty {
			return []
		}
		var groups : [TokenGroup] 	= []
		
		if let closingTag = rule.closingTag, string.contains(closingTag) {
			groups.append(contentsOf: self.groups(inString: &string, forTag: closingTag, state: .closed))
		} else if let intermediateString = rule.intermediateTag, string.contains(intermediateString)  {
			groups.append(contentsOf: self.groups(inString: &string, forTag: intermediateString, state: .intermediate))
		} else if string.contains(rule.openTag) {
			groups.append(contentsOf: self.groups(inString: &string, forTag: rule.openTag, state: .open))
		}
		
		if shouldEmpty && !string.isEmpty {
			let token = TokenGroup(string: string, isEscaped: false, type: .tag)
			groups.append(token)
			string.removeAll()
		}
		return groups
	}
	
	
	
	
	var rule : CharacterRule! = nil
	var metadataLookup : [String : String] = [:]
	
	let performanceLog = PerformanceLog(with: "SwiftyScannerPerformanceLogging", identifier: "Swifty Scanner Non Repeating", log: .swiftyScannerPerformance)
		
	
	var openIndex : Int = -1
	var intermediateIndex : Int = -1
	var closedIndex : Int = -1
	
	var stringList : [String] = []
	
	init() { }
	
	func scanForTags(in string : String) -> [Token] {
		let scanner = Scanner(string: string)
		scanner.charactersToBeSkipped = nil
		let set = CharacterSet(charactersIn: "\(rule.openTag)\(rule.intermediateTag ?? "")\(rule.closingTag ?? "")\(String(rule.escapeCharacter ?? Character.init("") ))")

		var tokens : [Token] = []
		while !scanner.isAtEnd {
			self.performanceLog.tag(with: "(loop start \(rule.openTag))")
			
			if #available(iOS 13.0, OSX 10.15, watchOS 6.0, tvOS 13.0, *) {
				if let start = scanner.scanUpToCharacters(from: set) {
					self.performanceLog.tag(with: "(first chars \(rule.openTag))")
					self.append(start)
				}
			} else {
				var string : NSString?
				scanner.scanUpToCharacters(from: set, into: &string)
				if let existentString = string as String? {
					self.append(existentString)
				}
			}
			
			// The end of the string
			let spacing = self.scanSpacing(scanner, usingCharactersIn: set)
			guard let foundTag = spacing.foundChars else {
				continue
			}
			
			if foundTag == rule.openTag && foundTag.count < rule.minTags {
				self.append(foundTag)
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
				self.append(escaped)
				continue
			}
			
			
			self.performanceLog.tag(with: "(found tag \(rule.openTag))")
			
			if !foundTag.contains(rule.openTag) && !foundTag.contains(rule.intermediateTag ?? "") && !foundTag.contains(rule.closingTag ?? "") {
				self.append(foundTag)
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
				
			}
			if let remainingEscape = escapeCharacter {
				tokenGroups.append(TokenGroup(string: String(remainingEscape), isEscaped: false, type: .escape))
			}
			
			tokenGroups.append(contentsOf: getTokenGroups(for: &cumulatedString, with: rule, shouldEmpty: true))
			self.append(contentsOf: tokenGroups)
			
			if self.state == .closed {
				tokens.append(contentsOf: self.tokens(beginningGroupNumberAt : tokenGroup))
			}
		}
		
		tokens.append(contentsOf: self.tokens(beginningGroupNumberAt : tokenGroup))
		return tokens
	}
	
	
	func scan( _ string : String, with rule : CharacterRule) -> [Token] {
		
		self.performanceLog.start()
		
		self.rule = rule
		self.tokenGroup = 0
		
		if let token = verifyTagsExist(string) {
			return [token]
		}

		var tokens : [Token] = []
		tokens = self.scanForTags(in: string)
		
		self.performanceLog.end()

		return tokens
	}
	
	/// Checks to ensure that any tags in the rule actually exist in the string.
	/// If there are is not at least one of each of the rule's existing tags, there is no processing
	/// to be done.
	///
	/// - Parameter string: The string to check for the existence of the rule's tags.
	func verifyTagsExist( _ string : String ) -> Token? {
		if !string.contains( rule.openTag ) {
			return Token(type: .string, inputString: string)
		}
		guard let existentClosingTag = rule.closingTag else {
			return nil
		}
		//
		if !string.contains(existentClosingTag) {
			return Token(type: .string, inputString: string)
		}
		guard let hasIntermediateString = rule.intermediateTag else {
			return nil
		}
		if !string.contains(hasIntermediateString) {
			return Token(type: .string, inputString: string)
		}
		return nil
	}
	
	func scanSpacing( _ scanner : Scanner, usingCharactersIn set : CharacterSet ) -> (preTag : String?, foundChars : String?, postTag : String?) {
		self.performanceLog.tag(with: "(scan space)")
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
		self.performanceLog.tag(with: "(end space)")
		
		return (lastChar, maybeFoundChars, nextChar)
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
