import Foundation
//let string = """
//# Heading 1
//## Heading 2
//### #Heading #3
//  #### #Heading 4 ####
// ##### Heading 5 ####
// ##### Heading 5 #### More
//# Hea
// Heading 1
//  =======
//    # Heading 1
//
//Here we go with some *italic*, **bold**, _italic_, __bold__, and a [link](https://www.neverendingvoyage.com/) to start with.
//
//"""

var challenges = """
*[**link**](   https://www.neverendingvoyage.com/   )* <- Should be a bold, italic link
[link](   https://www.neverendingvoyage.com/   ) <- Should be a link
[link](](   https://www.neverendingvoyage.com/   ))) <- Should be "link]())"
Here we go with some *italic*, **bold**, _italic_, __bold__, and a [link](https://www.neverendingvoyage.com/) to start with.
*[**link**](   https://www.neverendingvoyage.com/   )* <- Should be a bold, italic link
[link](](   https://www.neverendingvoyage.com/   ))) <- Should be "link]())"
\\[link\\]\\(https://www.neverendingvoyage.com/\\)
`code`, `**code**` ```code``` *_*`**code**`*_*
"""

let string = """
# Heading 1
"""

enum CharacterStyle : Int {
    case none
    case italic
    case underscoreItalic
    case bold
    case underscoreBold
    case code
    case link
    case image
}

struct LineAttribute  {
    let attributes : [CharacterStyle]
    let token : String
    let original : String
    let replacement : String
    var distance : String.IndexDistance {
        return replacement.distance(from: replacement.startIndex, to: replacement.endIndex)
    }
}




public struct LineStyleElement {
    let token : String
    let remove : Remove
    let type : LineStyling
    let trimmed : Bool
}

let tagList = "!\\_*`[]()"
let validMarkdownTags = CharacterSet(charactersIn: "!\\_*`[]()")
 
extension LineAttribute : Equatable {
    static func == ( _ lhs : LineAttribute, _ rhs : LineAttribute ) -> Bool {
        return lhs.attributes == rhs.attributes && lhs.token == rhs.token && lhs.original == rhs.original
    }
}

struct MarkdownTag {
    var openTag : String
    var closingTag : String = ""
    var enclosedText : String = ""
    var url : String? = nil
    var closeURL : String? = nil
    var original : String {
        return "\(openTag)\(enclosedText)\(closingTag)\(url ?? "")\(closeURL ?? "")"
    }
}

struct Token {
    let token : String
    var markdownTag : MarkdownTag
    var replacementPrefix : String = ""
    var replacement : String
    var replacementSuffix : String = ""
    var foundAttributes : [CharacterStyle]
    var url : URL?
    var imageIdentifier : String?
    var replacementRange : Range<String.Index>? = nil
    var distance : String.IndexDistance {
        return replacement.distance(from: replacement.startIndex, to: replacement.endIndex)
    }
    
    mutating func replaceToken( in string : String ) -> String {
        var replacementString = string
        if let first = string.range(of: self.token)?.lowerBound {
            replacementString = string.replacingOccurrences(of: self.token, with: "\(self.replacementPrefix)\(self.replacement)\(self.replacementSuffix)")
            let range = first..<replacementString.index(first, offsetBy: self.distance)
            self.replacementRange = range
        }
        return replacementString
    }
}



extension Token : Equatable {
    static func == ( _ lhs : Token, _ rhs : Token ) -> Bool {
        return lhs.token == rhs.token && lhs.markdownTag.original == rhs.markdownTag.original
    }
}

  

func replaceTokens( in line : SwiftyLine ) -> SwiftyLine {
    var replacementString : String = line.line
    
    var newTokens : [Token] = []
    for var token in line.tokens {
        replacementString = token.replaceToken(in: replacementString)
        newTokens.append(token)
    }
    return Line(line: replacementString, lineStyle: line.lineStyle, tokens: newTokens)
}

