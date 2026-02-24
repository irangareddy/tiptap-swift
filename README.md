# tiptap-swift

A Swift Package that brings the [TipTap](https://tiptap.dev) WYSIWYG rich text editor to iOS via WKWebView. Produces the same HTML output as the TipTap web editor, so content is fully compatible between your iOS and web apps.

## Features

- **WYSIWYG Editor** — Full formatting toolbar (headings, bold, italic, lists, blockquote, links, code blocks)
- **HTML In / HTML Out** — Bidirectional `@Binding var htmlContent: String`
- **Read-Only Renderer** — `HTMLContentView` for displaying HTML content with auto-sizing
- **Dark Mode** — Automatic light/dark theme via `@Environment(\.colorScheme)`
- **Ready-to-Use Sheet** — `RichTextEditorSheet` with Cancel/Done buttons
- **Zero Runtime Dependencies** — TipTap JS is pre-built and bundled as a local asset

## Requirements

- iOS 17.0+
- Swift 6.0+
- Xcode 16+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/irangareddy/tiptap-swift.git", from: "0.1.0")
]
```

Or in Xcode: **File > Add Package Dependencies** and paste the repository URL.

## Usage

### Editor (Read-Write)

```swift
import TipTapSwift

struct EditorView: View {
    @State private var html = ""

    var body: some View {
        RichTextEditorView(
            htmlContent: $html,
            placeholder: "Write something..."
        )
    }
}
```

### Editor Sheet

```swift
import TipTapSwift

struct MyView: View {
    @State private var description = ""
    @State private var showEditor = false

    var body: some View {
        Button("Edit Description") { showEditor = true }
            .sheet(isPresented: $showEditor) {
                RichTextEditorSheet(
                    htmlContent: $description,
                    title: "Event Description",
                    placeholder: "Describe your event..."
                )
            }
    }
}
```

### HTML Content Display (Read-Only)

```swift
import TipTapSwift

struct DetailView: View {
    let htmlDescription: String
    @State private var contentHeight: CGFloat = 100

    var body: some View {
        ScrollView {
            HTMLContentView(
                htmlContent: htmlDescription,
                contentHeight: $contentHeight
            )
            .frame(height: contentHeight)
        }
    }
}
```

### HTML Utilities

```swift
import TipTapSwift

let html = "<p>Hello <strong>world</strong></p>"
html.containsHTML           // true
html.strippingHTMLTags()    // "Hello world"
```

## TipTap Extensions Included

The pre-built JS bundle includes:

| Extension | Features |
|-----------|----------|
| **StarterKit** | Bold, Italic, Strike, Headings (H1–H3), Bullet List, Ordered List, Blockquote, Code Block, Horizontal Rule |
| **Link** | Clickable links with URL editing |
| **Placeholder** | Configurable placeholder text |

## Architecture

```
┌──────────────────────────────────────┐
│           SwiftUI View               │
│                                      │
│  RichTextEditorView / HTMLContentView│
│         (UIViewRepresentable)        │
├──────────────────────────────────────┤
│           WKWebView                  │
│  ┌────────────────────────────────┐  │
│  │  tiptap-editor.html            │  │
│  │  ├── tiptap-bundle.js (TipTap) │  │
│  │  └── tiptap-editor.css         │  │
│  └────────────────────────────────┘  │
├──────────────────────────────────────┤
│     JS ↔ Swift Bridge                │
│                                      │
│  JS → Swift (WKScriptMessageHandler) │
│  • contentChanged(html)              │
│  • editorReady()                     │
│  • editorHeightChanged(height)       │
│                                      │
│  Swift → JS (evaluateJavaScript)     │
│  • window.setContent(html)           │
│  • window.setTheme("dark"/"light")   │
│  • window.setEditable(bool)          │
│  • window.focus()                    │
└──────────────────────────────────────┘
```

## License

MIT License. See [LICENSE](LICENSE) for details.

TipTap is licensed under the [MIT License](https://github.com/ueberdosis/tiptap/blob/main/LICENSE.md).
