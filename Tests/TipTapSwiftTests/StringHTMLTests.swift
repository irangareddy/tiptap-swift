import Testing
@testable import TipTapSwift

@Test func plainTextIsNotDetectedAsHTML() {
    let plain = "Hello, world!"
    #expect(!plain.containsHTML)
}

@Test func htmlTagsAreDetected() {
    let html = "<p>Hello <strong>world</strong></p>"
    #expect(html.containsHTML)
}

@Test func strippingRemovesAllTags() {
    let html = "<h1>Title</h1><p>Some <em>formatted</em> text.</p>"
    let stripped = html.strippingHTMLTags()
    // Adjacent tags without whitespace collapse together
    #expect(stripped == "TitleSome formatted text.")
}

@Test func strippingHandlesSpacedTags() {
    let html = "<h1>Title</h1> <p>Some text.</p>"
    let stripped = html.strippingHTMLTags()
    #expect(stripped == "Title Some text.")
}

@Test func strippingPlainTextReturnsItself() {
    let plain = "No tags here"
    #expect(plain.strippingHTMLTags() == plain)
}

@Test func strippingCollapsesWhitespace() {
    let html = "<p>Line one</p>\n\n<p>Line two</p>"
    let stripped = html.strippingHTMLTags()
    #expect(stripped == "Line one Line two")
}

// MARK: - autoDetectedLink Tests

@Test func detectsEmailAddress() {
    #expect("hello@example.com".autoDetectedLink == "mailto:hello@example.com")
    #expect("support@venue.co.uk".autoDetectedLink == "mailto:support@venue.co.uk")
}

@Test func detectsPhoneNumber() {
    #expect("+1234567890".autoDetectedLink == "tel:+1234567890")
    #expect("(123) 456-7890".autoDetectedLink == "tel:(123) 456-7890")
    #expect("123-456-7890".autoDetectedLink == "tel:123-456-7890")
    #expect("+91 98765 43210".autoDetectedLink == "tel:+91 98765 43210")
    #expect("9876543210".autoDetectedLink == "tel:9876543210")
    #expect("+1 (555) 123-4567".autoDetectedLink == "tel:+1 (555) 123-4567")
    #expect("044-12345678".autoDetectedLink == "tel:044-12345678")
}

@Test func detectsURLAndAddsHTTPS() {
    #expect("example.com".autoDetectedLink == "https://example.com")
    #expect("www.venue.com/tickets".autoDetectedLink == "https://www.venue.com/tickets")
}

@Test func preservesExistingScheme() {
    #expect("https://example.com".autoDetectedLink == "https://example.com")
    #expect("http://example.com".autoDetectedLink == "http://example.com")
    #expect("mailto:a@b.com".autoDetectedLink == "mailto:a@b.com")
    #expect("tel:+1234567890".autoDetectedLink == "tel:+1234567890")
}

@Test func handlesEmptyAndWhitespace() {
    #expect("".autoDetectedLink == "")
    #expect("  ".autoDetectedLink == "")
}
