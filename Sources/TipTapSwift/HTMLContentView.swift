//
//  HTMLContentView.swift
//  TipTapSwift
//
//  A read-only WKWebView for rendering HTML content produced by the TipTap editor.
//

import SwiftUI
import WebKit

/// Renders HTML content in a non-editable WKWebView with auto-sizing height.
///
/// Use this to display rich text descriptions that were created with ``RichTextEditorView``.
///
/// ```swift
/// @State private var height: CGFloat = 100
///
/// HTMLContentView(htmlContent: event.description, contentHeight: $height)
///     .frame(height: height)
/// ```
public struct HTMLContentView: UIViewRepresentable {
    let htmlContent: String
    @Binding var contentHeight: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    public init(htmlContent: String, contentHeight: Binding<CGFloat>) {
        self.htmlContent = htmlContent
        self._contentHeight = contentHeight
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.dataDetectorTypes = [.phoneNumber, .link, .address]
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "heightChanged")
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator

        context.coordinator.webView = webView
        loadContent(in: webView)

        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        loadContent(in: webView)
    }

    public static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "heightChanged")
        coordinator.webView = nil
    }

    private func loadContent(in webView: WKWebView) {
        let theme = colorScheme == .dark ? "dark" : "light"
        let html = Self.wrapHTML(htmlContent, theme: theme)
        webView.loadHTMLString(html, baseURL: nil)
    }

    // swiftlint:disable function_body_length
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
            --hr-color: #c6c6c8;
            --quote-color: #8e8e93;
            --font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', sans-serif;
        }
        [data-theme="dark"] {
            --text-color: #ffffff;
            --link-color: #0a84ff;
            --blockquote-border: #48484a;
            --code-bg: #2c2c2e;
            --hr-color: #48484a;
            --quote-color: #636366;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body {
            background: transparent;
            color: var(--text-color);
            font-family: var(--font-family);
            font-size: 16px;
            line-height: 1.6;
            -webkit-text-size-adjust: 100%;
        }
        body { padding: 0; }
        p { margin: 0 0 0.75em 0; }
        p:last-child { margin-bottom: 0; }
        h1 { font-size: 1.75em; font-weight: 700; margin: 1em 0 0.5em 0; line-height: 1.2; }
        h2 { font-size: 1.375em; font-weight: 600; margin: 0.875em 0 0.4em 0; line-height: 1.3; }
        h3 { font-size: 1.125em; font-weight: 600; margin: 0.75em 0 0.35em 0; line-height: 1.4; }
        h1:first-child, h2:first-child, h3:first-child { margin-top: 0; }
        strong { font-weight: 600; }
        a { color: var(--link-color); text-decoration: underline; text-underline-offset: 2px; }
        ul, ol { padding-left: 1.5em; margin: 0.5em 0; }
        li { margin: 0.2em 0; }
        li p { margin: 0; }
        blockquote {
            border-left: 3px solid var(--blockquote-border);
            padding-left: 1em; margin: 0.75em 0;
            color: var(--quote-color);
        }
        pre {
            background: var(--code-bg); border-radius: 8px; padding: 12px;
            margin: 0.75em 0; overflow-x: auto;
            font-family: 'SF Mono', 'Menlo', monospace; font-size: 0.875em;
        }
        code {
            background: var(--code-bg); border-radius: 4px; padding: 0.15em 0.3em;
            font-family: 'SF Mono', 'Menlo', monospace; font-size: 0.875em;
        }
        pre code { background: none; padding: 0; }
        hr { border: none; border-top: 1px solid var(--hr-color); margin: 1.5em 0; }
        img { max-width: 100%; height: auto; }
        </style>
        </head>
        <body>
        \(content)
        <script>
        function reportHeight() {
            var height = document.body.scrollHeight;
            window.webkit.messageHandlers.heightChanged.postMessage(height);
        }
        new ResizeObserver(reportHeight).observe(document.body);
        reportHeight();
        </script>
        </body>
        </html>
        """
    }
    // swiftlint:enable function_body_length

    // MARK: - Coordinator

    public final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, @unchecked Sendable {
        var parent: HTMLContentView
        var webView: WKWebView?

        init(_ parent: HTMLContentView) {
            self.parent = parent
        }

        public func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            if message.name == "heightChanged", let height = message.body as? CGFloat {
                Task { @MainActor in
                    self.parent.contentHeight = height
                }
            }
        }

        @MainActor
        public func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                await UIApplication.shared.open(url)
                return .cancel
            } else {
                return .allow
            }
        }
    }
}
