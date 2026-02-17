import Foundation
@testable import UltraTrain

final class MockStravaAuthService: StravaAuthServiceProtocol, @unchecked Sendable {
    var authenticateCalled = false
    var disconnectCalled = false
    var shouldThrow = false
    var connected = false
    var athleteName: String? = "Test Athlete"

    func authenticate() async throws {
        authenticateCalled = true
        if shouldThrow { throw DomainError.stravaAuthFailed(reason: "Mock error") }
        connected = true
    }

    func disconnect() {
        disconnectCalled = true
        connected = false
        athleteName = nil
    }

    func getValidToken() async throws -> String {
        if shouldThrow { throw DomainError.stravaAuthFailed(reason: "Mock error") }
        guard connected else { throw DomainError.stravaAuthFailed(reason: "Not connected") }
        return "mock_access_token"
    }

    func isConnected() -> Bool {
        connected
    }

    func getConnectionStatus() -> StravaConnectionStatus {
        if let name = athleteName, connected {
            return .connected(athleteName: name)
        }
        return .disconnected
    }

    func getAthleteName() -> String? {
        connected ? athleteName : nil
    }
}
