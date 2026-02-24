//
//  String+HTML.swift
//  TipTapSwift
//
//  Utilities for detecting and stripping HTML tags from strings.
//

import Foundation

// MARK: - Link Auto-Detection

extension String {
    /// Auto-detects the link type and returns a properly prefixed URL string.
    ///
    /// - Email: `hello@example.com` → `mailto:hello@example.com`
    /// - Phone: `+1234567890` or `(123) 456-7890` → `tel:+1234567890`
    /// - URL: `example.com` → `https://example.com`
    /// - Already prefixed values are returned as-is.
    public var autoDetectedLink: String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }

        // Already has a scheme
        if trimmed.contains("://") || trimmed.hasPrefix("mailto:") || trimmed.hasPrefix("tel:") {
            return trimmed
        }

        // Email: contains @ with a dot after it
        if trimmed.contains("@"),
           let atIndex = trimmed.firstIndex(of: "@"),
           trimmed[atIndex...].contains(".") {
            return "mailto:\(trimmed)"
        }

        // Phone: starts with + or digit, contains mostly digits/phone chars
        let digitsOnly = trimmed.filter(\.isWholeNumber)
        let phoneChars = CharacterSet(charactersIn: "0123456789+()-. /")
        let isAllPhoneChars = trimmed.unicodeScalars.allSatisfy(phoneChars.contains)
        let startsLikePhone = trimmed.first?.isWholeNumber == true || trimmed.hasPrefix("+") || trimmed.hasPrefix("(")
        if isAllPhoneChars && startsLikePhone && digitsOnly.count >= 6 {
            return "tel:\(trimmed)"
        }

        // URL: add https:// if missing
        if !trimmed.hasPrefix("http://") && !trimmed.hasPrefix("https://") {
            return "https://\(trimmed)"
        }

        return trimmed
    }
}

// MARK: - HTML Utilities

extension String {
    /// Returns `true` if the string contains HTML tags (e.g. `<p>`, `<strong>`).
    public var containsHTML: Bool {
        let pattern = "<[a-zA-Z][^>]*>"
        return range(of: pattern, options: .regularExpression) != nil
    }

    /// Returns the string with all HTML tags removed, suitable for plain-text previews.
    ///
    /// Multiple whitespace characters are collapsed into single spaces and
    /// leading/trailing whitespace is trimmed.
    public func strippingHTMLTags() -> String {
        guard containsHTML else { return self }
        let stripped = replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let collapsed = stripped.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
