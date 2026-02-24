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
/// Use the provided methods to drive the editor from native controls.
@MainActor
@Observable
public final class EditorContext {

    // MARK: - Internal

    /// Set by RichTextEditorView's coordinator once the WKWebView is created.
    weak var webView: WKWebView?

    // MARK: - Alert State (observed by RichTextEditorSheet)

    /// Set to `true` to present a link URL input alert.
    public var isLinkAlertPresented = false

    /// Set to `true` to present an image URL input alert.
    public var isImageAlertPresented = false

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

    public func toggleUnderline() {
        run("window.toggleUnderline()")
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

    // MARK: - Text Alignment

    public func setTextAlign(_ alignment: String) {
        let escaped = alignment
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        run("window.setTextAlign('\(escaped)')")
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
