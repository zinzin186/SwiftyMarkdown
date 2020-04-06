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
	let group : Int
	let string : String
	var metadata : String = ""
}

class SwiftyScannerNonRepeating : SwiftyScanning {
	var metadataLookup: [String : String] = [:]
	
	var str : String = "" {
		didSet {
			self.currentIndex = str.startIndex
		}
	}
	var currentIndex : String.Index = "".startIndex
	var accumulatedStr : String = ""
	var openIndices : [Int] = []
	var stringList : [v2_Token] = []
	var rule : CharacterRule! = nil
	
	init() { }
	
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
		stringList.append(v2_Token(type: .link, group: 0, string: subarray.map({ $0.string }).joined(), metadata: metadataStr ?? ""))

	}
	
	func scan( _ tokens : [Token], with rule : CharacterRule ) -> [Token] {
		
	}
	
	
	func scan(_ string: String, with rule: CharacterRule) -> [Token] {
		var tokens : [Token] = []
		self.str = string
		
		self.rule = rule
		var isEscape = false
		let openTagStart = rule.openTag[rule.openTag.startIndex]
		let closeTagStart = ( rule.closeTag != nil ) ? rule.closeTag![rule.closeTag!.startIndex] : nil

		while currentIndex != str.endIndex {
			let char = str[currentIndex]

			if char == rule.escapeCharacter {
				isEscape = true
				movePointer(&currentIndex)
				continue
			}
			if isEscape {
				isEscape = false
				movePointer(&currentIndex, addCharacter: char)
				continue
			}
			
			if str[currentIndex] != openTagStart && str[currentIndex] != closeTagStart {
				movePointer(&currentIndex, addCharacter: char)
				continue
			}
			if !accumulatedStr.isEmpty {
				stringList.append(v2_Token(type: .string, group: 0, string: accumulatedStr))
				accumulatedStr.removeAll()
			}
			
			// We have the first character of a possible open tag
			if char == openTagStart {
				guard let nextIdx = str.index(currentIndex, offsetBy: rule.openTag.count, limitedBy: str.endIndex) else {
					movePointer(&currentIndex, addCharacter: char)
					continue
				}
				let tag = String(str[currentIndex..<nextIdx])
				if tag != rule.openTag {
					movePointer(&currentIndex, addCharacter: char)
					continue
				}
				
				openIndices.append(stringList.count)
				stringList.append(v2_Token(type: .tag, group: 0, string: tag))
				currentIndex = str.index(currentIndex, offsetBy: rule.openTag.count, limitedBy: str.endIndex) ?? str.endIndex
				continue
			}
			if char == closeTagStart {
				guard let closeTag = rule.closeTag else {
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
					stringList.append(v2_Token(type: .string, group: 0, string: String(char)))
					movePointer(&currentIndex)
					continue
				}

				// At this point we have gathered a valid close tag and we have a valid open tag
				
				guard let metadataOpen = rule.metadataOpen, let close = rule.metadataClose else {
					currentIndex = nextIdx
					addLink()
					continue
				}
				if nextIdx == str.endIndex {
					movePointer(&currentIndex, addCharacter: char)
					continue
				}
				guard str[nextIdx] == rule.metadataOpen else {
					movePointer(&currentIndex, addCharacter: char)
					continue
				}
				
				let substr = str[nextIdx..<str.endIndex]
				guard let closeIdx = substr.firstIndex(of: close) else {
					movePointer(&currentIndex, addCharacter: char)
					continue
				}
				let open = substr.index(nextIdx, offsetBy: 1, limitedBy: substr.endIndex) ?? substr.endIndex
				let metadataStr = String(substr[open..<closeIdx])
				currentIndex = str.index(closeIdx, offsetBy: 1, limitedBy: str.endIndex) ?? closeIdx

				addLink(with: metadataStr)
			}
		}

		if !accumulatedStr.isEmpty {
			stringList.append(v2_Token(type: .string, group: 0, string: accumulatedStr))
		}
		
		if !self.stringList.contains(where: { $0.type == .link }) {
			return [Token(type: .string, inputString: self.stringList.map({ $0.string}).joined())]
		}
		
		
		for tok in self.stringList {
			if tok.type == .string {
				tokens.append(Token(type: .string, inputString: tok.string))
			}
			if tok.type == .link {
				tokens.append(Token(type: .openTag, inputString: self.rule.openTag))
				var token = Token(type: .string, inputString: tok.string, characterStyles: self.rule.styles[1] ?? [])
				token.metadataString = tok.metadata
				token.isProcessed = true
				tokens.append(token)
				if let close = self.rule.closeTag {
					tokens.append(Token(type: .closeTag, inputString: close))
				}
			}
		}
		
		return tokens
	}
	
	
}
