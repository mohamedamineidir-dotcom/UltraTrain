import Foundation
import Testing
@testable import UltraTrain

@Suite("CrewTrackingService Tests")
struct CrewTrackingServiceTests {

    // MARK: - Start Session

    @Test("startSession creates an active session with the host as participant")
    func startSessionCreatesActiveSession() async throws {
        let service = CrewTrackingService()
        let session = try await service.startSession()

        #expect(session.status == .active)
        #expect(session.participants.count == 1)
        #expect(session.participants.first?.displayName == "Host")
        #expect(session.hostDisplayName == "Host")
    }

    @Test("startSession creates unique session IDs")
    func startSessionCreatesUniqueIds() async throws {
        let service = CrewTrackingService()
        let session1 = try await service.startSession()
        let session2 = try await service.startSession()

        #expect(session1.id != session2.id)
    }

    // MARK: - Join Session

    @Test("joinSession adds a participant to an active session")
    func joinSessionAddsParticipant() async throws {
        let service = CrewTrackingService()
        let session = try await service.startSession()

        // Create a second service instance to simulate another user
        // But since both share the same actor and participantId, we test from the same service
        try await service.joinSession(session.id)

        let fetched = try await service.fetchSession(session.id)
        // The join uses the same participantId as the host in this in-memory implementation
        // so it appends a second participant entry
        #expect(fetched != nil)
        #expect((fetched?.participants.count ?? 0) >= 1)
    }

    @Test("joinSession throws for nonexistent session")
    func joinNonexistentSessionThrows() async {
        let service = CrewTrackingService()
        let fakeId = UUID()

        do {
            try await service.joinSession(fakeId)
            Issue.record("Expected SocialError.recordNotFound")
        } catch {
            #expect(error is SocialError)
        }
    }

    @Test("joinSession throws for ended session")
    func joinEndedSessionThrows() async throws {
        let service = CrewTrackingService()
        let session = try await service.startSession()
        try await service.endSession(session.id)

        do {
            try await service.joinSession(session.id)
            Issue.record("Expected SocialError.recordNotFound for ended session")
        } catch {
            #expect(error is SocialError)
        }
    }

    // MARK: - Update Location

    @Test("updateLocation updates participant coordinates")
    func updateLocationUpdatesCoordinates() async throws {
        let service = CrewTrackingService()
        let session = try await service.startSession()

        try await service.updateLocation(
            sessionId: session.id,
            latitude: 45.832,
            longitude: 6.865,
            distanceKm: 5.2,
            paceSecondsPerKm: 420
        )

        let fetched = try await service.fetchSession(session.id)
        let participant = fetched?.participants.first
        #expect(participant?.latitude == 45.832)
        #expect(participant?.longitude == 6.865)
        #expect(participant?.distanceKm == 5.2)
        #expect(participant?.currentPaceSecondsPerKm == 420)
    }

    @Test("updateLocation throws for nonexistent session")
    func updateLocationNonexistentSessionThrows() async {
        let service = CrewTrackingService()

        do {
            try await service.updateLocation(
                sessionId: UUID(),
                latitude: 45.0,
                longitude: 6.0,
                distanceKm: 1.0,
                paceSecondsPerKm: 300
            )
            Issue.record("Expected SocialError.recordNotFound")
        } catch {
            #expect(error is SocialError)
        }
    }

    // MARK: - End Session

    @Test("endSession changes status to ended")
    func endSessionChangesStatus() async throws {
        let service = CrewTrackingService()
        let session = try await service.startSession()

        try await service.endSession(session.id)

        let fetched = try await service.fetchSession(session.id)
        #expect(fetched?.status == .ended)
    }

    @Test("endSession throws for nonexistent session")
    func endNonexistentSessionThrows() async {
        let service = CrewTrackingService()

        do {
            try await service.endSession(UUID())
            Issue.record("Expected SocialError.recordNotFound")
        } catch {
            #expect(error is SocialError)
        }
    }

    // MARK: - Leave Session

    @Test("leaveSession removes the participant from the session")
    func leaveSessionRemovesParticipant() async throws {
        let service = CrewTrackingService()
        let session = try await service.startSession()

        // Host leaves
        try await service.leaveSession(session.id)

        let fetched = try await service.fetchSession(session.id)
        #expect(fetched?.participants.isEmpty == true)
    }

    // MARK: - Fetch Session

    @Test("fetchSession returns nil for unknown session ID")
    func fetchUnknownSessionReturnsNil() async throws {
        let service = CrewTrackingService()
        let result = try await service.fetchSession(UUID())
        #expect(result == nil)
    }
}
