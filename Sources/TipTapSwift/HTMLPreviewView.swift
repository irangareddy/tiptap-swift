//
//  HTMLPreviewView.swift
//  TipTapSwift
//
//  A compact, non-interactive HTML preview for use in form fields.
//  Renders HTML content in a fixed-height WKWebView with tap pass-through.
//

import SwiftUI
import WebKit

/// A compact, non-interactive HTML preview for displaying rich text in form fields.
///
/// Unlike ``HTMLContentView``, this view disables user interaction so taps pass through
/// to parent controls (e.g. buttons). Use this in edit forms where tapping should open
/// an editor sheet rather than interact with the HTML content.
///
/// ```swift
/// Button {
///     showEditor = true
/// } label: {
///     HTMLPreviewView(htmlContent: description)
///         .frame(height: 80)
/// }
/// ```
public struct HTMLPreviewView: UIViewRepresentable {
    let htmlContent: String

    @Environment(\.colorScheme) private var colorScheme

    /// Creates a compact HTML preview.
    /// - Parameter htmlContent: The HTML string to render.
    public init(htmlContent: String) {
        self.htmlContent = htmlContent
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isUserInteractionEnabled = false

        context.coordinator.webView = webView
        context.coordinator.lastHTML = ""
        context.coordinator.lastTheme = ""
        loadContent(in: webView, coordinator: context.coordinator)

        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        loadContent(in: webView, coordinator: context.coordinator)
    }

    private func loadContent(in webView: WKWebView, coordinator: Coordinator) {
        let theme = colorScheme == .dark ? "dark" : "light"
        guard htmlContent != coordinator.lastHTML || theme != coordinator.lastTheme else { return }
        coordinator.lastHTML = htmlContent
        coordinator.lastTheme = theme
        let html = Self.wrapHTML(htmlContent, theme: theme)
        webView.loadHTMLString(html, baseURL: nil)
    }

    private static func wrapHTML(_ content: String, theme: String) -> String {
        """
        <!DOCTYPE html>
        <html data-theme="\(theme)">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
        :root {
            --text-color: #000000;
            --link-color: #007aff;
            --blockquote-border: #c6c6c8;
            --code-bg: #f2f2f7;
            --quote-color: #8e8e93;
            --font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', sans-serif;
        }
        [data-theme="dark"] {
            --text-color: #ffffff;
            --link-color: #0a84ff;
            --blockquote-border: #48484a;
            --code-bg: #2c2c2e;
            --quote-color: #636366;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body {
            background: transparent;
            color: var(--text-color);
            font-family: var(--font-family);
            font-size: 15px;
            line-height: 1.5;
            -webkit-text-size-adjust: 100%;
            overflow: hidden;
        }
        body { padding: 8px; }
        p { margin: 0 0 0.5em 0; }
        p:last-child { margin-bottom: 0; }
        h1 { font-size: 1.5em; font-weight: 700; margin: 0.5em 0 0.3em 0; line-height: 1.2; }
        h2 { font-size: 1.25em; font-weight: 600; margin: 0.4em 0 0.25em 0; line-height: 1.3; }
        h3 { font-size: 1.1em; font-weight: 600; margin: 0.35em 0 0.2em 0; line-height: 1.4; }
        h1:first-child, h2:first-child, h3:first-child { margin-top: 0; }
        strong { font-weight: 600; }
        a { color: var(--link-color); text-decoration: none; }
        ul, ol { padding-left: 1.25em; margin: 0.3em 0; }
        li { margin: 0.1em 0; }
        li p { margin: 0; }
        blockquote {
            border-left: 2px solid var(--blockquote-border);
            padding-left: 0.75em; margin: 0.4em 0;
            color: var(--quote-color);
        }
        pre {
            background: var(--code-bg); border-radius: 6px; padding: 8px;
            margin: 0.4em 0; overflow-x: auto;
            font-family: 'SF Mono', 'Menlo', monospace; font-size: 0.85em;
        }
        code {
            background: var(--code-bg); border-radius: 3px; padding: 0.1em 0.2em;
            font-family: 'SF Mono', 'Menlo', monospace; font-size: 0.85em;
        }
        pre code { background: none; padding: 0; }
        hr { border: none; border-top: 1px solid var(--blockquote-border); margin: 0.75em 0; }
        img { max-width: 100%; height: auto; max-height: 60px; object-fit: cover; border-radius: 4px; }
        </style>
        </head>
        <body>\(content)</body>
        </html>
        """
    }

    // MARK: - Coordinator

    public final class Coordinator: NSObject, @unchecked Sendable {
        var webView: WKWebView?
        var lastHTML = ""
        var lastTheme = ""
    }
}
