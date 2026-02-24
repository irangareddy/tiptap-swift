//
//  FormattingAccessoryView.swift
//  TipTapSwift
//
//  A native UIKit input accessory view with formatting buttons for the TipTap editor.
//  Appears above the keyboard when the WKWebView is focused.
//

import UIKit

@MainActor
final class FormattingAccessoryView: UIInputView {

    private weak var context: EditorContext?

    init(context: EditorContext) {
        self.context = context
        super.init(
            frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44),
            inputViewStyle: .keyboard
        )
        autoresizingMask = .flexibleWidth
        setupButtons()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupButtons() {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -8),
            stack.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            stack.heightAnchor.constraint(equalToConstant: 36)
        ])

        // Inline formatting
        stack.addArrangedSubview(makeButton("bold", action: #selector(boldTapped)))
        stack.addArrangedSubview(makeButton("italic", action: #selector(italicTapped)))
        stack.addArrangedSubview(makeButton("strikethrough", action: #selector(strikeTapped)))
        stack.addArrangedSubview(makeSeparator())

        // Headings
        stack.addArrangedSubview(makeHeadingMenuButton())
        stack.addArrangedSubview(makeSeparator())

        // Lists
        stack.addArrangedSubview(makeButton("list.bullet", action: #selector(bulletListTapped)))
        stack.addArrangedSubview(makeButton("list.number", action: #selector(orderedListTapped)))
        stack.addArrangedSubview(makeSeparator())

        // Block formatting
        stack.addArrangedSubview(makeButton("text.quote", action: #selector(blockquoteTapped)))
        stack.addArrangedSubview(makeButton("minus", action: #selector(hrTapped)))
        stack.addArrangedSubview(makeSeparator())

        // Link & Image
        stack.addArrangedSubview(makeButton("link", action: #selector(linkTapped)))
        stack.addArrangedSubview(makeButton("photo", action: #selector(imageTapped)))
        stack.addArrangedSubview(makeSeparator())

        // Dismiss keyboard
        stack.addArrangedSubview(
            makeButton("keyboard.chevron.compact.down", action: #selector(dismissKeyboardTapped)))
    }

    // MARK: - Factory

    private func makeButton(_ systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 36),
            button.heightAnchor.constraint(equalToConstant: 36)
        ])
        return button
    }

    private func makeHeadingMenuButton() -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        button.setImage(
            UIImage(systemName: "textformat.size", withConfiguration: config), for: .normal)
        button.menu = UIMenu(children: [
            UIAction(title: "Heading 1", image: UIImage(systemName: "h1")) {
                [weak self] _ in self?.context?.toggleHeading(level: 1)
            },
            UIAction(title: "Heading 2", image: UIImage(systemName: "h2")) {
                [weak self] _ in self?.context?.toggleHeading(level: 2)
            },
            UIAction(title: "Heading 3", image: UIImage(systemName: "h3")) {
                [weak self] _ in self?.context?.toggleHeading(level: 3)
            }
        ])
        button.showsMenuAsPrimaryAction = true
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 36),
            button.heightAnchor.constraint(equalToConstant: 36)
        ])
        return button
    }

    private func makeSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 1),
            view.heightAnchor.constraint(equalToConstant: 20)
        ])
        return view
    }

    // MARK: - Actions

    @objc private func boldTapped() { context?.toggleBold() }
    @objc private func italicTapped() { context?.toggleItalic() }
    @objc private func strikeTapped() { context?.toggleStrike() }
    @objc private func bulletListTapped() { context?.toggleBulletList() }
    @objc private func orderedListTapped() { context?.toggleOrderedList() }
    @objc private func blockquoteTapped() { context?.toggleBlockquote() }
    @objc private func hrTapped() { context?.setHorizontalRule() }
    @objc private func linkTapped() { context?.isLinkAlertPresented = true }
    @objc private func imageTapped() { context?.isImageAlertPresented = true }

    @objc private func dismissKeyboardTapped() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
