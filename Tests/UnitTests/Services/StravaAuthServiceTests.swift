import Foundation
import Testing
@testable import UltraTrain

@Suite("StravaAuthService Tests")
struct StravaAuthServiceTests {

    // MARK: - Helpers

    private func makeMock(
        connected: Bool = false,
        athleteName: String? = "Test Runner",
        shouldThrow: Bool = false
    ) -> MockStravaAuthService {
        let mock = MockStravaAuthService()
        mock.connected = connected
        mock.athleteName = athleteName
        mock.shouldThrow = shouldThrow
        return mock
    }

    // MARK: - authenticate

    @Test("authenticate sets connected state to true")
    func authenticateSetsConnected() async throws {
        let service = makeMock(connected: false)

        try await service.authenticate()

        #expect(service.isConnected() == true)
        #expect(service.authenticateCalled == true)
    }

    @Test("authenticate throws when shouldThrow is set")
    func authenticateThrows() async {
        let service = makeMock(shouldThrow: true)

        await #expect(throws: DomainError.self) {
            try await service.authenticate()
        }
    }

    // MARK: - disconnect

    @Test("disconnect clears connected state and athlete name")
    func disconnectClearsState() {
        let service = makeMock(connected: true, athleteName: "John Doe")

        service.disconnect()

        #expect(service.isConnected() == false)
        #expect(service.disconnectCalled == true)
        #expect(service.getAthleteName() == nil)
    }

    // MARK: - getValidToken

    @Test("getValidToken returns token when connected")
    func getValidTokenWhenConnected() async throws {
        let service = makeMock(connected: true)

        let token = try await service.getValidToken()

        #expect(token == "mock_access_token")
    }

    @Test("getValidToken throws when not connected")
    func getValidTokenThrowsWhenDisconnected() async {
        let service = makeMock(connected: false)

        await #expect(throws: DomainError.self) {
            try await service.getValidToken()
        }
    }

    @Test("getValidToken throws when shouldThrow is set")
    func getValidTokenThrowsOnError() async {
        let service = makeMock(connected: true, shouldThrow: true)

        await #expect(throws: DomainError.self) {
            try await service.getValidToken()
        }
    }

    // MARK: - isConnected

    @Test("isConnected returns false by default")
    func isConnectedDefaultFalse() {
        let service = makeMock(connected: false)
        #expect(service.isConnected() == false)
    }

    @Test("isConnected returns true after authentication")
    func isConnectedTrueAfterAuth() async throws {
        let service = makeMock(connected: false)
        try await service.authenticate()
        #expect(service.isConnected() == true)
    }

    // MARK: - getConnectionStatus

    @Test("getConnectionStatus returns connected with athlete name")
    func connectionStatusConnected() {
        let service = makeMock(connected: true, athleteName: "Ultra Runner")

        let status = service.getConnectionStatus()

        #expect(status == .connected(athleteName: "Ultra Runner"))
    }

    @Test("getConnectionStatus returns disconnected when not connected")
    func connectionStatusDisconnected() {
        let service = makeMock(connected: false)

        let status = service.getConnectionStatus()

        #expect(status == .disconnected)
    }

    // MARK: - getAthleteName

    @Test("getAthleteName returns name when connected")
    func athleteNameWhenConnected() {
        let service = makeMock(connected: true, athleteName: "Trail Beast")

        #expect(service.getAthleteName() == "Trail Beast")
    }

    @Test("getAthleteName returns nil when disconnected")
    func athleteNameNilWhenDisconnected() {
        let service = makeMock(connected: false, athleteName: "Trail Beast")

        #expect(service.getAthleteName() == nil)
    }

    // MARK: - StravaToken model

    @Test("StravaToken isExpired returns false for future expiry")
    func tokenNotExpired() {
        let token = StravaToken(
            accessToken: "abc",
            refreshToken: "def",
            expiresAt: Date().addingTimeInterval(3600),
            athleteId: 123,
            athleteName: "Test"
        )
        #expect(token.isExpired == false)
    }

    @Test("StravaToken isExpired returns true for past expiry")
    func tokenExpired() {
        let token = StravaToken(
            accessToken: "abc",
            refreshToken: "def",
            expiresAt: Date().addingTimeInterval(-60),
            athleteId: 123,
            athleteName: "Test"
        )
        #expect(token.isExpired == true)
    }
}