func tokenisePre13( _ line : SwiftyLine ) -> SwiftyLine {
    return line
}

@available(iOSApplicationExtension 13.0, *)
func tokenise( _ line : SwiftyLine ) -> SwiftyLine {
    
    // Do nothing if it's a codeblock
    if !line.lineStyle.tokenise {
        return line
    }
    var output : String = ""
    let textScanner = Scanner(string: line.line)
    textScanner.charactersToBeSkipped = nil
    
    var tokenIdx = 1
    var tokens : [Token] = []
    while !textScanner.isAtEnd {
        
        if let start = textScanner.scanUpToCharacters(from: validMarkdownTags) {
            output.append(start)
        }
        if var startAttribute = textScanner.scanCharacters(from: validMarkdownTags) {
            var markdownTag = MarkdownTag(openTag: startAttribute)
            if var enclosedText = textScanner.scanUpToCharacters(from: validMarkdownTags) {
                markdownTag.enclosedText = enclosedText
                if let endAttribute = textScanner.scanCharacters(from:  validMarkdownTags ) {
                    // If we reach here, there's a valid markdown tag and we can tokenise the string
                    markdownTag.closingTag = endAttribute
                    if endAttribute.contains( "](" ) || endAttribute.contains( "][" ) {
                        if let enclosedURL = textScanner.scanUpToString(")") {
                            markdownTag.url = enclosedURL
                        }
                        if let end = textScanner.scanCharacters(from: validMarkdownTags) {
                            markdownTag.closeURL = end
                        }
                    }
                    
                    let token = Token(token: "%\(tokenIdx)", markdownTag: markdownTag, replacement: "", foundAttributes: [])
                    tokens.append(token)
                    output.append(token.token)
                    tokenIdx += 1
                } else {
                    
                    for char in tagList {
                        if char == "\\" {
                            continue
                        }
                        startAttribute = startAttribute.replacingOccurrences(of: "\\\(char)", with: "\(char)")
                        enclosedText = startAttribute.replacingOccurrences(of: "\\\(char)", with: "\(char)")
                    }
                    output.append ( startAttribute )
                    output.append( enclosedText )
                }
            } else {
                
                for char in tagList {
                    if char == "\\" {
                        continue
                    }
                    startAttribute = startAttribute.replacingOccurrences(of: "\\\(char)", with: "\(char)")
                }
                
                output.append ( startAttribute )
            }
        } else {
            output.append( String(line.line[textScanner.currentIndex..<line.line.endIndex]) )
            break
        }
    }
    return Line(line: output, lineStyle: line.lineStyle, tokens: tokens)
}

func handleLinks( in token : Token ) -> Token {
    var newToken = token
    var newTag = token.markdownTag
    print( newTag.openTag )
    print( newTag.closingTag )
    print( newTag.closeURL ?? "" )
    if ( newTag.openTag.contains("[") || newTag.openTag.contains("![") ) && newTag.closingTag.contains("](") && (newTag.closeURL?.contains(")") ?? false) {
        if let range =  newTag.closingTag.ranges(of: "![").first {
            newTag.closingTag.removeSubrange(range)
        } else if let bracketIdx = newTag.openTag.firstIndex(of:"[") {
            newTag.openTag.remove(at: bracketIdx)
        }
        if let range =  newTag.closingTag.ranges(of: "](").first {
            newTag.closingTag.removeSubrange(range)
        }
        if let bracketIdx = newTag.closeURL?.firstIndex(of:")") {
            newTag.closeURL?.remove(at: bracketIdx)
        }
        if let existentURL = newTag.url?.trimmingCharacters(in: .whitespaces) {
            newTag.url = nil
            let url = URL(string: existentURL)
            if url?.scheme == nil {
                newToken.imageIdentifier = existentURL
            } else {
                newToken.url = url
            }
        }
        newToken.markdownTag = newTag
        newToken.foundAttributes.append(.link)
        newToken.replacement = newToken.markdownTag.enclosedText
    }
    
    return newToken
}

