import Foundation
import os

// MARK: - Export & Strava

extension SettingsViewModel {

    // MARK: - Export

    func exportAllRunsAsCSV() async {
        isExporting = true
        do {
            let runs = try await runRepository.getRecentRuns(limit: 10000)
            guard !runs.isEmpty else {
                self.error = "No runs to export."
                isExporting = false
                return
            }
            exportedFileURL = try await exportService.exportRunsAsCSV(runs)
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to export runs: \(error)")
        }
        isExporting = false
    }

    // MARK: - Strava

    func loadStravaStatus() {
        stravaStatus = stravaAuthService.getConnectionStatus()
    }

    func loadStravaQueueCount() async {
        stravaQueuePendingCount = await stravaUploadQueueService?.getPendingCount() ?? 0
    }

    func connectStrava() async {
        isConnectingStrava = true
        stravaStatus = .connecting
        do {
            try await stravaAuthService.authenticate()
            stravaStatus = stravaAuthService.getConnectionStatus()
            if var settings = appSettings {
                settings.stravaConnected = true
                try await appSettingsRepository.updateSettings(settings)
                appSettings = settings
            }
        } catch {
            stravaStatus = .error(message: error.localizedDescription)
            self.error = error.localizedDescription
            Logger.strava.error("Failed to connect Strava: \(error)")
        }
        isConnectingStrava = false
    }

    func disconnectStrava() async {
        stravaAuthService.disconnect()
        stravaStatus = .disconnected
        if var settings = appSettings {
            settings.stravaConnected = false
            settings.stravaAutoUploadEnabled = false
            do {
                try await appSettingsRepository.updateSettings(settings)
                appSettings = settings
            } catch {
                Logger.strava.error("Failed to update settings after disconnect: \(error)")
            }
        }
    }

    func updateStravaAutoUpload(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.stravaAutoUploadEnabled = enabled
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.strava.error("Failed to update Strava auto-upload: \(error)")
        }
    }
}
