# SwiftyMarkdown 1.0

SwiftyMarkdown converts Markdown files and strings into `NSAttributedString`s using sensible defaults and a Swift-style syntax. It uses dynamic type to set the font size correctly with whatever font you'd like to use.

## Fully Rebuilt For 2020!

SwiftyMarkdown now features a more robust and reliable rules-based line processing and tokenisation engine. It has added support for images stored in the bundle (`![Image](<Name In bundle>)`), codeblocks, blockquotes, and unordered lists!

Line-level attributes can now have a paragraph alignment applied to them (e.g. `h2.aligment = .center`), and links can be underlined by setting underlineLinks to `true`. 

It also uses the system color `.label` as the default font color on iOS 13 and above for Dark Mode support out of the box. 

## Installation

### CocoaPods:

`pod 'SwiftyMarkdown'`

### SPM: 

In Xcode, `File -> Swift Packages -> Add Package Dependency` and add the GitHub URL. 

## Usage

Text string

```swift
let md = SwiftyMarkdown(string: "# Heading\nMy *Markdown* string")
md.attributedString()
```

URL 

```swift
if let url = Bundle.main.url(forResource: "file", withExtension: "md"), md = SwiftyMarkdown(url: url ) {
	md.attributedString()
}
```

## Supported Markdown Features

    *italics* or _italics_
    **bold** or __bold__

    # Header 1
    ## Header 2
    ### Header 3
    #### Header 4
    ##### Header 5
    ###### Header 6
    
    `code`
    [Links](http://voyagetravelapps.com/)
    ![Images](<Name of asset in bundle>)
    
    > Blockquotes
		
		Indented code blocks


## Customisation 
```swift
md.body.fontName = "AvenirNextCondensed-Medium"

md.h1.color = UIColor.redColor()
md.h1.fontName = "AvenirNextCondensed-Bold"
md.h1.fontSize = 16
md.h1.alignmnent = .center

md.italic.color = UIColor.blueColor()

md.underlineLinks = true
```

## Screenshot

![Screenshot](http://f.cl.ly/items/12332k3f2s0s0C281h2u/swiftymarkdown.png)

## Advanced Customisation

SwiftyMarkdown uses a rules-based line processing and customisation engine that is no longer limited to Markdown. Rules are processed in order, from top to bottom. Line processing happens first, then character styles are applied based on the character rules. 

For example, here's how a small subset of Markdown line tags are set up within SwiftyMarkdown:

	enum MarkdownLineStyle : LineStyling {
		case h1
		case h2
		case previousH1
		case codeblock
		case body
		
		var shouldTokeniseLine: Bool {
			switch self {
			case .codeblock:
				return false
			default:
				return true
			}
		}
		
		func styleIfFoundStyleAffectsPreviousLine() -> LineStyling? {
			switch self {
			case .previousH1:
				return MarkdownLineStyle.h1
			default :
				return nil
			}
		}
	}

	static let lineRules = [
		LineRule(token: "    ",type : MarkdownLineStyle.codeblock, removeFrom: .leading),
		LineRule(token: "=",type : MarkdownLineStyle.previousH1, removeFrom: .entireLine, changeAppliesTo: .previous),
		LineRule(token: "## ",type : MarkdownLineStyle.h2, removeFrom: .both),
		LineRule(token: "# ",type : MarkdownLineStyle.h1, removeFrom: .both)
	]
	
	let lineProcessor = SwiftyLineProcessor(rules: SwiftyMarkdown.lineRules, default: MarkdownLineStyle.body)
	
Similarly, the character styles all follow rules:
	
	enum CharacterStyle : CharacterStyling {
		case link, bold, italic, code
	}
	
	static let characterRules = [
		CharacterRule(openTag: "[", intermediateTag: "](", closingTag: ")", escapeCharacter: "\\", styles: [1 : [CharacterStyle.link]], maxTags: 1),
		CharacterRule(openTag: "`", intermediateTag: nil, closingTag: nil, escapeCharacter: "\\", styles: [1 : [CharacterStyle.code]], maxTags: 1),
		CharacterRule(openTag: "*", intermediateTag: nil, closingTag: nil, escapeCharacter: "\\", styles: [1 : [CharacterStyle.italic], 2 : [CharacterStyle.bold], 3 : [CharacterStyle.bold, CharacterStyle.italic]], maxTags: 3),
		CharacterRule(openTag: "_", intermediateTag: nil, closingTag: nil, escapeCharacter: "\\", styles: [1 : [CharacterStyle.italic], 2 : [CharacterStyle.bold], 3 : [CharacterStyle.bold, CharacterStyle.italic]], maxTags: 3)
	]

If you wanted to create a rule that applied a style of `Elf` to a range of characters between "The elf will speak now: %Here is my elf speaking%", you could set things up like this:

	enum Characters : CharacterStyling {
		case elf
	}
	
	let characterRules = [
		CharacterRule(openTag: "%", intermediateTag: nil, closingTag: nil, escapeCharacter: "\\", styles: [1 : [CharacterStyle.elf]], maxTags: 1)
	]
	
	let processor = SwiftyTokeniser( with : characterRules )
	let string = "The elf will speak now: %Here is my elf speaking%"
	let tokens = processor.process(string)

The output is an array of tokens would be equivalent to:

	[
		Token(type: .string, inputString: "The elf will speak now: ", characterStyles: []),
		Token(type: .openTag, inputString: "%", characterStyles: []),
		Token(type: .string, inputString: "Here is my elf speaking", characterStyles: [.elf]),
		Token(type: .openTag, inputString: "%", characterStyles: [])
	]



