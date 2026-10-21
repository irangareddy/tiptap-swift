import CryptoKit
import Foundation
import SwiftSoup
import Testing
import WebKit
@testable import TipTapSwift

private let sanitizationCases: [(String, String)] = [
    ("<script>alert(1)</script><p>Safe</p>", "<p>Safe</p>"),
    ("<img src='https://example.com/a' onerror='alert(1)'>", "<img src=\"https://example.com/a\" />"),
    ("<svg onload='alert(1)'><text>Hidden</text></svg>Safe", "Safe"),
    ("<meta http-equiv='refresh' content='0;url=https://example.com'>Safe", "Safe"),
    ("<a href='javascript:alert(1)'>Safe</a>", "Safe"),
    ("<a href='jav&#x61;script:alert(1)'>Safe</a>", "Safe"),
    ("<a href='java&#10;script:alert(1)'>Safe</a>", "Safe"),
    ("<a href=' java\tscript:alert(1) '>Safe</a>", "Safe"),
    ("<a href='data:text/html,hi'>Safe</a>", "Safe"),
    ("<a href='VBScript:msgbox(1)'>Safe</a>", "Safe"),
    ("<a href='//example.com'>Safe</a>", "Safe"),
    ("<a href='/relative'>Safe</a>", "Safe"),
    ("<iframe src='https://example.com'>Hidden</iframe>Safe", "Safe"),
    ("<form action='https://example.com'><p>Hidden</p><input></form>Safe", "Safe"),
    ("<p style='color:red' class='x' id='y' onclick='alert(1)'>Safe</p>", "<p>Safe</p>"),
    ("<style>body{display:none}</style>Safe", "Safe"),
    ("<object data='https://example.com'>Hidden</object>Safe", "Safe"),
    ("<embed src='https://example.com'>Safe", "Safe"),
    ("<button onclick='alert(1)'>Hidden</button>Safe", "Safe"),
    ("<math><mtext>Hidden</mtext></math>Safe", "Safe"),
    ("<template><p>Hidden</p></template>Safe", "Safe"),
    ("<noscript><p>Hidden</p></noscript>Safe", "Safe"),
    ("<link href='https://example.com'><base href='https://example.com'>Safe", "Safe"),
    ("<span style='color:red'><font face='x'><div>Safe</div></font></span>", "Safe"),
    ("<img src='http://example.com/a'>Safe", "Safe"),
    ("<img src='data:image/png;base64,AA=='>Safe", "Safe"),
    ("<img src='javascript:alert(1)'>Safe", "Safe"),
    ("<a href=' HTTPS://example.com ' target='_blank' ping='https://other.com'>Safe</a>", "<a href=\"HTTPS://example.com\">Safe</a>"),
    ("<a href='mailto:test@example.com'>Email</a>", "<a href=\"mailto:test@example.com\">Email</a>"),
    ("<a href='http://example.com'>Site</a>", "<a href=\"http://example.com\">Site</a>"),
    ("Hello, world!", "Hello, world!"),
    ("Hello  world\nNext line", "Hello  world\nNext line"),
    ("", ""),
    ("<!-- comment --><p>Safe</p>", "<p>Safe</p>"),
    ("<p><strong>Safe<script>bad()</script></strong></p>", "<p><strong>Safe</strong></p>"),
    ("<p><b>One<i>Two</b>Three</i>", "<p><b>One<i>Two</i></b><i>Three</i></p>"),
    ("<a href='java&#x09;script&colon;alert(1)'>Safe</a>", "Safe"),
    ("<img src='https://example.com/a' srcset='http://other.com/a' width='9' alt='x'>", "<img src=\"https://example.com/a\" />"),
    ("<p>Fish &amp; chips &lt;script&gt;</p>", "<p>Fish &amp; chips &lt;script&gt;</p>")
]

@Test(arguments: sanitizationCases)
func sanitizesDescription(input: String, expected: String) {
    #expect(RichTextSanitizer.sanitize(input) == expected)
}

@Test func preservesAllowedFormatting() {
    let html = "<h1>A</h1><h2>B</h2><h3>C</h3><h4>D</h4><p><strong>E</strong><b>F</b><em>G</em><i>H</i><u>I</u><s>J</s><br></p><ul><li>K</li></ul><ol><li>L</li></ol><blockquote>M</blockquote><pre><code>N</code></pre><hr>"
    #expect(RichTextSanitizer.sanitize(html) == html.replacingOccurrences(of: "<br>", with: "<br />").replacingOccurrences(of: "<hr>", with: "<hr />"))
}

@Test(arguments: [
    "<svg><p><style><img src=x onerror=alert(1)></style></p></svg>",
    "<math><mtext><table><mglyph><style><!--</style><img title='--><img src=x onerror=alert(1)>'>",
    "<p><a href='https://example.com' onclick='bad()'><iframe>hidden</iframe>Safe</a>",
    String(repeating: "<div>", count: 200) + "<script>bad()</script>" + String(repeating: "</div>", count: 200)
])
func malformedOutputRemainsAllowlistedAfterReparse(input: String) throws {
    let clean = RichTextSanitizer.sanitize(input)
    let reparsed = try SwiftSoup.parseBodyFragment(clean)
    #expect(try reparsed.select("script,style,svg,math,iframe,form,[onerror],[onload],[onclick]").isEmpty())
    #expect(RichTextSanitizer.sanitize(clean) == clean)
}

