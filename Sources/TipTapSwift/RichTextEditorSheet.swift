//
//  RichTextEditorSheet.swift
//  TipTapSwift
//
//  A ready-to-use sheet for editing HTML content with the TipTap editor.
//

import SwiftUI

/// A sheet that wraps ``RichTextEditorView`` with Cancel / Done toolbar buttons.
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
            }
        }
    }
}
