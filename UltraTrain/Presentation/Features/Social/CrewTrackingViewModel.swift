import Foundation
import os

@Observable
@MainActor
final class CrewTrackingViewModel {

    // MARK: - Dependencies

    private let crewService: any CrewTrackingServiceProtocol
    private let profileRepository: any SocialProfileRepository

    // MARK: - State

    var session: CrewTrackingSession?
    var isLoading = false
    var error: String?
    var isHost = false

    // MARK: - Init

    init(
        crewService: any CrewTrackingServiceProtocol,
        profileRepository: any SocialProfileRepository
    ) {
        self.crewService = crewService
        self.profileRepository = profileRepository
    }

    // MARK: - Start Session

    func startSession() async {
        isLoading = true
        error = nil
        do {
            session = try await crewService.startSession()
            isHost = true
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to start crew session: \(error)")
        }
        isLoading = false
    }

    // MARK: - Join Session

    func joinSession(id: UUID) async {
        isLoading = true
        error = nil
        do {
            try await crewService.joinSession(id)
            session = try await crewService.fetchSession(id)
            isHost = false
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to join crew session: \(error)")
        }
        isLoading = false
    }

    // MARK: - Update My Location

    func updateMyLocation(
        latitude: Double,
        longitude: Double,
        distanceKm: Double,
        paceSecondsPerKm: Double
    ) async {
        guard let sessionId = session?.id else { return }
        do {
            try await crewService.updateLocation(
                sessionId: sessionId,
                latitude: latitude,
                longitude: longitude,
                distanceKm: distanceKm,
                paceSecondsPerKm: paceSecondsPerKm
            )
        } catch {
            Logger.social.error("Failed to update location: \(error)")
        }
    }

    // MARK: - End Session

    func endSession() async {
        guard let sessionId = session?.id else { return }
        do {
            try await crewService.endSession(sessionId)
            session = nil
            isHost = false
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to end crew session: \(error)")
        }
    }

    // MARK: - Leave Session

    func leaveSession() async {
        guard let sessionId = session?.id else { return }
        do {
            try await crewService.leaveSession(sessionId)
            session = nil
            isHost = false
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to leave crew session: \(error)")
        }
    }

    // MARK: - Refresh Session

    func refreshSession() async {
        guard let sessionId = session?.id else { return }
        do {
            session = try await crewService.fetchSession(sessionId)
        } catch {
            Logger.social.error("Failed to refresh crew session: \(error)")
        }
    }
}
