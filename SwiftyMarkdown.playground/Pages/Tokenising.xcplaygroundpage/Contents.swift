//: [Previous](@previous)

import Foundation
import UIKit

let open = "**__"
let close = "_**_"
var openEdit = open
var closeEdit = close

var remainingOpen = ""
var remainingClose = ""

var removedCount = 0
for (idx,char) in open.enumerated() {
	// Get the last character of the opening tag
	guard let lastOpen = openEdit.popLast() else {
		break
	}
	guard let firstClose = closeEdit.first else {
		break
	}
	if lastOpen == firstClose {
		closeEdit.removeFirst()
	} else {
		remainingOpen.append(String(lastOpen))
	}
	
}

print(remainingOpen)
print( closeEdit)


let tokenisedString = "%1 Here is a string with a token and a %2 and a last token %3. No more tokens"
var updatingString = tokenisedString


struct Tokeniser {
	let token : String
	let replacement : String
	var distance : String.IndexDistance {
		return replacement.distance(from: replacement.startIndex, to: replacement.endIndex)
	}
}

let tokens = [Tokeniser(token: "%1", replacement: ""), Tokeniser(token: "%2", replacement: "token"), Tokeniser(token: "%3", replacement: "here")]

var indices : [Range<String.Index>] = []
for token in tokens {
	if let first = updatingString.range(of: token.token)?.lowerBound {
		updatingString = updatingString.replacingOccurrences(of: token.token, with: token.replacement)
		indices.append(first..<updatingString.index(first, offsetBy: token.distance))
	}
}

let attString = NSMutableAttributedString(string: updatingString)
for index in indices {
	
	let attribute = [NSAttributedString.Key.foregroundColor : UIColor.red]
	
	attString.addAttributes(attribute, range: NSRange(index, in: updatingString))
	
	print( updatingString[index])
	
}

attString


var string = "**_!*]("

var lastChar = string[string.startIndex]
var count = 0
for (idx, char) in string.enumerated() {

	if char != lastChar {
		switch count {
		case 2:
			print("2")
		case 1:
			print("1")
		default:
			break
		}
		count = 0
	}
	switch char {
	case "*", "_":
		count += 1
	default:
		count = 0
	}
	lastChar = char
}
switch lastChar {
case "*", "_":
	switch count {
	case 2:
		print("2")
	case 1:
		print("1")
	default:
		break
	}
default:
	break
}


//: [Next](@next)
