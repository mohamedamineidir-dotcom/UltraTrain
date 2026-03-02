import Foundation
@testable import UltraTrain

final class MockCrewTrackingService: CrewTrackingServiceProtocol, @unchecked Sendable {
    var startedSession: CrewTrackingSession?
    var joinedSessionId: UUID?
    var endedSessionId: UUID?
    var leftSessionId: UUID?
    var fetchedSessionId: UUID?
    var updatedLocation: (sessionId: UUID, lat: Double, lon: Double, dist: Double, pace: Double)?
    var sessionToReturn: CrewTrackingSession?
    var shouldThrow = false

    func startSession() async throws -> CrewTrackingSession {
        if shouldThrow { throw DomainError.networkUnavailable }
        let session = sessionToReturn ?? CrewTrackingSession(
            id: UUID(),
            hostProfileId: "host-1",
            hostDisplayName: "Host",
            startedAt: Date.now,
            status: .active,
            participants: []
        )
        startedSession = session
        return session
    }

    func joinSession(_ sessionId: UUID) async throws {
        if shouldThrow { throw DomainError.networkUnavailable }
        joinedSessionId = sessionId
    }

    func updateLocation(sessionId: UUID, latitude: Double, longitude: Double, distanceKm: Double, paceSecondsPerKm: Double) async throws {
        if shouldThrow { throw DomainError.networkUnavailable }
        updatedLocation = (sessionId, latitude, longitude, distanceKm, paceSecondsPerKm)
    }

    func fetchSession(_ sessionId: UUID) async throws -> CrewTrackingSession? {
        if shouldThrow { throw DomainError.networkUnavailable }
        fetchedSessionId = sessionId
        return sessionToReturn
    }

    func endSession(_ sessionId: UUID) async throws {
        if shouldThrow { throw DomainError.networkUnavailable }
        endedSessionId = sessionId
    }

    func leaveSession(_ sessionId: UUID) async throws {
        if shouldThrow { throw DomainError.networkUnavailable }
        leftSessionId = sessionId
    }
}
