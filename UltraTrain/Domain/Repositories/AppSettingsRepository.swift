import Foundation

protocol AppSettingsRepository: Sendable {
    func getSettings() async throws -> AppSettings?
    func saveSettings(_ settings: AppSettings) async throws
    func updateSettings(_ settings: AppSettings) async throws
}
