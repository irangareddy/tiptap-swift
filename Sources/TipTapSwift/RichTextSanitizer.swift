import Foundation
import SwiftSoup

/// The render-time allowlist. Never returns the original input on a parsing failure.
enum RichTextSanitizer {
    private static let allowed: Set<String> = [
        "p", "br", "strong", "b", "em", "i", "u", "s", "h1", "h2", "h3", "h4",
        "ul", "ol", "li", "a", "blockquote", "code", "pre", "hr", "img"
    ]
    private static let removed: Set<String> = [
        "script", "style", "iframe", "frame", "frameset", "object", "embed", "form",
        "input", "button", "svg", "math", "template", "noscript", "meta", "link", "base",
        "head", "title", "textarea", "select", "applet"
    ]

    static func sanitize(_ html: String) -> String {
        do {
            let source = try SwiftSoup.parseBodyFragment(html)
            let output = Document.createShell("")
            output.outputSettings().prettyPrint(pretty: false)
            guard let body = source.body(), let clean = output.body() else { return "" }
            try copyChildren(from: body, to: clean, depth: 0)
            return try clean.html()
        } catch {
            return ""
        }
    }

    private static func copyChildren(from source: Node, to output: Element, depth: Int) throws {
        // Bound recursion; excess nesting is dropped rather than copied unchecked.
        guard depth < 128 else { return }
        for node in source.getChildNodes() {
            if let text = node as? TextNode {
                try output.appendChild(TextNode(text.getWholeText(), ""))
            } else if let element = node as? Element {
                let tag = element.tagName().lowercased()
                if removed.contains(tag) { continue }
                guard allowed.contains(tag) else {
                    try copyChildren(from: element, to: output, depth: depth + 1)
                    continue
                }
                let attribute = tag == "a" ? "href" : "src"
                let schemes: Set<String> = tag == "a" ? ["http", "https", "mailto"] : ["https"]
                let url = vettedURL(try element.attr(attribute), schemes: schemes)
                if tag == "img" && url == nil { continue }
                if tag == "a" && url == nil {
                    try copyChildren(from: element, to: output, depth: depth + 1)
                    continue
                }
                let clean = try output.appendElement(tag)
                if (tag == "a" || tag == "img"), let url {
                    try clean.attr(attribute, url)
                }
                try copyChildren(from: element, to: clean, depth: depth + 1)
            }
        }
    }

    static func vettedURL(_ value: String, schemes: Set<String> = ["http", "https", "mailto"]) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let colon = trimmed.firstIndex(of: ":"),
              schemes.contains(String(trimmed[..<colon]).lowercased()),
              !trimmed.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
              let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(),
              scheme == "mailto" || url.host?.isEmpty == false else { return nil }
        return trimmed
    }
}
