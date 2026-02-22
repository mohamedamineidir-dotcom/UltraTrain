import Foundation

protocol AuthServiceProtocol: Sendable {
    func register(email: String, password: String) async throws
    func login(email: String, password: String) async throws
    func logout() async throws
    func getValidAccessToken() async throws -> String
    func isAuthenticated() -> Bool
}
