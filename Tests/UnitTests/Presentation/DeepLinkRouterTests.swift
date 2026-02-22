import Foundation
import Testing
@testable import UltraTrain

@Suite("DeepLinkRouter Tests")
struct DeepLinkRouterTests {

    @Test("Handles dashboard deep link")
    @MainActor
    func dashboardLink() {
        let router = DeepLinkRouter()
        let url = URL(string: "ultratrain://dashboard")!
        let handled = router.handle(url: url)
        #expect(handled)
        #expect(router.pendingDeepLink == .tab(.dashboard))
    }

    @Test("Handles plan deep link")
    @MainActor
    func planLink() {
        let router = DeepLinkRouter()
        let url = URL(string: "ultratrain://plan")!
        let handled = router.handle(url: url)
        #expect(handled)
        #expect(router.pendingDeepLink == .tab(.plan))
    }

    @Test("Handles run deep link without session ID")
    @MainActor
    func runLinkNoSession() {
        let router = DeepLinkRouter()
        let url = URL(string: "ultratrain://run")!
        let handled = router.handle(url: url)
        #expect(handled)
        #expect(router.pendingDeepLink == .startRun(sessionId: nil))
    }

    @Test("Handles run deep link with session ID")
    @MainActor
    func runLinkWithSession() {
        let router = DeepLinkRouter()
        let url = URL(string: "ultratrain://run?sessionId=abc123")!
        let handled = router.handle(url: url)
        #expect(handled)
        #expect(router.pendingDeepLink == .startRun(sessionId: "abc123"))
    }

    @Test("Handles nutrition deep link")
    @MainActor
    func nutritionLink() {
        let router = DeepLinkRouter()
        let url = URL(string: "ultratrain://nutrition")!
        let handled = router.handle(url: url)
        #expect(handled)
        #expect(router.pendingDeepLink == .tab(.nutrition))
    }

    @Test("Handles profile deep link")
    @MainActor
    func profileLink() {
        let router = DeepLinkRouter()
        let url = URL(string: "ultratrain://profile")!
        let handled = router.handle(url: url)
        #expect(handled)
        #expect(router.pendingDeepLink == .tab(.profile))
    }

    @Test("Handles readiness deep link")
    @MainActor
    func readinessLink() {
        let router = DeepLinkRouter()
        let url = URL(string: "ultratrain://readiness")!
        let handled = router.handle(url: url)
        #expect(handled)
        #expect(router.pendingDeepLink == .morningReadiness)
    }

    @Test("Rejects unknown URL scheme")
    @MainActor
    func unknownScheme() {
        let router = DeepLinkRouter()
        let url = URL(string: "https://example.com")!
        let handled = router.handle(url: url)
        #expect(!handled)
        #expect(router.pendingDeepLink == nil)
    }

    @Test("Rejects unknown host")
    @MainActor
    func unknownHost() {
        let router = DeepLinkRouter()
        let url = URL(string: "ultratrain://unknown")!
        let handled = router.handle(url: url)
        #expect(!handled)
        #expect(router.pendingDeepLink == nil)
    }

    @Test("Consume returns and clears pending deep link")
    @MainActor
    func consume() {
        let router = DeepLinkRouter()
        _ = router.handle(url: URL(string: "ultratrain://dashboard")!)
        let consumed = router.consume()
        #expect(consumed == .tab(.dashboard))
        #expect(router.pendingDeepLink == nil)
    }

    @Test("Consume returns nil when no pending link")
    @MainActor
    func consumeEmpty() {
        let router = DeepLinkRouter()
        let consumed = router.consume()
        #expect(consumed == nil)
    }

    @Test("New deep link overwrites previous pending link")
    @MainActor
    func overwritesPendingLink() {
        let router = DeepLinkRouter()
        _ = router.handle(url: URL(string: "ultratrain://dashboard")!)
        _ = router.handle(url: URL(string: "ultratrain://profile")!)
        #expect(router.pendingDeepLink == .tab(.profile))
    }
}
