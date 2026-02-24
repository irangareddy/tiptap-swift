//
//  String+HTML.swift
//  TipTapSwift
//
//  Utilities for detecting and stripping HTML tags from strings.
//

import Foundation

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
