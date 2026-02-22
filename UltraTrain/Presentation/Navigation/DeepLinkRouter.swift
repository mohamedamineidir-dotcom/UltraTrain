import Foundation
import os

enum DeepLink: Equatable {
    case tab(Tab)
    case startRun(sessionId: String?)
    case morningReadiness
}

@Observable
@MainActor
final class DeepLinkRouter {
    var pendingDeepLink: DeepLink?

    func handle(url: URL) -> Bool {
        guard url.scheme == "ultratrain" else { return false }
        let host = url.host()

        switch host {
        case "dashboard":
            pendingDeepLink = .tab(.dashboard)
        case "plan":
            pendingDeepLink = .tab(.plan)
        case "run":
            let sessionId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "sessionId" })?.value
            pendingDeepLink = .startRun(sessionId: sessionId)
        case "nutrition":
            pendingDeepLink = .tab(.nutrition)
        case "profile":
            pendingDeepLink = .tab(.profile)
        case "runHistory":
            pendingDeepLink = .tab(.run)
        case "readiness":
            pendingDeepLink = .morningReadiness
        default:
            return false
        }
        return true
    }

    func consume() -> DeepLink? {
        let link = pendingDeepLink
        pendingDeepLink = nil
        return link
    }
}
