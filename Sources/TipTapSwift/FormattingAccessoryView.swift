//
//  FormattingAccessoryView.swift
//  TipTapSwift
//
//  A native input accessory view with formatting buttons for the TipTap editor.
//  Appears above the keyboard when the WKWebView is focused.
//  UIKit glass background (works in keyboard window) + SwiftUI toolbar content.
//

import SwiftUI
import UIKit

// MARK: - SwiftUI Toolbar Content

private struct FormattingToolbar: View {
    let context: EditorContext

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 4) {
                    // 1. Text emphasis
                    iconButton("bold") { context.toggleBold() }
                    iconButton("italic") { context.toggleItalic() }
                    iconButton("underline") { context.toggleUnderline() }

                    // 2. Headings
                    textButton("H1") { context.toggleHeading(level: 1) }
                    textButton("H2") { context.toggleHeading(level: 2) }
                    textButton("H3") { context.toggleHeading(level: 3) }

                    // 3. Lists
                    iconButton("list.bullet") { context.toggleBulletList() }
                    iconButton("list.number") { context.toggleOrderedList() }

                    // 4. Links & Images
                    iconButton("link") { context.isLinkAlertPresented = true }
                    iconButton("photo") { context.isImageAlertPresented = true }

                    // 5. Alignment
                    iconButton("text.alignleft") { context.setTextAlign("left") }
                    iconButton("text.aligncenter") { context.setTextAlign("center") }
                    iconButton("text.alignright") { context.setTextAlign("right") }

                    // 6. Block formatting
                    iconButton("text.quote") { context.toggleBlockquote() }
                    iconButton("minus") { context.setHorizontalRule() }
                    iconButton("strikethrough") { context.toggleStrike() }
                }
                .padding(.horizontal, 6)
            }
            .scrollIndicatorsFlash(onAppear: true)

            Divider()
                .frame(height: 24)
                .padding(.leading, 6)
                .padding(.trailing, 4)

            Button {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 16, weight: .medium))
            }
            .tint(.primary)
            .padding(.trailing, 4)
        }
        .frame(height: 44)
    }

    private func iconButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
        }
        .tint(.primary)
        .frame(width: 34, height: 36)
    }

    private func textButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
        }
        .tint(.primary)
        .frame(width: 34, height: 36)
    }
}

// MARK: - UIKit Host

@MainActor
final class FormattingAccessoryView: UIInputView {

    private var hostingController: UIHostingController<FormattingToolbar>?

    init(context: EditorContext) {
        super.init(
            frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 52),
            inputViewStyle: .default
        )
        autoresizingMask = .flexibleWidth

        // Glass / material background (UIKit — renders reliably in keyboard window)
        let effectView: UIVisualEffectView
        if #available(iOS 26, *) {
            effectView = UIVisualEffectView(effect: UIGlassEffect())
        } else {
            effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        }
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.clipsToBounds = true
        effectView.layer.cornerRadius = 12
        effectView.layer.cornerCurve = .continuous
        addSubview(effectView)

        // SwiftUI toolbar content
        let hosting = UIHostingController(rootView: FormattingToolbar(context: context))
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        hosting.safeAreaRegions = []
        addSubview(hosting.view)

        NSLayoutConstraint.activate([
            // Glass background with 8pt padding
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            // SwiftUI content aligned to the glass area
            hosting.view.leadingAnchor.constraint(equalTo: effectView.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: effectView.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: effectView.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: effectView.bottomAnchor)
        ])

        hostingController = hosting
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
