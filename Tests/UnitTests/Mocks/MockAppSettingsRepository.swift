import Foundation
@testable import UltraTrain

final class MockAppSettingsRepository: AppSettingsRepository, @unchecked Sendable {
    var savedSettings: AppSettings?
    var shouldThrow = false

    func getSettings() async throws -> AppSettings? {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        return savedSettings
    }

    func saveSettings(_ settings: AppSettings) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        savedSettings = settings
    }

    func updateSettings(_ settings: AppSettings) async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        savedSettings = settings
    }
}
