import Foundation
import os

enum DeepLink: Equatable {
    case tab(Tab)
    case startRun(sessionId: String?)
    case morningReadiness
    case sharedRun(id: String)
    case crewTracking(sessionId: String)
    case raceDetail(raceId: String)
    case raceNutritionTimer(raceId: String)
    case referral(code: String)
}

@Observable
@MainActor
final class DeepLinkRouter {
    var pendingDeepLink: DeepLink?

    func handle(url: URL) -> Bool {
        if url.scheme == "ultratrain" {
            return handleCustomScheme(url: url)
        }

        if url.scheme == "https", url.host() == "ultratrain.app" {
            return handleUniversalLink(url: url)
        }

        return false
    }

    func consume() -> DeepLink? {
        let link = pendingDeepLink
        pendingDeepLink = nil
        return link
    }

    // MARK: - Private

    private func handleCustomScheme(url: URL) -> Bool {
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
        case "referral":
            let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "code" })?.value
            if let code, !code.isEmpty {
                pendingDeepLink = .referral(code: code)
            }
        default:
            return false
        }
        return true
    }

    private func handleUniversalLink(url: URL) -> Bool {
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard pathComponents.count >= 2 else { return false }

        let section = pathComponents[0]
        let identifier = pathComponents[1]
        guard !identifier.isEmpty else { return false }

        switch section {
        case "referral":
            pendingDeepLink = .referral(code: identifier)
        case "shared-runs":
            pendingDeepLink = .sharedRun(id: identifier)
        case "crew":
            pendingDeepLink = .crewTracking(sessionId: identifier)
        case "race":
            if pathComponents.count >= 3, pathComponents[2] == "nutrition" {
                pendingDeepLink = .raceNutritionTimer(raceId: identifier)
            } else {
                pendingDeepLink = .raceDetail(raceId: identifier)
            }
        default:
            return false
        }
        return true
    }
}
