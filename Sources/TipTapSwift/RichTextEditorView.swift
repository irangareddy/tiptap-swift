//
//  RichTextEditorView.swift
//  TipTapSwift
//
//  A SwiftUI view wrapping WKWebView with a full TipTap WYSIWYG editor.
//  Communicates bidirectionally with the TipTap JS bundle via WKScriptMessageHandler.
//

import SwiftUI
import WebKit

/// A WYSIWYG rich text editor powered by TipTap, rendered inside a WKWebView.
///
/// Use this view when you need full rich text editing.
/// Content is stored as HTML.
///
/// ```swift
/// @State private var html = ""
/// @State private var context = EditorContext()
///
/// RichTextEditorView(htmlContent: $html, editorContext: context)
/// ```
public struct RichTextEditorView: UIViewRepresentable {
    @Binding var htmlContent: String
    var placeholder: String
    var editorContext: EditorContext?
    var onEditorReady: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    /// Creates a rich text editor.
    /// - Parameters:
    ///   - htmlContent: Bidirectional binding to the HTML content string.
    ///   - placeholder: Placeholder text shown when the editor is empty.
    ///   - editorContext: Optional context for driving formatting from native controls.
    ///   - onEditorReady: Called once the TipTap editor has fully initialized.
    public init(
        htmlContent: Binding<String>,
        placeholder: String = "Start typing...",
        editorContext: EditorContext? = nil,
        onEditorReady: (() -> Void)? = nil
    ) {
        self._htmlContent = htmlContent
        self.placeholder = placeholder
        self.editorContext = editorContext
        self.onEditorReady = onEditorReady
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()

        contentController.add(context.coordinator, name: "contentChanged")
        contentController.add(context.coordinator, name: "editorReady")
        contentController.add(context.coordinator, name: "editorHeightChanged")

        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        webView.navigationDelegate = context.coordinator

        context.coordinator.webView = webView
        editorContext?.webView = webView

        // Install native formatting toolbar as the keyboard input accessory
        if let editorContext {
            let accessoryView = FormattingAccessoryView(context: editorContext)
            context.coordinator.accessoryView = accessoryView
            Self.installInputAccessoryView(accessoryView, on: webView)
        }

        if let resourceURL = Bundle.module.url(
            forResource: "tiptap-editor",
            withExtension: "html",
            subdirectory: "RichTextEditor"
        ) {
            let directory = resourceURL.deletingLastPathComponent()
            webView.loadFileURL(resourceURL, allowingReadAccessTo: directory)
        }

        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator

        // Keep editor context wired to the current webView
        editorContext?.webView = webView

        // Update theme when color scheme changes
        let theme = colorScheme == .dark ? "dark" : "light"
        if coordinator.currentTheme != theme {
            coordinator.currentTheme = theme
            webView.evaluateJavaScript("window.setTheme('\(theme)')") { _, _ in }
        }

        // Only push content changes originating from Swift (not echoed JS changes)
        if htmlContent != coordinator.lastContentFromJS && coordinator.isEditorReady {
            let escaped = Self.escapeForJS(htmlContent)
            webView.evaluateJavaScript("window.setContent('\(escaped)')") { _, _ in }
        }
    }

    public static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "contentChanged")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "editorReady")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "editorHeightChanged")
        coordinator.webView = nil
        coordinator.accessoryView = nil
    }

    // MARK: - Helpers

    static func escapeForJS(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }

    // MARK: - Input Accessory View Installation

    /// Replaces WKWebView's default input accessory view by dynamically subclassing WKContentView.
    /// This is the standard approach used by production rich text editors on iOS.
    private static func installInputAccessoryView(_ accessoryView: UIView, on webView: WKWebView) {
        // Find WKContentView — the internal UIResponder that becomes first responder on keyboard input
        guard let contentView = webView.scrollView.subviews.first(where: {
            NSStringFromClass(type(of: $0)).hasPrefix("WKContent")
        }) else { return }

        let contentViewClass: AnyClass = type(of: contentView)
        let customClassName = "_TipTapContent_\(UInt(bitPattern: ObjectIdentifier(contentView)))"

        let customClass: AnyClass
        if let existingClass = objc_lookUpClass(customClassName) {
            customClass = existingClass
        } else {
            guard let newClass = objc_allocateClassPair(contentViewClass, customClassName, 0) else { return }

            let selector = #selector(getter: UIResponder.inputAccessoryView)
            guard let method = class_getInstanceMethod(UIResponder.self, selector) else { return }
            let typeEncoding = method_getTypeEncoding(method)

            let block: @convention(block) (AnyObject) -> UIView? = { [weak accessoryView] _ in
                accessoryView
            }
            let imp = imp_implementationWithBlock(block)
            class_addMethod(newClass, selector, imp, typeEncoding)
            objc_registerClassPair(newClass)
            customClass = newClass
        }

        object_setClass(contentView, customClass)
    }

    // MARK: - Coordinator

    public final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, @unchecked Sendable {
        var parent: RichTextEditorView
        var webView: WKWebView?
        var accessoryView: FormattingAccessoryView?
        var lastContentFromJS: String = ""
        var isEditorReady = false
        var currentTheme: String?
        private var pendingContent: String?
        private var pendingPlaceholder: String

        init(_ parent: RichTextEditorView) {
            self.parent = parent
            self.pendingPlaceholder = parent.placeholder
            if !parent.htmlContent.isEmpty {
                self.pendingContent = parent.htmlContent
            }
        }

        public func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            switch message.name {
            case "contentChanged":
                if let html = message.body as? String {
                    lastContentFromJS = html
                    Task { @MainActor in
                        self.parent.htmlContent = html
                    }
                }

            case "editorReady":
                isEditorReady = true

                let theme = parent.colorScheme == .dark ? "dark" : "light"
                currentTheme = theme
                webView?.evaluateJavaScript("window.setTheme('\(theme)')") { _, _ in }

                if let content = pendingContent, !content.isEmpty {
                    let escaped = RichTextEditorView.escapeForJS(content)
                    webView?.evaluateJavaScript("window.setContent('\(escaped)')") { _, _ in }
                    pendingContent = nil
                }

                Task { @MainActor in
                    self.parent.onEditorReady?()
                }

            case "editorHeightChanged":
                break

            default:
                break
            }
        }

        public func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            if navigationAction.navigationType == .other || navigationAction.request.url?.isFileURL == true {
                return .allow
            } else {
                return .cancel
            }
        }
    }
}
