//: [Previous](@previous)


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

public struct SwiftyTagging {
	public let openTag : String
	public let intermediateTag : String?
	public let closingTag : String?
	public let escapeCharacter : Character?
	public let styles : [Int : [CharacterStyling]]
	public var maxTags : Int = 1
	public var spacesAllowed : SpaceAllowed = .oneSide
	public var cancels : Cancel = .none
	
	public init(openTag: String, intermediateTag: String? = nil, closingTag: String? = nil, escapeCharacter: Character? = nil, styles: [Int : [CharacterStyling]] = [:], maxTags : Int = 1) {
		self.openTag = openTag
		self.intermediateTag = intermediateTag
		self.closingTag = closingTag
		self.escapeCharacter = escapeCharacter
		self.styles = styles
		self.maxTags = maxTags
	}
}

// Token definition
public enum TokenType {
	case openTag
	case intermediateTag
	case closeTag
	case processed
	case string
	case escape
	case metadata
}



public struct Token {
	public let id = UUID().uuidString
	public var type : TokenType
	public let inputString : String
	public var metadataString : String? = nil
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
			case .metadata, .processed:
				return ""
			case .escape, .string:
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

		var currentTokens : [Token] = []
		var mutableRules = self.rules
		while !mutableRules.isEmpty {
			let nextRule = mutableRules.removeFirst()
			if currentTokens.isEmpty {
				// This means it's the first time through
				currentTokens = self.applyStyles(to: self.scan(inputString, with: nextRule), usingRule: nextRule)
				continue
			}
			
			// Each string could have additional tokens within it, so they have to be scanned as well with the current rule.
			// The one string token might then be exploded into multiple more tokens
			var replacements : [Int : [Token]] = [:]
			for (idx,token) in currentTokens.enumerated() {
				switch token.type {
				case .string:
					let nextTokens = self.scan(token.outputString, with: nextRule)
					replacements[idx] = self.applyStyles(to: nextTokens, usingRule: nextRule)
				default:
					break
				}
			}
			
			// This replaces the individual string tokens with the new token arrays
			// making sure to apply any previously found styles to the new tokens.
			for key in replacements.keys.sorted(by: { $0 > $1 }) {
				let existingToken = currentTokens[key]
				var newTokens : [Token] = []
				for token in replacements[key]! {
					var newToken = token
					newToken.characterStyles.append(contentsOf: existingToken.characterStyles)
					newTokens.append(newToken)
				}
				currentTokens.replaceSubrange(key...key, with: newTokens)
			}
		}
		return currentTokens
	}
	
	func handleClosingTagFromOpenTag(withIndex index : Int, in tokens: inout [Token], following rule : SwiftyTagging ) {
		
		guard rule.closingTag != nil else {
			return
		}
		
		var metadataIndex = index
		// If there's an intermediate tag, get the index of that
		if rule.intermediateTag != nil {
			guard let nextTokenIdx = tokens.firstIndex(where: { $0.type == .intermediateTag }) else {
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
		
		guard let closeTokenIdx = tokens.firstIndex(where: { $0.type == .closeTag }) else {
			return
		}
		var metadataString : String = ""
		for i in metadataIndex..<closeTokenIdx {
			var otherTokens = tokens[i]
			otherTokens.type = .metadata
			tokens[i] = otherTokens
			metadataString.append(otherTokens.outputString)
		}
		tokens[closeTokenIdx].type = .processed
		tokens[metadataIndex].type = .processed
		tokens[index].type = .processed
		tokens[index].metadataString = metadataString
		
		
		
	}
	
	
	func applyStyles( to tokens : [Token], usingRule rule : SwiftyTagging ) -> [Token] {
		var nextTokens : [Token] = []
		var mutableTokens : [Token] = tokens
		print( tokens.map( { ( $0.outputString, $0.count )}))
		for idx in 0..<mutableTokens.count {
			let token = mutableTokens[idx]
			switch token.type {
			case .escape:
				print( "Found escape (\(token.inputString))" )
				nextTokens.append(token)
			case .openTag:
				let theToken = mutableTokens[idx]
				print ("Found open tag with tag count \(theToken.count) tags: \(theToken.inputString). Current rule open tag = \(rule.openTag)" )
				
				guard rule.closingTag == nil else {
					
					// If there's an intermediate tag, get the index of that
					self.handleClosingTagFromOpenTag(withIndex: idx, in: &mutableTokens, following: rule)
					// Get the index of the closing tag
					
					continue
				}
				
				guard theToken.count > 0 else {
					nextTokens.append(theToken)
					continue
				}
				
				let startIdx = idx
				var endIdx : Int? = nil
				
				if let nextTokenIdx = mutableTokens.firstIndex(where: { $0.inputString == theToken.inputString && $0.type == theToken.type && $0.count == theToken.count && $0.id != theToken.id }) {
					endIdx = nextTokenIdx
				}
				guard let existentEnd = endIdx else {
					nextTokens.append(theToken)
					continue
				}
				
				let styles : [CharacterStyling] = rule.styles[theToken.count] ?? []
				for i in startIdx..<existentEnd {
					var otherTokens = mutableTokens[i]
					for style in styles {
						otherTokens.characterStyles.append(style)
					}
					mutableTokens[i] = otherTokens
				}
				var newToken = theToken
				newToken.count = 0
				nextTokens.append(newToken)
				mutableTokens[idx] = newToken
				
				var closeToken = mutableTokens[existentEnd]
				closeToken.count = 0
				mutableTokens[existentEnd] = closeToken
			case .intermediateTag:
				let theToken = mutableTokens[idx]
				print ("Found intermediate tag with tag count \(theToken.count) tags: \(theToken.inputString)" )
				nextTokens.append(theToken)
			case .closeTag:
				let theToken = mutableTokens[idx]
				print ("Found close tag with tag count \(theToken.count) tags: \(theToken.inputString)" )
				nextTokens.append(theToken)
			case .string:
				let theToken = mutableTokens[idx]
				print ("Found String: \(theToken.inputString)" )
				nextTokens.append(theToken)
			case .metadata:
				let theToken = mutableTokens[idx]
				print ("Found metadata: \(theToken.inputString)" )
				nextTokens.append(theToken)
			case .processed:
				let theToken = mutableTokens[idx]
				print ("Found already processed tag: \(theToken.inputString)" )
				nextTokens.append(theToken)
			}
		}
		return nextTokens
	}
	
	
	func scan( _ string : String, with rule : SwiftyTagging) -> [Token] {
		let scanner = Scanner(string: string)
		scanner.charactersToBeSkipped = nil
		var tokens : [Token] = []
		var set = CharacterSet(charactersIn: "\(rule.openTag)\(rule.intermediateTag ?? "")\(rule.closingTag ?? "")")
		if let existentEscape = rule.escapeCharacter {
			set.insert(charactersIn: String(existentEscape))
		}
		
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
				var token = Token(type: type, inputString: inputString)
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
				} else if cumulativeString == rule.intermediateTag {
					intermediateString.append(cumulativeString)
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
			addToken(for: .intermediateTag)
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


// Example customisation
public enum CharacterStyle : CharacterStyling {
	case none
	case bold
	case italic
	case code
	case link
	
}



var str = "A standard paragraph with an *italic*, * spaced asterisk, \\*escaped asterisks\\*, _underscored italics_, \\_escaped underscores\\_, **bold** \\*\\*escaped double asterisks\\*\\*, __underscored bold__, _ spaced underscore \\_\\_escaped double underscores\\_\\_ and a `code block *with an italic that should be ignored*`."

//str = "**AAAA*BB\\*BB*AAAAAA**"
str = "*_*Bold and italic*_*"
str = "*Italic* `Code block with *ignored* italic` __Bold__"

struct Test {
	let input : String
	let output : String
	let tokens : [Token]
}

let challenge1 = Test(input: "*_*italic*_*", output: "italic",  tokens: [
	Token(type: .string, inputString: "italic", characterStyles: [CharacterStyle.italic])
])
let challenge2 = Test(input: "*Italic* `Code block with *ignored* italic` __Bold__", output : "Italic `Code block with *ignored* italic` Bold", tokens : [
	Token(type: .string, inputString: "Italic", characterStyles: [CharacterStyle.italic]),
	Token(type: .string, inputString: " ", characterStyles: []),
	Token(type: .string, inputString: "Code block with *ignored* italic", characterStyles: [CharacterStyle.code]),
	Token(type: .string, inputString: " ", characterStyles: []),
	Token(type: .string, inputString: "Bold", characterStyles: [CharacterStyle.bold])
])
let challenge3 = Test(input: " * ", output : " * ", tokens : [
	Token(type: .string, inputString: " ", characterStyles: []),
	Token(type: .string, inputString: "*", characterStyles: []),
	Token(type: .string, inputString: " ", characterStyles: [])
])
let challenge4 = Test(input: "**AAAA*BB\\*BB*AAAAAA**", output : "AAAABB*BBAAAAAA", tokens : [
	Token(type: .string, inputString: "AAAA", characterStyles: [CharacterStyle.bold]),
	Token(type: .string, inputString: "BB*BB", characterStyles: [CharacterStyle.bold, CharacterStyle.italic]),
	Token(type: .string, inputString: "AAAAAA", characterStyles: [CharacterStyle.bold]),
])
let challenge5 = Test(input: "*Italic* \\_\\_Not Bold\\_\\_ **Bold**", output : "Italic __Not Bold__ Bold", tokens : [
	Token(type: .string, inputString: "Italic", characterStyles: [CharacterStyle.italic]),
	Token(type: .string, inputString: " __Not Bold__ ", characterStyles: []),
	Token(type: .string, inputString: "Bold", characterStyles: [CharacterStyle.bold])
])

let challenge6 = Test(input: " *\\** ", output : " *** ", tokens : [
	Token(type: .string, inputString: " *** ", characterStyles: [])
])

let challenge7 = Test(input: " *\\**Italic*\\** ", output : " *Italic* ", tokens : [
	Token(type: .string, inputString: " ", characterStyles: []),
	Token(type: .string, inputString: "*Italic*", characterStyles: [CharacterStyle.italic]),
	Token(type: .string, inputString: " ", characterStyles: []),
])

let challenge8 = Test(input: "[*Link*](https://www.neverendingvoyage.com/)", output : "Link", tokens : [
	Token(type: .string, inputString: "Link", characterStyles: [CharacterStyle.link, CharacterStyle.italic])
])

let challenge9 = Test(input: "`Code (should not be indented)`", output: "Code (should not be indented)", tokens: [
	Token(type: .string, inputString: "Link", characterStyles: [CharacterStyle.link, CharacterStyle.italic])
])

let challenge10 = Test(input: "A string with a **bold** word", output: "A string with a bold word",  tokens: [
	Token(type: .string, inputString: "A string with a ", characterStyles: []),
	Token(type: .string, inputString: "bold", characterStyles: [CharacterStyle.bold]),
	Token(type: .string, inputString: " word", characterStyles: [])
])


let challenges = [challenge10]

var links = SwiftyTagging(openTag: "[", intermediateTag: "](", closingTag: ")", escapeCharacter: "\\", styles: [1 : [CharacterStyle.link]], maxTags: 1)
var codeblock = SwiftyTagging(openTag: "`", intermediateTag: nil, closingTag: nil, escapeCharacter: "\\", styles: [1 : [CharacterStyle.code]], maxTags: 1)
codeblock.cancels = .allRemaining
let asterisks = SwiftyTagging(openTag: "*", intermediateTag: nil, closingTag: nil, escapeCharacter: "\\", styles: [1 : [.italic], 2 : [.bold], 3 : [CharacterStyle.bold, CharacterStyle.italic]], maxTags: 3)
let underscores = SwiftyTagging(openTag: "_", intermediateTag: nil, closingTag: nil, escapeCharacter: "\\", styles: [1 : [.italic], 2 : [.bold], 3 : [CharacterStyle.bold, CharacterStyle.italic]], maxTags: 3)

let scan = SwiftyTokeniser(with: [ links, asterisks])

for challenge in challenges {
	let finalTokens = scan.process(challenge.input)
	let stringTokens = finalTokens.filter({ $0.type == .string })
	
	guard stringTokens.count == challenge.tokens.count else {
		print("Token count check failed. Expected: \(challenge.tokens.count). Found: \(stringTokens.count)")
		print("-------EXPECTED--------")
		for token in challenge.tokens {
			switch token.type {
			case .string:
				print("\(token.outputString): \(token.characterStyles)")
			default:
				print("\(token.outputString)")
			}
		}
		print("-------OUTPUT--------")
		for token in finalTokens {
			switch token.type {
			case .string:
				print("\(token.outputString): \(token.characterStyles)")
			default:
				if !token.outputString.isEmpty {
					print("\(token.outputString)")
				}
				
			}
		}
		continue
	}
	
	print("-----EXPECTATIONS-----")
	for (idx, token) in stringTokens.enumerated() {
		let expected = challenge.tokens[idx]

		if expected.type != token.type {
			print("Failure: Token types are different. Expected: \(expected.type), found: \(token.type)")
		}
		
		switch token.type {
		case .string:
			print("Expected: \(expected.outputString): \(expected.characterStyles)")
			print("Found: \(token.outputString): \(token.characterStyles)")
		default:
			break
		}
	}

	let string = finalTokens.map({ $0.outputString }).joined()
	print("-------OUTPUT VS INPUT--------")
	print("Input: \(challenge.input)")
	print("Expected: \(challenge.output)")
	print("Output: \(string)")
	
}






//: [Next](@next)
