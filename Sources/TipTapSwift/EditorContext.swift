//
//  EditorContext.swift
//  TipTapSwift
//
//  Observable command channel for driving TipTap formatting from native SwiftUI.
//

import SwiftUI
import WebKit

/// A command channel that lets native SwiftUI controls trigger TipTap formatting.
///
/// ``RichTextEditorView`` populates the internal web view reference automatically.
/// Use the provided methods in a SwiftUI toolbar to drive the editor.
///
/// ```swift
/// @State private var context = EditorContext()
///
/// RichTextEditorView(htmlContent: $html, editorContext: context)
///     .toolbar {
///         ToolbarItemGroup(placement: .keyboard) {
///             Button { context.toggleBold() } label: { Image(systemName: "bold") }
///         }
///     }
/// ```
@MainActor
@Observable
public final class EditorContext {

    // MARK: - Internal

    /// Set by RichTextEditorView's coordinator once the WKWebView is created.
    weak var webView: WKWebView?

    public init() {}

    // MARK: - Inline Formatting

    public func toggleBold() {
        run("window.toggleBold()")
    }

    public func toggleItalic() {
        run("window.toggleItalic()")
    }

    public func toggleStrike() {
        run("window.toggleStrike()")
    }

    // MARK: - Block Formatting

    public func toggleHeading(level: Int) {
        run("window.toggleHeading(\(level))")
    }

    public func toggleBulletList() {
        run("window.toggleBulletList()")
    }

    public func toggleOrderedList() {
        run("window.toggleOrderedList()")
    }

    public func toggleBlockquote() {
        run("window.toggleBlockquote()")
    }

    public func toggleCodeBlock() {
        run("window.toggleCodeBlock()")
    }

    public func setHorizontalRule() {
        run("window.setHorizontalRule()")
    }

    // MARK: - Links

    public func setLink(url: String) {
        let escaped = url
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        run("window.setLink('\(escaped)')")
    }

    public func removeLink() {
        run("window.setLink(null)")
    }

    // MARK: - Images

    public func insertImage(url: String, alt: String = "") {
        let escapedURL = url
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        let escapedAlt = alt
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        run("window.setImage('\(escapedURL)', '\(escapedAlt)')")
    }

    // MARK: - Private

    private func run(_ js: String) {
        webView?.evaluateJavaScript(js) { _, _ in }
    }
}
