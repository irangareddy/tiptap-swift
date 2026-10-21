import Foundation
import WebKit

/// Each explicit loadHTMLString call authorizes one main-frame about:blank navigation.
struct HTMLNavigationPolicy {
    enum Decision: Equatable { case allow, external(URL), cancel }
    private var awaitingInitialLoad = false

    mutating func beginLoad() { awaitingInitialLoad = true }

    mutating func decide(url: URL?, type: WKNavigationType, isMainFrame: Bool) -> Decision {
        let initial = awaitingInitialLoad
        awaitingInitialLoad = false
        if initial, type == .other, isMainFrame, url?.absoluteString == "about:blank" {
            return .allow
        }
        if type == .linkActivated, let url,
           RichTextSanitizer.vettedURL(url.absoluteString) != nil {
            return .external(url)
        }
        return .cancel
    }
}
