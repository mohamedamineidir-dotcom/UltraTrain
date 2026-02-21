import Foundation

protocol CrewTrackingServiceProtocol: Sendable {
    func startSession() async throws -> CrewTrackingSession
    func joinSession(_ sessionId: UUID) async throws
    func updateLocation(sessionId: UUID, latitude: Double, longitude: Double, distanceKm: Double, paceSecondsPerKm: Double) async throws
    func fetchSession(_ sessionId: UUID) async throws -> CrewTrackingSession?
    func endSession(_ sessionId: UUID) async throws
    func leaveSession(_ sessionId: UUID) async throws
}