func handleFormatting( in token : Token ) -> Token {
    var newToken = token
    var attributes : Set<CharacterStyle> = []
    newToken.markdownTag.openTag = String(token.markdownTag.openTag.reversed())
    if newToken.markdownTag.openTag == token.markdownTag.closingTag {
        // Easy territory!
        if let idx = newToken.markdownTag.openTag.firstIndex(of: "`") {
            attributes.insert(.code)
            newToken.markdownTag.openTag.remove(at: idx)
            newToken.markdownTag.closingTag.remove(at: idx)
            
            let range = newToken.markdownTag.openTag.startIndex..<idx
            
            newToken.markdownTag.enclosedText = String(newToken.markdownTag.openTag[range]) + newToken.markdownTag.enclosedText
            newToken.markdownTag.openTag.removeSubrange(range)
            newToken.markdownTag.enclosedText = newToken.markdownTag.enclosedText + String(newToken.markdownTag.closingTag[range])
            newToken.markdownTag.closingTag.removeSubrange(range)
        }
        
        var openTag = newToken.markdownTag.openTag
        var count = 0
        var foundBold : Int? = nil
        var foundItalic : Int? = nil
        var skipNext = false
        
        for (idx,char) in newToken.markdownTag.openTag.enumerated() {
            if skipNext {
                skipNext = false
                continue
            }
            if char == "*" || char == "_" {
                if foundBold == nil {
                    if idx < (newToken.markdownTag.openTag.count - 1) {
                        let start = newToken.markdownTag.openTag.index(newToken.markdownTag.openTag.startIndex, offsetBy: idx)
                        let end = newToken.markdownTag.openTag.index(newToken.markdownTag.openTag.startIndex, offsetBy: idx + 1)
                        if newToken.markdownTag.openTag[end] == char {
                            foundBold = idx
                            skipNext = true
                            attributes.insert(.bold)
                            continue
                        }
                    }
                }
                if foundItalic == nil {
                    foundItalic = idx
                    attributes.insert(.italic)
                }
            }
            if foundBold != nil && foundItalic != nil {
                break
            }
        }
        if let italicIdx = foundItalic {
            print(italicIdx)
            let start = newToken.markdownTag.openTag.index(newToken.markdownTag.openTag.startIndex, offsetBy: italicIdx)
            newToken.markdownTag.openTag.remove(at: start)
            newToken.markdownTag.closingTag.remove(at: start)
            if let boldIdx = foundBold, boldIdx >= italicIdx {
                foundBold = boldIdx - 1
            }
        }
        if let boldIdx = foundBold {
            print(boldIdx)
            let start = newToken.markdownTag.openTag.index(newToken.markdownTag.openTag.startIndex, offsetBy: boldIdx)
            let end = newToken.markdownTag.openTag.index(newToken.markdownTag.openTag.startIndex, offsetBy: boldIdx + 1)
            newToken.markdownTag.openTag.removeSubrange(start...end)
            newToken.markdownTag.closingTag.removeSubrange(start...end)
        }
        
        
    } else {
        
    }
    newToken.markdownTag.openTag = String(newToken.markdownTag.openTag.reversed())
    print(newToken.replacementPrefix)
    
    return newToken
}

