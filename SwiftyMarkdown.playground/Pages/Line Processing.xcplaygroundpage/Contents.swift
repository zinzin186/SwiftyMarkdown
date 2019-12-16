import Foundation

public protocol LineStyling {
    var shouldTokeniseLine : Bool { get }
    func styleIfFoundStyleAffectsPreviousLine() -> LineStyling?
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

public struct Line : CustomStringConvertible {
    let line : String
    let lineStyle : LineStyling
    public var description: String {
        return self.line
    }
}

extension Line : Equatable {
    public static func == ( _ lhs : Line, _ rhs : Line ) -> Bool {
        return lhs.line == rhs.line
    }
}

public enum Remove {
    case leading
    case trailing
    case both
    case entireLine
    case none
}

public enum ChangeApplication {
    case current
    case previous
}

public struct LineRule {
    let token : String
    var removeFrom : Remove = .leading
    let type : LineStyling
    var trimmed : Bool = true
    var changeAppliesTo : ChangeApplication = .current
}

public class SwiftyLineProcessor {
    
    let defaultType : LineStyling
    public var processEmptyStrings : LineStyling?
    let lineRules : [LineRule]
    
    public init( rules : [LineRule], defaultRule: LineStyling) {
        self.lineRules = rules
        self.defaultType = defaultRule
    }
    
    func findLeadingLineElement( _ element : LineRule, in string : String ) -> String {
        var output = string
        if let range = output.index(output.startIndex, offsetBy: element.token.count, limitedBy: output.endIndex), output[output.startIndex..<range] == element.token {
            output.removeSubrange(output.startIndex..<range)
            return output
        }
        return output
    }
    
    func findTrailingLineElement( _ element : LineRule, in string : String ) -> String {
        var output = string
        var token = element.token.trimmingCharacters(in: .whitespaces)
        if let range = output.index(output.endIndex, offsetBy: -(token.count), limitedBy: output.startIndex), output[range..<output.endIndex] == token {
            output.removeSubrange(range..<output.endIndex)
            return output
            
        }
        return output
    }
    
    func processLineLevelAttributes( _ text : String ) -> Line {
        if text.isEmpty, let style = processEmptyStrings {
            return Line(line: "", lineStyle: style)
        }
        let previousLines = lineRules.filter({ $0.changeAppliesTo == .previous })
        for element in previousLines {
            let output = (element.trimmed) ? text.trimmingCharacters(in: .whitespaces) : text
            let charSet = CharacterSet(charactersIn: element.token )
            if output.unicodeScalars.allSatisfy({ charSet.contains($0) }) {
                return Line(line: "", lineStyle: element.type)
            }
        }
        var rules = lineRules.filter({ $0.changeAppliesTo == .current })
        for element in lineRules {
            guard element.token.count > 0 else {
                continue
            }
            var output : String = (element.trimmed) ? text.trimmingCharacters(in: .whitespaces) : text
            var unprocessed = output
            
            switch element.removeFrom {
            case .leading:
                output = findLeadingLineElement(element, in: output)
            case .trailing:
                output = findTrailingLineElement(element, in: output)
            case .both:
                output = findLeadingLineElement(element, in: output)
                output = findTrailingLineElement(element, in: output)
            default:
                break
            }
            // Only if the output has changed in some way
            guard unprocessed != output else {
                continue
            }
            output = (element.trimmed) ? output.trimmingCharacters(in: .whitespaces) : output
            return Line(line: output, lineStyle: element.type)
            
        }
        
        return Line(line: text.trimmingCharacters(in: .whitespaces), lineStyle: defaultType)
    }
    
    public func process( _ string : String ) -> [Line] {
        var foundAttributes : [Line] = []
        for  heading in string.split(separator: "\n") {
            
            if processEmptyStrings == nil, heading.isEmpty {
                continue
            }
            
            let input : Line
            input = processLineLevelAttributes(String(heading))
            
            if let existentPrevious = input.lineStyle.styleIfFoundStyleAffectsPreviousLine(), foundAttributes.count > 0 {
                if let idx = foundAttributes.firstIndex(of: foundAttributes.last!) {
                    let updatedPrevious = foundAttributes.last!
                    foundAttributes[idx] = Line(line: updatedPrevious.line, lineStyle: existentPrevious)
                }
                continue
            }
            foundAttributes.append(input)
        }
        return foundAttributes
    }
    
}

let rules = [
    LineRule(token: "=", removeFrom: .entireLine, type: MarkdownLineStyle.previousH1, changeAppliesTo: .previous),
    LineRule(token: "-", removeFrom: .entireLine, type: MarkdownLineStyle.previousH2, changeAppliesTo: .previous),
    LineRule(token: "    ", removeFrom: .leading, type: MarkdownLineStyle.codeblock),
    LineRule(token: "\t", removeFrom: .leading, type: MarkdownLineStyle.codeblock),
    LineRule(token: ">",removeFrom: .leading, type : MarkdownLineStyle.blockquote),
    LineRule(token: "- ",removeFrom: .leading, type : MarkdownLineStyle.unorderedList),
    LineRule(token: "# ",removeFrom: .both, type : MarkdownLineStyle.h1),
    LineRule(token: "## ",removeFrom: .both, type : MarkdownLineStyle.h2),
    LineRule(token: "### ",removeFrom: .both, type : MarkdownLineStyle.h3),
    LineRule(token: "#### ",removeFrom: .both, type : MarkdownLineStyle.h4),
    LineRule(token: "##### ",removeFrom: .both, type : MarkdownLineStyle.h5),
    LineRule(token: "###### ",removeFrom: .both, type : MarkdownLineStyle.h6)
]


let lineProcesser = SwiftyLineProcessor(rules: rules, defaultRule: MarkdownLineStyle.body)
print(lineProcesser.process("#### Heading 4 ###").first?.line)

