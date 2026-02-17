import Foundation

enum StravaConnectionStatus: Sendable, Equatable {
    case disconnected
    case connecting
    case connected(athleteName: String)
    case error(message: String)
}

protocol StravaAuthServiceProtocol: Sendable {
    func authenticate() async throws
    func disconnect()
    func getValidToken() async throws -> String
    func isConnected() -> Bool
    func getConnectionStatus() -> StravaConnectionStatus
    func getAthleteName() -> String?
}
