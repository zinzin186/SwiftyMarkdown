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

enum v2_TokenType {
	case string
	case link
	case metadata
	case tag
}

struct v2_Token {
	var type : v2_TokenType
	let string : String
	var metadata : String = ""
//	let startIndex : String.Index
}

class SwiftyScannerNonRepeating : SwiftyScanning {
	var metadataLookup: [String : String]
	
	var str : String
	var currentIndex : String.Index
	
	var rule : CharacterRule
	var tokens : [Token]

	var openIndices : [Int] = []
	var accumulatedStr : String = ""
	var stringList : [v2_Token] = []

	
	init( tokens : [Token], rule : CharacterRule, metadataLookup : [String : String] = [:] ) {
		self.tokens = tokens
		self.rule = rule
		self.str = tokens.map({ $0.inputString }).joined()
		self.currentIndex = self.str.startIndex
		self.metadataLookup = metadataLookup
	}
	
	func scan() -> [Token] {
		
		if !self.str.contains(rule.primaryTag.tag) {
			return self.tokens
		}
		self.process()
		return self.convertTokens()
	}
	
	func emptyAccumulatedString() {
		if !accumulatedStr.isEmpty {
			stringList.append(v2_Token(type: .string, string: accumulatedStr))
			accumulatedStr.removeAll()
		}
	}
	
	func process() {
		var tokens : [Token] = []

		let openTagStart = rule.primaryTag.tag[rule.primaryTag.tag.startIndex]
		let closeTagStart = ( rule.tag(for: .close)?.tag != nil ) ? rule.tag(for: .close)?.tag[rule.tag(for: .close)!.tag.startIndex] : nil
		


		
		
		while currentIndex != str.endIndex {
			let char = str[currentIndex]
			
			if str[currentIndex] != openTagStart && str[currentIndex] != closeTagStart {
				movePointer(&currentIndex, addCharacter: char)
				continue
			}

			
			// We have the first character of a possible open tag
			if char == openTagStart {
				// Checks to see if there is an escape character before this one
				if let prevIndex = str.index(currentIndex, offsetBy: -1, limitedBy: str.startIndex) {
					if let escapeChar = self.rule.primaryTag.escapeCharacter(for: str[prevIndex]) {
						switch escapeChar.rule {
						case .remove:
							if !accumulatedStr.isEmpty {
								accumulatedStr.removeLast()
							}
						case .keep:
							break
						}
						movePointer(&currentIndex, addCharacter: char)
						continue
					}
				}
				
				emptyAccumulatedString()
				
				guard let nextIdx = str.index(currentIndex, offsetBy: rule.primaryTag.tag.count, limitedBy: str.endIndex) else {
					movePointer(&currentIndex, addCharacter: char)
					continue
				}
				let tag = String(str[currentIndex..<nextIdx])
				if tag != rule.primaryTag.tag {
					movePointer(&currentIndex, addCharacter: char)
					continue
				}
				
				openIndices.append(stringList.count)
				stringList.append(v2_Token(type: .tag, string: tag))
				currentIndex = str.index(currentIndex, offsetBy: rule.primaryTag.tag.count, limitedBy: str.endIndex) ?? str.endIndex
				continue
			}
			if char == closeTagStart {
				
				emptyAccumulatedString()
				
				guard let closeTag = rule.tag(for: .close)?.tag else {
					movePointer(&currentIndex, addCharacter: char)
					continue
				}
				
				guard let nextIdx = str.index(currentIndex, offsetBy: closeTag.count, limitedBy: str.endIndex) else {
					movePointer(&currentIndex, addCharacter: char)
					continue
				}
				let tag = String(str[currentIndex..<nextIdx])
				if tag != closeTag {
					movePointer(&currentIndex, addCharacter: char)
					continue
				}
				if openIndices.isEmpty {
					stringList.append(v2_Token(type: .string, string: String(char)))
					movePointer(&currentIndex)
					continue
				}

				// At this point we have gathered a valid close tag and we have a valid open tag
				
				guard let metadataOpen = rule.tag(for: .metadataOpen), let metadataClose = rule.tag(for: .metadataClose) else {
					currentIndex = nextIdx
					addLink()
					continue
				}
				if nextIdx == str.endIndex {
					movePointer(&currentIndex, addCharacter: char)
					continue
				}
				guard str[nextIdx] == metadataOpen.tag.first else {
					movePointer(&currentIndex, addCharacter: char)
					continue
				}
				
				let substr = str[nextIdx..<str.endIndex]
				guard let closeIdx = substr.firstIndex(of: metadataClose.tag.first!) else {
					movePointer(&currentIndex, addCharacter: char)
					continue
				}
				let open = substr.index(nextIdx, offsetBy: 1, limitedBy: substr.endIndex) ?? substr.endIndex
				let metadataStr = String(substr[open..<closeIdx])
				
				guard !metadataStr.contains(rule.primaryTag.tag) else {
					movePointer(&currentIndex, addCharacter: char)
					continue

				}
				
				currentIndex = str.index(closeIdx, offsetBy: 1, limitedBy: str.endIndex) ?? closeIdx

				addLink(with: metadataStr)
			}
		}

		if !accumulatedStr.isEmpty {
			stringList.append(v2_Token(type: .string, string: accumulatedStr))
		}
	}
	
	func movePointer( _ idx : inout String.Index, addCharacter char : Character? = nil ) {
		idx = str.index(idx, offsetBy: 1, limitedBy: str.endIndex) ?? str.endIndex
		if let character = char {
			accumulatedStr.append(character)
		}
	}
	
	func addLink(with metadataStr : String? = nil) {
		let openIndex = openIndices.removeLast()
		stringList.remove(at: openIndex)
		let subarray = stringList[openIndex..<stringList.count]
		stringList.removeSubrange(openIndex..<stringList.count)
		stringList.append(v2_Token(type: .link, string: subarray.map({ $0.string }).joined(), metadata: metadataStr ?? ""))
	}
	
	func convertTokens() -> [Token] {
		if !stringList.contains(where: { $0.type == .link }) {
			return [Token(type: .string, inputString: stringList.map({ $0.string}).joined())]
		}
		var tokens : [Token] = []
		var allStrings : [v2_Token] = []
		for tok in stringList {
			if tok.type == .link {
				if !allStrings.isEmpty {
					tokens.append(Token(type: .string, inputString: allStrings.map({ $0.string }).joined()))
					allStrings.removeAll()
				}
				let ruleStyles = self.rule.styles[1] ?? []
				let charStyles = ( rule.isSelfContained ) ? [] : ruleStyles
				var token = Token(type: .string, inputString: tok.string, characterStyles: charStyles)
				token.metadataString = tok.metadata
				
				if rule.isSelfContained {
					var parentToken = Token(type: .string, inputString: token.id, characterStyles: ruleStyles)
					parentToken.children = [token]
					tokens.append(parentToken)
				} else {
					tokens.append(token)
				}
			} else {
				allStrings.append(tok)
			}
		}
		if !allStrings.isEmpty {
			tokens.append(Token(type: .string, inputString: allStrings.map({ $0.string }).joined()))
		}
		
		return tokens
	}
	
	// Old
	
	func scan( _ tokens : [Token], with rule : CharacterRule ) -> [Token] {
		self.tokens = tokens
		return self.scan(tokens.map({ $0.inputString }).joined(), with: rule)
	}
	
	func scan(_ string: String, with rule: CharacterRule) -> [Token] {
		return []
	}
}
