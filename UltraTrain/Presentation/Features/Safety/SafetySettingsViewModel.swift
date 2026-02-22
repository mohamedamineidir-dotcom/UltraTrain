import Foundation
import os

@Observable
@MainActor
final class SafetySettingsViewModel {
    private let appSettingsRepository: any AppSettingsRepository

    var config: SafetyConfig = SafetyConfig()
    var isLoading = false
    var error: String?

    init(appSettingsRepository: any AppSettingsRepository) {
        self.appSettingsRepository = appSettingsRepository
    }

    func load() async {
        isLoading = true
        do {
            if let settings = try await appSettingsRepository.getSettings() {
                config = settings.safetyConfig
            }
        } catch {
            self.error = error.localizedDescription
            Logger.safety.error("Failed to load safety config: \(error)")
        }
        isLoading = false
    }

    func save() async {
        do {
            guard var settings = try await appSettingsRepository.getSettings() else { return }
            settings.safetyConfig = config
            try await appSettingsRepository.saveSettings(settings)
        } catch {
            self.error = error.localizedDescription
            Logger.safety.error("Failed to save safety config: \(error)")
        }
    }
}
