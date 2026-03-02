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

    // MARK: - Universal Link Tests

    @Test("Handles shared-runs universal link")
    @MainActor
    func sharedRunUniversalLink() {
        let router = DeepLinkRouter()
        let url = URL(string: "https://ultratrain.app/shared-runs/abc-123")!
        let handled = router.handle(url: url)
        #expect(handled)
        #expect(router.pendingDeepLink == .sharedRun(id: "abc-123"))
    }

    @Test("Handles crew universal link")
    @MainActor
    func crewUniversalLink() {
        let router = DeepLinkRouter()
        let url = URL(string: "https://ultratrain.app/crew/session-456")!
        let handled = router.handle(url: url)
        #expect(handled)
        #expect(router.pendingDeepLink == .crewTracking(sessionId: "session-456"))
    }

    @Test("Handles race universal link")
    @MainActor
    func raceUniversalLink() {
        let router = DeepLinkRouter()
        let url = URL(string: "https://ultratrain.app/race/race-789")!
        let handled = router.handle(url: url)
        #expect(handled)
        #expect(router.pendingDeepLink == .raceDetail(raceId: "race-789"))
    }

    @Test("Rejects unknown ultratrain.app path")
    @MainActor
    func unknownUniversalLinkPath() {
        let router = DeepLinkRouter()
        let url = URL(string: "https://ultratrain.app/unknown/123")!
        let handled = router.handle(url: url)
        #expect(!handled)
        #expect(router.pendingDeepLink == nil)
    }

    @Test("Rejects universal link with wrong domain")
    @MainActor
    func wrongDomain() {
        let router = DeepLinkRouter()
        let url = URL(string: "https://other.com/shared-runs/123")!
        let handled = router.handle(url: url)
        #expect(!handled)
        #expect(router.pendingDeepLink == nil)
    }

    @Test("Rejects universal link with missing identifier")
    @MainActor
    func missingIdentifier() {
        let router = DeepLinkRouter()
        let url = URL(string: "https://ultratrain.app/shared-runs")!
        let handled = router.handle(url: url)
        #expect(!handled)
        #expect(router.pendingDeepLink == nil)
    }

    @Test("Handles race nutrition timer universal link")
    @MainActor
    func raceNutritionTimerUniversalLink() {
        let router = DeepLinkRouter()
        let url = URL(string: "https://ultratrain.app/race/race-789/nutrition")!
        let handled = router.handle(url: url)
        #expect(handled)
        #expect(router.pendingDeepLink == .raceNutritionTimer(raceId: "race-789"))
    }

    @Test("Race link without nutrition subpath resolves to raceDetail")
    @MainActor
    func raceDetailNotNutrition() {
        let router = DeepLinkRouter()
        let url = URL(string: "https://ultratrain.app/race/race-789")!
        let handled = router.handle(url: url)
        #expect(handled)
        #expect(router.pendingDeepLink == .raceDetail(raceId: "race-789"))
    }

    @Test("Existing custom scheme links still work after universal link support")
    @MainActor
    func backwardCompatibility() {
        let router = DeepLinkRouter()
        let url = URL(string: "ultratrain://dashboard")!
        let handled = router.handle(url: url)
        #expect(handled)
        #expect(router.pendingDeepLink == .tab(.dashboard))
    }
}