@MainActor @Test func cspHashMatchesExactEmbeddedHeightScript() throws {
    let html = HTMLContentView.wrapHTML("<p>Safe</p>", theme: "light")
    let document = try SwiftSoup.parse(html)
    let script = try #require(document.select("script").first()).data()
    let hash = Data(SHA256.hash(data: Data(script.utf8))).base64EncodedString()
    #expect(hash == HTMLContentView.heightScriptHash)
    let policy = try #require(document.select("meta[http-equiv=Content-Security-Policy]").first()).attr("content")
    #expect(policy == "default-src 'none'; style-src 'unsafe-inline'; img-src https: data:; font-src data:; script-src 'sha256-\(hash)'")
}

@Test func permitsOnlyOneAuthorizedMainFrameLoad() {
    var policy = HTMLNavigationPolicy()
    let blank = URL(string: "about:blank")
    #expect(policy.decide(url: blank, type: .other, isMainFrame: true) == .cancel)
    policy.beginLoad()
    #expect(policy.decide(url: blank, type: .other, isMainFrame: true) == .allow)
    #expect(policy.decide(url: blank, type: .other, isMainFrame: true) == .cancel)
    policy.beginLoad()
    #expect(policy.decide(url: blank, type: .other, isMainFrame: false) == .cancel)
    #expect(policy.decide(url: blank, type: .other, isMainFrame: true) == .cancel)
}

@Test(arguments: ["https://example.com", "http://example.com", "mailto:test@example.com"])
func approvedLinkTapsOpenExternally(value: String) throws {
    let url = try #require(URL(string: value))
    var policy = HTMLNavigationPolicy()
    #expect(policy.decide(url: url, type: .linkActivated, isMainFrame: true) == .external(url))
}

@Test(arguments: [WKNavigationType.other, .formSubmitted, .formResubmitted, .reload, .backForward])
func cancelsNonLinkNavigation(type: WKNavigationType) {
    var policy = HTMLNavigationPolicy()
    policy.beginLoad()
    #expect(policy.decide(url: URL(string: "https://example.com"), type: type, isMainFrame: true) == .cancel)
}

@Test(arguments: ["javascript:alert(1)", "data:text/html,hi", "vbscript:x", "file:///tmp/a", "about:blank", "gobeet://events/a"])
func cancelsUnapprovedLinkSchemes(value: String) {
    var policy = HTMLNavigationPolicy()
    #expect(policy.decide(url: URL(string: value), type: .linkActivated, isMainFrame: true) == .cancel)
}

import SwiftUI
import XCTest

@MainActor
final class HTMLWebViewTests: XCTestCase {
    func testSanitizedDocumentLoadsAndHeightScriptRunsUnderCSP() async throws {
        let heightReported = expectation(description: "Trusted height script runs")
        heightReported.assertForOverFulfill = false
        let recorder = HeightRecorder(expectation: heightReported)
        let config = WKWebViewConfiguration()
        config.userContentController.add(recorder, name: "heightChanged")
        config.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 200), configuration: config)
        let view = HTMLContentView(htmlContent: "", contentHeight: .constant(0))
        let coordinator = view.makeCoordinator()
        webView.navigationDelegate = coordinator
        coordinator.navigationPolicy.beginLoad()
        let content = RichTextSanitizer.sanitize("<p>Visible <strong>formatting</strong></p><script>window.untrustedRan=true</script>")
        webView.loadHTMLString(HTMLContentView.wrapHTML(content, theme: "light"), baseURL: nil)
        await fulfillment(of: [heightReported], timeout: 10)
        let text = try await webView.evaluateJavaScript("document.body.innerText") as? String
        XCTAssertEqual(text?.trimmingCharacters(in: .whitespacesAndNewlines), "Visible formatting")
        let untrusted = try await webView.evaluateJavaScript("window.untrustedRan === true") as? Bool
        XCTAssertEqual(untrusted, false)
        XCTAssertGreaterThan(recorder.height, 0)
        config.userContentController.removeScriptMessageHandler(forName: "heightChanged")
    }

    func testCSPBlocksUntrustedScriptEvenWithoutSanitizer() async throws {
        let heightReported = expectation(description: "Only trusted script runs")
        heightReported.assertForOverFulfill = false
        let config = WKWebViewConfiguration()
        let recorder = HeightRecorder(expectation: heightReported)
        config.userContentController.add(recorder, name: "heightChanged")
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 200), configuration: config)
        let html = HTMLContentView.wrapHTML("<p>Safe</p><script>window.untrustedRan=true</script>", theme: "light")
        webView.loadHTMLString(html, baseURL: nil)
        await fulfillment(of: [heightReported], timeout: 10)
        let untrusted = try await webView.evaluateJavaScript("window.untrustedRan === true") as? Bool
        XCTAssertEqual(untrusted, false)
        config.userContentController.removeScriptMessageHandler(forName: "heightChanged")
    }
}

@MainActor
private final class HeightRecorder: NSObject, WKScriptMessageHandler {
    let expectation: XCTestExpectation
    var height: CGFloat = 0
    init(expectation: XCTestExpectation) { self.expectation = expectation }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        height = message.body as? CGFloat ?? 0
        expectation.fulfill()
    }
}

// DS §18.11 allows tel: links (tap to call).
@Test func telLinksArePreserved() {
    let clean = RichTextSanitizer.sanitize("<p><a href=\"tel:+14155550100\">Call</a></p>")
    #expect(clean.contains("href=\"tel:+14155550100\""))
    #expect(RichTextSanitizer.vettedURL("tel:+14155550100") == "tel:+14155550100")
    #expect(RichTextSanitizer.vettedURL("javascript:alert(1)") == nil)
}

@Test func telLinkActivationOpensExternally() {
    var policy = HTMLNavigationPolicy()
    #expect(policy.decide(url: URL(string: "tel:+14155550100"), type: .linkActivated, isMainFrame: true)
        == .external(URL(string: "tel:+14155550100")!))
}
