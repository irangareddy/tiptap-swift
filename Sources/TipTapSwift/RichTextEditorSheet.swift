//
//  RichTextEditorSheet.swift
//  TipTapSwift
//
//  A ready-to-use sheet for editing HTML content with the TipTap editor.
//

import SwiftUI

/// A sheet that wraps ``RichTextEditorView`` with Cancel / Done toolbar buttons
/// and a native SwiftUI keyboard toolbar for formatting.
///
/// Works on a local copy of the content and only commits changes on "Done".
///
/// ```swift
/// .sheet(isPresented: $showEditor) {
///     RichTextEditorSheet(htmlContent: $description)
/// }
/// ```
public struct RichTextEditorSheet: View {
    @Binding var htmlContent: String
    @Environment(\.dismiss) private var dismiss

    @State private var localContent: String
    @State private var isEditorReady = false
    @State private var editorContext = EditorContext()
    @State private var showLinkAlert = false
    @State private var showImageAlert = false
    @State private var linkURL = ""
    @State private var imageURL = ""

    private let title: String
    private let placeholder: String

    /// Creates a rich text editor sheet.
    /// - Parameters:
    ///   - htmlContent: Binding to the HTML string to edit.
    ///   - title: Navigation bar title.
    ///   - placeholder: Placeholder shown when editor is empty.
    public init(
        htmlContent: Binding<String>,
        title: String = "Description",
        placeholder: String = "Start typing..."
    ) {
        self._htmlContent = htmlContent
        self._localContent = State(initialValue: htmlContent.wrappedValue)
        self.title = title
        self.placeholder = placeholder
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                RichTextEditorView(
                    htmlContent: $localContent,
                    placeholder: placeholder,
                    editorContext: editorContext,
                    onEditorReady: {
                        withAnimation(.easeIn(duration: 0.2)) {
                            isEditorReady = true
                        }
                    }
                )
                .opacity(isEditorReady ? 1 : 0)

                if !isEditorReady {
                    ProgressView("Loading editor...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") {
                        htmlContent = localContent
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    formattingToolbar
                }
            }
            .alert("Add Link", isPresented: $showLinkAlert) {
                TextField("https://example.com", text: $linkURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                Button("Add") {
                    if !linkURL.isEmpty {
                        editorContext.setLink(url: linkURL)
                    }
                    linkURL = ""
                }
                Button("Remove Link", role: .destructive) {
                    editorContext.removeLink()
                    linkURL = ""
                }
                Button("Cancel", role: .cancel) {
                    linkURL = ""
                }
            }
            .alert("Add Image", isPresented: $showImageAlert) {
                TextField("https://example.com/image.jpg", text: $imageURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                Button("Insert") {
                    if !imageURL.isEmpty {
                        editorContext.insertImage(url: imageURL)
                    }
                    imageURL = ""
                }
                Button("Cancel", role: .cancel) {
                    imageURL = ""
                }
            }
        }
    }

    @ViewBuilder
    private var formattingToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Inline formatting
                Button { editorContext.toggleBold() } label: {
                    Image(systemName: "bold")
                }
                Button { editorContext.toggleItalic() } label: {
                    Image(systemName: "italic")
                }
                Button { editorContext.toggleStrike() } label: {
                    Image(systemName: "strikethrough")
                }

                Divider().frame(height: 20)

                // Headings
                Menu {
                    Button("Heading 1") { editorContext.toggleHeading(level: 1) }
                    Button("Heading 2") { editorContext.toggleHeading(level: 2) }
                    Button("Heading 3") { editorContext.toggleHeading(level: 3) }
                } label: {
                    Image(systemName: "textformat.size")
                }

                Divider().frame(height: 20)

                // Lists
                Button { editorContext.toggleBulletList() } label: {
                    Image(systemName: "list.bullet")
                }
                Button { editorContext.toggleOrderedList() } label: {
                    Image(systemName: "list.number")
                }

                Divider().frame(height: 20)

                // Block formatting
                Button { editorContext.toggleBlockquote() } label: {
                    Image(systemName: "text.quote")
                }
                Button { editorContext.toggleCodeBlock() } label: {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                }
                Button { editorContext.setHorizontalRule() } label: {
                    Image(systemName: "minus")
                }

                Divider().frame(height: 20)

                // Link & Image
                Button { showLinkAlert = true } label: {
                    Image(systemName: "link")
                }
                Button { showImageAlert = true } label: {
                    Image(systemName: "photo")
                }

                Divider().frame(height: 20)

                // Dismiss keyboard
                Button {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
            }
            .imageScale(.large)
        }
    }
}
