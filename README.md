# SwiftUI-Formatted-Text
A simple proof-of-concept SwiftUI application that renders a HTML-like language using SwiftUI Text elements.

## Description
Goal of this project is to test the described proof-of-concept. In the moment both the parser and the renderer are fairly
buggy. The language used is closely related to HTML and those comfortable with HTML should also be comfortable with this
language. The string is parsed into an abstract sytnax tree consisting of `Tag` structs. The tree is then rendered to
SwiftUI native `Text` views.

## Use Cases
- Formatted localized strings
- Loading text from a database
- Allowing the user to format text in a certain way

## Syntax
### Tags
The following tags are implemented:
- `largeTitle` / `h1`
- `title` / `h2`
- `headline` / `h3`
- `subheadline` / `h4`
- `body`
- `callout` / `h5`
- `caption` / `h6`
- `footnote`
- `b`
- `i`
- `u`
- `br`
- `font`
  - Attributes:
    - `family`
    - `size`
    - `color`
  - `family` and `size` attributes both have to be present for them to have any effect
  - `color` can only be given using hex values i.e. `#ff0000` and `#ff0000aa`

Block elements like h1/h2/h3/h4/h5 are not implemented in the moment. Newlines can only be added using `\n` and `<br/>`

The XML-like parser is very rudimentary and does not follow any specs. Unlike in HTML every tag that was opened has to be
closed - this includes `<br/>`.
### 👉 This is just a proof-of-concept that should not be used in any application
