import Foundation
import os

// MARK: - iCloud Sync, Clear Data, Account, Privacy & Appearance

extension SettingsViewModel {

    // MARK: - iCloud Sync

    func toggleiCloudSync(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "iCloudSyncEnabled")
        iCloudSyncEnabled = enabled
        showRestartAlert = true
        Logger.cloudKit.info("iCloud sync toggled to \(enabled). Restart required.")
    }

    // MARK: - Clear Data

    func clearAllData() async {
        do {
            try await clearAllDataUseCase.execute()
            athlete = nil
            appSettings = nil
            didClearData = true
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to clear all data: \(error)")
        }
    }

    // MARK: - Appearance

    func updateAppearanceMode(_ mode: AppearanceMode) async {
        guard var settings = appSettings else { return }
        settings.appearanceMode = mode
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
            UserDefaults.standard.set(mode.rawValue, forKey: "appearanceMode")
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update appearance mode: \(error)")
        }
    }

    // MARK: - Account

    func logout() async {
        guard let authService else { return }
        do {
            try await authService.logout()
            didLogout = true
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Logout failed: \(error)")
        }
    }

    func changePassword() async {
        guard let authService else { return }
        guard !currentPassword.isEmpty, !newPassword.isEmpty else {
            error = "Please fill in all fields"
            return
        }
        guard newPassword.count >= 8 else {
            error = "New password must be at least 8 characters"
            return
        }
        guard newPassword == confirmPassword else {
            error = "New passwords do not match"
            return
        }

        isChangingPassword = true
        error = nil

        do {
            try await authService.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            isChangingPassword = false
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
            changePasswordSuccess = true
        } catch {
            isChangingPassword = false
            self.error = error.localizedDescription
            Logger.settings.error("Change password failed: \(error)")
        }
    }

    func deleteAccount() async {
        guard let authService else { return }
        isDeletingAccount = true
        do {
            try await authService.deleteAccount()
            try await clearAllDataUseCase.execute()
            isDeletingAccount = false
            didLogout = true
        } catch {
            isDeletingAccount = false
            self.error = error.localizedDescription
            Logger.settings.error("Account deletion failed: \(error)")
        }
    }

    // MARK: - Privacy Tracking

    func requestTrackingPermission() async {
        guard let privacyTrackingService else { return }
        trackingStatus = await privacyTrackingService.requestAuthorization()
    }

    // MARK: - Data Retention

    func updateDataRetention(_ months: Int) async {
        guard var settings = appSettings else { return }
        settings.dataRetentionMonths = months
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update data retention: \(error)")
        }
    }
}
