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
