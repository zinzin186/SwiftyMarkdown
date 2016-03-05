# SwiftyMarkdown

SwiftyMarkdown converts Markdown files and strings into NSAttributedString using sensible defaults and a Swift-style syntax. It uses dynamic type to set the font size for whatever font you want

## Usage

Text string

	let md = SwiftyMarkdown(string: "# Heading\nMy *Markdown* string")
	md.attributedString()

URL 


	if let url = NSBundle.mainBundle().URLForResource("file", withExtension: "md"), md = SwiftyMarkdown(url: url ) {
		md.attributedString()
	}

## Customisation 

	// Setting the body name will use this font for all the heading styles as well, unless explicitly overridden
	md.body.fontName = "AvenirNextCondensed-Medium"

	md.h1.color = UIColor.redColor()
	md.h1.fontName = "AvenirNextCondensed-Bold"

