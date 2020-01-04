//
//  AttributedText.swift
//  SwiftUIRenderer
//
//  Created by Lukas Möller on 19.06.19.
//  Copyright © 2019 Lukas Möller. All rights reserved.
//

import SwiftUI
struct AttributedStringStyle {
    let font: Font?
    let weight: Font.Weight?
    let color: Color?
    let italic: Bool?
    let underline: Bool?
    let block: Bool?
    init(font: Font? = nil, weight: Font.Weight? = nil, color: Color? = nil, italic: Bool? = nil, underline: Bool? = nil, block: Bool? = nil) {
        self.font = font
        self.weight = weight
        self.color = color
        self.italic = italic
        self.underline = underline
        self.block = block
    }
    static var `default`: AttributedStringStyle {
        return AttributedStringStyle(font: nil, weight: nil, color: nil, italic: nil, underline: nil, block: nil)
    }
    func applying(partial: AttributedStringStyle) -> AttributedStringStyle{
        let font = partial.font ?? self.font
        let weight = partial.weight ?? self.weight
        let color = partial.color ?? self.color
        let italic = partial.italic ?? self.italic
        let underline = partial.underline ?? self.underline
        let block = partial.block ?? self.block
        return AttributedStringStyle(font: font, weight: weight, color: color, italic: italic, underline: underline, block: block)
    }
    func childVersion() -> AttributedStringStyle {
        let font = self.font
        let weight = self.weight
        let color = self.color
        let italic = self.italic
        let underline = self.underline
        let block = false
        return AttributedStringStyle(font: font, weight: weight, color: color, italic: italic, underline: underline, block: block)
    }
}
extension AttributedStringStyle: Equatable {
    
}
indirect enum Tag {
    case array([Tag])
    case font(style: AttributedStringStyle, child: Tag)
    case text(String)
    case newline
    func render(parentStyle: AttributedStringStyle? = nil) -> Text {
        let style = parentStyle ?? AttributedStringStyle.default
        switch self {
        case .array(let tags):
            return tags.map({$0.render(parentStyle: style)}).reduce(Text(""), +)
        case .font(let partial, let children):
            let newStyle = style.applying(partial: partial)
            let result = children.render(parentStyle: newStyle)
            //TODO: Properly handle block styling
            if let block = newStyle.block, block {
                return result
            } else {
                return result
            }
        case .text(let string):
            let components = string.components(separatedBy: NSCharacterSet.whitespacesAndNewlines)
            let sanitizedString = components.filter { !$0.isEmpty }.joined(separator: " ") + " "
            var node = Text(sanitizedString)
            var font: Font = style.font ?? .body
            if let italic = style.italic, italic {
                font = font.italic()
            }
            if let underline = style.underline, underline {
                node = node.underline()
            }
            
            node = node.font(font)
            if let fontWeight = style.weight {
                node = node.fontWeight(fontWeight)
            }
            if let color = style.color {
                node = node.foregroundColor(color)
            }
            return node
        case .newline:
            return Text("\n")
        }
    }
}
extension Tag: Equatable {
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        switch (lhs, rhs) {
        case (.array(let lhs), .array(let rhs)):
            return lhs == rhs
        case (.font(let lhsStyle, let lhsChild), .font(let rhsStyle, let rhsChild)):
            return lhsStyle == rhsStyle && lhsChild == rhsChild
        case (.text(let lhs), .text(let rhs)):
            return lhs == rhs
        case (.newline, .newline):
            return true
        default:
            return false
        }
    }
}
extension Tag {
    static func parse(from string: String) -> Tag {
        let entityMap: [String: String] = [
            "lt;": "<",
            "gt;": ">"
        ]
        let ws: Set<Character> = [" "]
        var index = string.startIndex
        func advance() {
            if eof() {
                return
            }
            index = string.index(after: index)
        }
        func current()-> Character {
            return string[index]
        }
        func peek()-> Character {
            return string[string.index(after: index)]
        }
        func eof() -> Bool {
            return index >= string.endIndex
        }
        func peekIsEof() -> Bool {
            return string.index(after: index) >= string.endIndex
        }
        func skipWhiteSpace() {
            while !eof() && ws.contains(current()) {
                advance()
            }
        }
        func parseEnclosedString() -> String? {
            guard !eof() && current() == "\"" else {
                return nil
            }
            advance()
            var buffer = ""
            while !eof() && current() != "\"" {
                buffer.append(current())
                advance()
            }
            guard !eof() && current() == "\"" else {
                return nil
            }
            advance()
            return buffer
        }
        func parseTag() -> Tag? {
            guard !eof() && current() == "<" else {
                return nil
            }
            advance()
            var tagName = ""
            var attributes: [String: String] = [:]
            while !eof() && !current().isWhitespace && current() != "/" && current() != ">"{
                tagName.append(current())
                advance()
            }
            //Parsing Attributes
            skipWhiteSpace()
            while !eof() && current() != ">" && current() != "/" {
                var attributeName = ""
                while !eof() && !current().isWhitespace && current() != "="{
                    attributeName.append(current())
                    advance()
                }
                advance()
                guard let value = parseEnclosedString() else {
                    return nil
                }
                attributes[attributeName] = value
                skipWhiteSpace()
            }
            var content: Tag? = nil
            if !eof() && current() == "/" {
                advance()
                guard !eof() && current() == ">" else {
                    return nil
                }
                advance()
            } else {
                guard !eof() && current() == ">" else {
                    return nil
                }
                advance()
                
                content = parse()
                
                guard !eof() && current() == "<" else {
                    return nil
                }
                advance()
                guard !eof() && current() == "/"  else {
                    return nil
                }
                advance()
                var closingtagName: String = ""
                while !eof() && !current().isWhitespace && current() != "/" && current() != ">"{
                    closingtagName.append(current())
                    advance()
                }
                guard closingtagName == tagName else {
                    return nil
                }
                guard !eof() && current() == ">" else {
                    return nil
                }
                advance()
            }
            
            switch tagName {
            case "largeTitle", "h1":
                guard let content = content else {
                    return nil
                }
                let style = AttributedStringStyle(font: .largeTitle, block: true)
                return .font(style: style, child: content)
            case "title", "h2":
                guard let content = content else {
                    return nil
                }
                let style = AttributedStringStyle(font: .title, block: true)
                return .font(style: style, child: content)
            case "headline", "h3":
                guard let content = content else {
                    return nil
                }
                let style = AttributedStringStyle(font: .headline, block: true)
                return .font(style: style, child: content)
            case "subheadline", "h4":
                guard let content = content else {
                    return nil
                }
                let style = AttributedStringStyle(font: .subheadline, block: true)
                return .font(style: style, child: content)
            case "body":
                guard let content = content else {
                    return nil
                }
                let style = AttributedStringStyle(font: .body)
                return .font(style: style, child: content)
            case "callout", "h5":
                guard let content = content else {
                    return nil
                }
                let style = AttributedStringStyle(font: .callout, block: true)
                return .font(style: style, child: content)
            case "caption", "h6":
                guard let content = content else {
                    return nil
                }
                let style = AttributedStringStyle(font: .caption, block: true)
                return .font(style: style, child: content)
            case "footnote":
                guard let content = content else {
                    return nil
                }
                let style = AttributedStringStyle(font: .footnote, block: true)
                return .font(style: style, child: content)
            case "b":
                guard let content = content else {
                    return nil
                }
                let style = AttributedStringStyle(weight: .bold)
                return .font(style: style, child: content)
            case "i":
                guard let content = content else {
                    return nil
                }
                let style = AttributedStringStyle(italic: true)
                return .font(style: style, child: content)
            case "u":
                guard let content = content else {
                    return nil
                }
                let style = AttributedStringStyle(underline: true)
                return .font(style: style, child: content)
            case "br":
                return .newline
            case "font":
                guard let content = content else {
                    return nil
                }
                var color: Color? = nil
                var font: Font? = nil
                if let hexString = attributes["color"] {
                    //Source: https://www.hackingwithswift.com/example-code/uicolor/how-to-convert-a-html-name-string-into-a-uicolor
                    var r: Double = 0.0
                    var g: Double = 0.0
                    var b: Double = 0.0
                    var a: Double = 0.0
                    
                    if hexString.hasPrefix("#") {
                        let start = hexString.index(hexString.startIndex, offsetBy: 1)
                        let hexColor = hexString[start...]
                        
                        if hexColor.count == 8 {
                            let scanner = Scanner(string: String(hexColor))
                            var hexNumber: UInt64 = 0
                            
                            if scanner.scanHexInt64(&hexNumber) {
                                r = Double((hexNumber & 0xff000000) >> 24) / 255
                                g = Double((hexNumber & 0x00ff0000) >> 16) / 255
                                b = Double((hexNumber & 0x0000ff00) >> 8) / 255
                                a = Double(hexNumber & 0x000000ff) / 255
                            }
                        }else if hexColor.count == 6 {
                            let scanner = Scanner(string: String(hexColor))
                            var hexNumber: UInt64 = 0
                            
                            if scanner.scanHexInt64(&hexNumber) {
                                r = Double((hexNumber & 0xff0000) >> 16) / 255
                                g = Double((hexNumber & 0x00ff00) >> 8) / 255
                                b = Double(hexNumber & 0x0000ff) / 255
                                a = 1.0
                            }
                        }
                    }
                    color = Color(.sRGBLinear, red: r, green: g, blue: b, opacity: a)
                }
                if let family = attributes["family"],
                    let sizeString = attributes["size"],
                    let size = NumberFormatter().number(from: sizeString)?.floatValue {
                    font = Font.custom(family, size: CGFloat(size))
                }
                let style = AttributedStringStyle(font: font, color: color)
                return .font(style: style, child: content)
            default:
                return content
            }
        }
        func parseUntilWhiteSpace() -> String {
            var buffer = ""
            while !eof() && !ws.contains(current()){
                buffer.append(current())
                advance()
            }
            return buffer
        }
        func parse() -> Tag {
            var array: [Tag] = []
            while !eof() {
                if current() == "<"{
                    if eof() || peekIsEof() ||  peek() == "/" {
                        break
                    }
                    if let tag = parseTag() {
                        array.append(tag)
                    }
                }else if current() == "&"{
                    advance()
                    let entity = parseUntilWhiteSpace()
                    array.append(.text(entityMap[entity] ?? ""))
                } else {
                    var buffer = ""
                    while !eof() && !["<", "&"].contains(current()){
                        buffer.append(current())
                        advance()
                    }
                    array.append(.text(buffer))
                }
            }
            return .array(array)
        }
        let result = parse()
        return result
    }
}

struct AttributedText : View {
    var formatted: String
    var renderedTag: some View {
        let result = Tag.parse(from: formatted).render()
        return result
    }
    var body: some View {
        VStack {
            renderedTag.lineLimit(nil)
        }
    }
}

#if DEBUG
struct AttributedText_Previews : PreviewProvider {
    static var previews: some View {
        AttributedText(formatted: "test")
    }
}
#endif
