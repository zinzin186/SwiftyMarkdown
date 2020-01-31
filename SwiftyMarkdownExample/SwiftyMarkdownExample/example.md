# Swifty Markdown

SwiftyMarkdown is a Swift-based *Markdown* parser that converts *Markdown* files or strings into **NSAttributedStrings**. It uses sensible defaults and supports dynamic type, even with custom fonts.

Show Images From Your App Bundle!
---
![Image](bubble)

Customise fonts and colors easily in a Swift-like way: 

    md.code.fontName = "CourierNewPSMT"

    md.h2.fontName = "AvenirNextCondensed-Medium"
    md.h2.color = UIColor.redColor()
    md.h2.alignment = .center

It supports the standard Markdown syntax, like *italics*, _underline italics_, **bold**, `backticks for code` and headings.

It ignores random * and correctly handles escaped \*asterisks\* and \_underlines\_ and \`backticks\`. It also supports inline Markdown [Links](http://voyagetravelapps.com/).

> It also now supports blockquotes
> and it supports whole-line italic and bold styles so you can go completely wild with styling! Wow! Such styles! Much fun!

**List**

- And
- Unordered
- Lists
	- Maybe an indented item?
- Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.






