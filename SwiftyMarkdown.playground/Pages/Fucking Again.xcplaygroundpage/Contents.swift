//: [Previous](@previous)

import Foundation


// Tag definition



// Example customisation
public enum CharacterStyle : CharacterStyling {
	case none
	case bold
	case italic
	case code
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
	Token(type: .string, inputString: "BB", characterStyles: [CharacterStyle.bold, CharacterStyle.italic]),
	Token(type: .string, inputString: "*", characterStyles: [CharacterStyle.bold, CharacterStyle.italic]),
	Token(type: .string, inputString: "BB", characterStyles: [CharacterStyle.bold, CharacterStyle.italic]),
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


let challenges = [challenge1]

var codeblock = SwiftyTagging(openTag: "`", intermediateTag: nil, closingTag: nil, escapeString: "\\", styles: [1 : [CharacterStyle.code]], maxTags: 1)
codeblock.cancels = .allRemaining
let asterisks = SwiftyTagging(openTag: "*", intermediateTag: nil, closingTag: "*", escapeString: "\\", styles: [1 : [.italic], 2 : [.bold], 3 : [CharacterStyle.bold, CharacterStyle.italic]], maxTags: 3)
let underscores = SwiftyTagging(openTag: "_", intermediateTag: nil, closingTag: nil, escapeString: "\\", styles: [1 : [.italic], 2 : [.bold], 3 : [CharacterStyle.bold, CharacterStyle.italic]], maxTags: 3)

let scan = SwiftyTokeniser(with: [ asterisks, underscores])

for challenge in challenges {
	let finalTokens = scan.process(challenge.input)
	let stringTokens = finalTokens.filter({ $0.type == .string })
	
	guard stringTokens.count == challenge.tokens.count else {
		print("Token count check failed. Expected: \(challenge.tokens.count). Found: \(finalTokens.count)")
		print("-------EXPECTED--------")
		for token in challenge.tokens {
			switch token.type {
			case .string:
				print("\(token.outputString): \(token.characterStyles)")
			default:
				break
			}
		}
		print("-------OUTPUT--------")
		for token in finalTokens {
			switch token.type {
			case .string:
				print("\(token.outputString): \(token.characterStyles)")
			default:
				break
			}
		}
		continue
	}
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