func attributes( from token : Token ) -> Token {
    var newToken = token
    for (idx, char) in tagList.enumerated() {
        if char == "\\" {
            continue
        }
        newToken.markdownTag.openTag = newToken.markdownTag.openTag.replacingOccurrences(of: "\\\(char)", with: "\(idx)")
        newToken.markdownTag.closingTag = newToken.markdownTag.closingTag.replacingOccurrences(of: "\\\(char)", with: "\(idx)")
        newToken.markdownTag.closeURL = newToken.markdownTag.closeURL?.replacingOccurrences(of: "\\\(char)", with: "\(idx)")
    }
    newToken = handleLinks(in: newToken)
    newToken = handleFormatting(in: newToken)
    
    for (idx, char) in tagList.enumerated() {
        if char == "\\" {
            continue
        }
        newToken.markdownTag.openTag = newToken.markdownTag.openTag.replacingOccurrences(of: "\(idx)", with: "\(char)")
        newToken.markdownTag.closingTag = newToken.markdownTag.closingTag.replacingOccurrences(of: "\(idx)", with: "\(char)")
        newToken.markdownTag.closeURL = newToken.markdownTag.closeURL?.replacingOccurrences(of: "\(idx)", with: "\(char)")
    }
    
    newToken.replacementPrefix = newToken.markdownTag.openTag
    newToken.replacement = newToken.markdownTag.enclosedText
    newToken.replacementSuffix = "\(newToken.markdownTag.closingTag)\(newToken.markdownTag.url ?? "")\(newToken.markdownTag.closeURL ?? "")"
    return newToken
}

func process( _ tokens : [Token] ) -> [Token] {
    
    var doneTokens : [Token] = []
    for token in tokens {
        doneTokens.append(attributes(from: token))
    }
    
    return doneTokens
}

func attributedString( for line : Line ) -> NSAttributedString {
    return NSAttributedString(string: line.line)
}



enum MarkdownLineStyle : LineStyling {
    var shouldTokeniseLine: Bool {
        switch self {
        case .codeblock:
            return false
        default:
            return true
        }
        
    }
    
    case h1
    case h2
    case h3
    case h4
    case h5
    case h6
    case previousH1
    case previousH2
    case body
    case blockquote
    case codeblock
    case unorderedList
    func styleIfFoundStyleAffectsPreviousLine() -> LineStyling? {
        switch self {
        case .previousH1:
            return MarkdownLineStyle.h1
        case .previousH2:
            return MarkdownLineStyle.h2
        default :
            return nil
        }
    }
}

var rules = [
    LineRule(token: "=", type: MarkdownLineStyle.previousH1, removeFrom: .entireLine, changeAppliesTo: .previous),
    LineRule(token: "-", type: MarkdownLineStyle.previousH2, removeFrom: .entireLine, changeAppliesTo: .previous),
    LineRule(token: "    ", type: MarkdownLineStyle.codeblock, removeFrom: .leading),
    LineRule(token: "\t", type: MarkdownLineStyle.codeblock, removeFrom: .leading),
    LineRule(token: ">",type : MarkdownLineStyle.blockquote, removeFrom: .leading),
    LineRule(token: "- ",type : MarkdownLineStyle.unorderedList, removeFrom: .leading),
    LineRule(token: "# ",type : MarkdownLineStyle.h1, removeFrom: .both),
    LineRule(token: "## ",type : MarkdownLineStyle.h2, removeFrom: .both),
    LineRule(token: "### ",type : MarkdownLineStyle.h3, removeFrom: .both),
    LineRule(token: "#### ",type : MarkdownLineStyle.h4, removeFrom: .both),
    LineRule(token: "##### ",type : MarkdownLineStyle.h5, removeFrom: .both),
    LineRule(token: "###### ",type : MarkdownLineStyle.h6, removeFrom: .both)
]

let lineProcessor = SwiftyLineProcessor(rules: rules, defaultRule: MarkdownLineStyle.body)
let foundAttributes = lineProcessor.process(string)


for output in foundAttributes {
    var processed : SwiftyLine
    if #available(iOSApplicationExtension 13.0, *) {
        processed = tokenise(output)
    } else {
        processed = tokenisePre13(output)
    }
//    processed.tokens = process(processed.tokens)
    processed = replaceTokens(in: processed)
    print(processed.line)
}

let tokens = "***_***Hey**_****"
// The above should equal "*Hey*"
