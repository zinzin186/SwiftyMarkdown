//: [Previous](@previous)

import Foundation

var str = "Hell\\*o, play\\*ground"

struct StringReplacement {
	let index : String.Index
	let length : Int
}

var replacemens : [StringReplacement] = []

public struct SwiftyTagging {
	let openTag : String
	let intermediateTag : String?
	let closingTag : String?
	let escapeString : String?
}

func escapeReplacements( for rule : SwiftyTagging, in string : String ) -> [StringReplacement] {
	guard let existentEscapeString = rule.escapeString else {
		return []
	}
	let ranges = str.ranges(of: "\(existentEscapeString)\(rule.openTag)" )
	var replacements : [StringReplacement] = []
	for range in ranges {
		let replacement1 = StringReplacement(index: range.lowerBound, length: existentEscapeString.count)
		replacements.append(replacement1)
	}

	if let existentClosingTag = rule.closingTag, rule.openTag != existentClosingTag {
		for range in ranges {
			let replacement1 = StringReplacement(index: range.lowerBound, length: existentEscapeString.count)
			replacements.append(replacement1)
		}
	}
	return replacements
}


let token = "*"
let escape = "\\"
let ranges = str.ranges(of: "\(escape)\(token)" )

for range in ranges {
	let replacement1 = StringReplacement(index: range.lowerBound, length: escape.count)
	replacemens.append(replacement1)
}

let p = StringReplacement(index: str.index(str.startIndex, offsetBy: 9), length: 1)

replacemens.append(p)

let els = StringReplacement(index: str.index(str.startIndex, offsetBy: 2), length: 2)

replacemens.append(els)


let sorted = replacemens.sorted() { $0.index > $1.index }

for rep in sorted {
	let endIdx = str.index(rep.index, offsetBy: rep.length)
	str.replaceSubrange(rep.index..<endIdx, with: "")
}

print(str)

//: [Next](@next)
