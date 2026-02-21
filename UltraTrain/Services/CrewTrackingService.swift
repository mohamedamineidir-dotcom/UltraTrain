import Foundation
import os

actor CrewTrackingService: CrewTrackingServiceProtocol {

    // MARK: - In-Memory Storage

    private var sessions: [UUID: CrewTrackingSession] = [:]
    private var myParticipantId: String = UUID().uuidString

    // MARK: - Start Session

    func startSession() async throws -> CrewTrackingSession {
        let sessionId = UUID()
        let session = CrewTrackingSession(
            id: sessionId,
            hostProfileId: myParticipantId,
            hostDisplayName: "Host",
            startedAt: Date.now,
            status: .active,
            participants: [
                CrewParticipant(
                    id: myParticipantId,
                    displayName: "Host",
                    latitude: 0,
                    longitude: 0,
                    distanceKm: 0,
                    currentPaceSecondsPerKm: 0,
                    lastUpdated: Date.now
                )
            ]
        )
        sessions[sessionId] = session
        Logger.social.info("Started crew tracking session: \(sessionId)")
        return session
    }

    // MARK: - Join Session

    func joinSession(_ sessionId: UUID) async throws {
        guard var session = sessions[sessionId] else {
            throw SocialError.recordNotFound
        }
        guard session.status == .active else {
            throw SocialError.recordNotFound
        }
        let participant = CrewParticipant(
            id: myParticipantId,
            displayName: "Participant",
            latitude: 0,
            longitude: 0,
            distanceKm: 0,
            currentPaceSecondsPerKm: 0,
            lastUpdated: Date.now
        )
        session.participants.append(participant)
        sessions[sessionId] = session
        Logger.social.info("Joined crew tracking session: \(sessionId)")
    }

    // MARK: - Update Location

    func updateLocation(
        sessionId: UUID,
        latitude: Double,
        longitude: Double,
        distanceKm: Double,
        paceSecondsPerKm: Double
    ) async throws {
        guard var session = sessions[sessionId] else {
            throw SocialError.recordNotFound
        }
        guard let index = session.participants.firstIndex(where: { $0.id == myParticipantId }) else {
            throw SocialError.recordNotFound
        }
        session.participants[index].latitude = latitude
        session.participants[index].longitude = longitude
        session.participants[index].distanceKm = distanceKm
        session.participants[index].currentPaceSecondsPerKm = paceSecondsPerKm
        session.participants[index].lastUpdated = Date.now
        sessions[sessionId] = session
        Logger.social.debug("Updated location in session: \(sessionId)")
    }

    // MARK: - Fetch Session

    func fetchSession(_ sessionId: UUID) async throws -> CrewTrackingSession? {
        sessions[sessionId]
    }

    // MARK: - End Session

    func endSession(_ sessionId: UUID) async throws {
        guard var session = sessions[sessionId] else {
            throw SocialError.recordNotFound
        }
        session.status = .ended
        sessions[sessionId] = session
        Logger.social.info("Ended crew tracking session: \(sessionId)")
    }

    // MARK: - Leave Session

    func leaveSession(_ sessionId: UUID) async throws {
        guard var session = sessions[sessionId] else {
            throw SocialError.recordNotFound
        }
        session.participants.removeAll { $0.id == myParticipantId }
        sessions[sessionId] = session
        Logger.social.info("Left crew tracking session: \(sessionId)")
    }
}
