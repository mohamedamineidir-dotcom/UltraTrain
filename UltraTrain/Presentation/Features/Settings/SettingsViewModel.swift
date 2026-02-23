import Foundation
import os

@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - Dependencies

    private let athleteRepository: any AthleteRepository
    private let appSettingsRepository: any AppSettingsRepository
    private let clearAllDataUseCase: any ClearAllDataUseCase
    private let healthKitService: any HealthKitServiceProtocol
    private let exportService: any ExportServiceProtocol
    private let runRepository: any RunRepository
    private let stravaAuthService: any StravaAuthServiceProtocol
    private let stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)?
    private let notificationService: any NotificationServiceProtocol
    private let planRepository: any TrainingPlanRepository
    private let raceRepository: any RaceRepository
    private let biometricAuthService: any BiometricAuthServiceProtocol
    private let healthKitImportService: (any HealthKitImportServiceProtocol)?
    private let authService: (any AuthServiceProtocol)?

    // MARK: - State

    var athlete: Athlete?
    var appSettings: AppSettings?
    var isLoading = false
    var error: String?
    var showingClearDataConfirmation = false
    var didClearData = false
    var healthKitRestingHR: Int?
    var healthKitMaxHR: Int?
    var healthKitBodyWeight: Double?
    var isRequestingHealthKit = false
    var showHealthKitExplanation = false
    var isExporting = false
    var exportedFileURL: URL?
    var stravaStatus: StravaConnectionStatus = .disconnected
    var isConnectingStrava = false
    var stravaQueuePendingCount = 0
    var iCloudSyncEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
    var showRestartAlert = false
    var isImportingFromHealth = false
    var lastImportResult: HealthKitImportResult?
    var didLogout = false
    var showingLogoutConfirmation = false
    var showingDeleteAccountConfirmation = false
    var isDeletingAccount = false
    var showingChangePassword = false
    var currentPassword = ""
    var newPassword = ""
    var confirmPassword = ""
    var isChangingPassword = false
    var changePasswordSuccess = false

    var healthKitStatus: HealthKitAuthStatus {
        healthKitService.authorizationStatus
    }

    // MARK: - Biometric Computed Properties

    var biometricTypeLabel: String {
        switch biometricAuthService.availableBiometricType {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .none: "Biometric Lock"
        }
    }

    var biometricIconName: String {
        switch biometricAuthService.availableBiometricType {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .none: "lock.fill"
        }
    }

    var isBiometricAvailable: Bool {
        biometricAuthService.availableBiometricType != .none
    }

    var settings: AppSettings {
        get {
            appSettings ?? AppSettings(
                id: UUID(),
                trainingRemindersEnabled: true,
                nutritionRemindersEnabled: true,
                autoPauseEnabled: true,
                nutritionAlertSoundEnabled: true,
                stravaAutoUploadEnabled: false,
                stravaConnected: false,
                raceCountdownEnabled: true,
                biometricLockEnabled: false,
                hydrationIntervalSeconds: 1200,
                fuelIntervalSeconds: 2700,
                electrolyteIntervalSeconds: 0,
                smartRemindersEnabled: false,
                saveToHealthEnabled: false,
                healthKitAutoImportEnabled: false,
                pacingAlertsEnabled: true,
                recoveryRemindersEnabled: true,
                weeklySummaryEnabled: true,
                voiceCoachingConfig: VoiceCoachingConfig()
            )
        }
        set {
            appSettings = newValue
        }
    }

    // MARK: - Init

    init(
        athleteRepository: any AthleteRepository,
        appSettingsRepository: any AppSettingsRepository,
        clearAllDataUseCase: any ClearAllDataUseCase,
        healthKitService: any HealthKitServiceProtocol,
        exportService: any ExportServiceProtocol,
        runRepository: any RunRepository,
        stravaAuthService: any StravaAuthServiceProtocol,
        stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)? = nil,
        notificationService: any NotificationServiceProtocol,
        planRepository: any TrainingPlanRepository,
        raceRepository: any RaceRepository,
        biometricAuthService: any BiometricAuthServiceProtocol,
        healthKitImportService: (any HealthKitImportServiceProtocol)? = nil,
        authService: (any AuthServiceProtocol)? = nil
    ) {
        self.athleteRepository = athleteRepository
        self.appSettingsRepository = appSettingsRepository
        self.clearAllDataUseCase = clearAllDataUseCase
        self.healthKitService = healthKitService
        self.exportService = exportService
        self.runRepository = runRepository
        self.stravaAuthService = stravaAuthService
        self.stravaUploadQueueService = stravaUploadQueueService
        self.notificationService = notificationService
        self.planRepository = planRepository
        self.raceRepository = raceRepository
        self.biometricAuthService = biometricAuthService
        self.healthKitImportService = healthKitImportService
        self.authService = authService
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            athlete = try await athleteRepository.getAthlete()
            appSettings = try await appSettingsRepository.getSettings()

            if appSettings == nil {
                let defaults = AppSettings(
                    id: UUID(),
                    trainingRemindersEnabled: true,
                    nutritionRemindersEnabled: true,
                    autoPauseEnabled: true,
                    nutritionAlertSoundEnabled: true,
                    stravaAutoUploadEnabled: false,
                    stravaConnected: false,
                    raceCountdownEnabled: true,
                    biometricLockEnabled: false,
                    hydrationIntervalSeconds: 1200,
                    fuelIntervalSeconds: 2700,
                    electrolyteIntervalSeconds: 0,
                    smartRemindersEnabled: false,
                    saveToHealthEnabled: false,
                    healthKitAutoImportEnabled: false,
                    pacingAlertsEnabled: true,
                    recoveryRemindersEnabled: true,
                    weeklySummaryEnabled: true,
                    voiceCoachingConfig: VoiceCoachingConfig()
                )
                try await appSettingsRepository.saveSettings(defaults)
                appSettings = defaults
            }
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to load settings: \(error)")
        }

        if healthKitStatus == .authorized {
            await fetchHealthKitData()
            if appSettings?.healthKitAutoImportEnabled == true {
                await importFromHealthKit()
            }
        }

        loadStravaStatus()
        await loadStravaQueueCount()
        isLoading = false
    }

    // MARK: - Unit Preference

    func updateUnitPreference(_ unit: UnitPreference) async {
        guard var athlete else { return }
        athlete.preferredUnit = unit

        do {
            try await athleteRepository.updateAthlete(athlete)
            self.athlete = athlete
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update unit preference: \(error)")
        }
    }

    // MARK: - Notification Toggles

    func updateTrainingReminders(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.trainingRemindersEnabled = enabled

        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings

            if enabled {
                _ = try await notificationService.requestAuthorization()
                if let plan = try await planRepository.getActivePlan() {
                    let sessions = plan.weeks.flatMap(\.sessions)
                    let races = try await raceRepository.getRaces()
                    await notificationService.rescheduleAll(sessions: sessions, races: races)
                }
            } else {
                await notificationService.cancelNotifications(withIdentifierPrefix: "training-")
            }
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update training reminders: \(error)")
        }
    }

    func updateNutritionReminders(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.nutritionRemindersEnabled = enabled

        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update nutrition reminders: \(error)")
        }
    }

    func updateNutritionAlertSound(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.nutritionAlertSoundEnabled = enabled

        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update nutrition alert sound: \(error)")
        }
    }

    func updateRaceCountdown(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.raceCountdownEnabled = enabled

        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings

            if enabled {
                _ = try await notificationService.requestAuthorization()
                let races = try await raceRepository.getRaces()
                for race in races {
                    await notificationService.scheduleRaceCountdown(for: race)
                }
            } else {
                await notificationService.cancelNotifications(withIdentifierPrefix: "race-")
            }
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update race countdown: \(error)")
        }
    }

    func updateRecoveryReminders(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.recoveryRemindersEnabled = enabled

        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings

            if enabled {
                _ = try await notificationService.requestAuthorization()
                if let plan = try await planRepository.getActivePlan() {
                    let sessions = plan.weeks.flatMap(\.sessions)
                    let races = try await raceRepository.getRaces()
                    await notificationService.rescheduleAll(sessions: sessions, races: races)
                }
            } else {
                await notificationService.cancelNotifications(withIdentifierPrefix: "recovery-")
            }
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update recovery reminders: \(error)")
        }
    }

    func updateWeeklySummary(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.weeklySummaryEnabled = enabled

        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings

            if enabled {
                _ = try await notificationService.requestAuthorization()
            } else {
                await notificationService.cancelNotifications(withIdentifierPrefix: "weekly-")
            }
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update weekly summary: \(error)")
        }
    }

    // MARK: - Nutrition Interval Settings

    func updateHydrationInterval(_ seconds: TimeInterval) async {
        guard var settings = appSettings else { return }
        settings.hydrationIntervalSeconds = seconds
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update hydration interval: \(error)")
        }
    }

    func updateFuelInterval(_ seconds: TimeInterval) async {
        guard var settings = appSettings else { return }
        settings.fuelIntervalSeconds = seconds
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update fuel interval: \(error)")
        }
    }

    func updateElectrolyteInterval(_ seconds: TimeInterval) async {
        guard var settings = appSettings else { return }
        settings.electrolyteIntervalSeconds = seconds
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update electrolyte interval: \(error)")
        }
    }

    func updateSmartReminders(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.smartRemindersEnabled = enabled
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update smart reminders: \(error)")
        }
    }

    // MARK: - Biometric Lock

    func updateBiometricLock(_ enabled: Bool) async {
        guard var settings = appSettings else { return }

        if enabled {
            do {
                let success = try await biometricAuthService.authenticate(
                    reason: "Verify your identity to enable app lock"
                )
                guard success else {
                    self.error = "Authentication failed. Please try again."
                    return
                }
            } catch {
                self.error = error.localizedDescription
                Logger.biometric.error("Failed to verify biometrics: \(error)")
                return
            }
        }

        settings.biometricLockEnabled = enabled
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update biometric lock: \(error)")
        }
    }

    // MARK: - HealthKit

    func requestHealthKitAuthorization() async {
        isRequestingHealthKit = true
        do {
            try await healthKitService.requestAuthorization()
            await fetchHealthKitData()
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to request HealthKit authorization: \(error)")
        }
        isRequestingHealthKit = false
    }

    func fetchHealthKitData() async {
        do {
            healthKitRestingHR = try await healthKitService.fetchRestingHeartRate()
            healthKitMaxHR = try await healthKitService.fetchMaxHeartRate()
            healthKitBodyWeight = try await healthKitService.fetchBodyWeight()
        } catch {
            Logger.settings.error("Failed to fetch HealthKit data: \(error)")
        }
    }

    func updateAthleteWithHealthKitData() async {
        guard var athlete else { return }
        var changed = false

        if let rhr = healthKitRestingHR {
            athlete.restingHeartRate = rhr
            changed = true
        }
        if let mhr = healthKitMaxHR {
            athlete.maxHeartRate = mhr
            changed = true
        }
        if let weight = healthKitBodyWeight {
            athlete.weightKg = weight
            changed = true
        }

        guard changed else { return }
        do {
            try await athleteRepository.updateAthlete(athlete)
            self.athlete = athlete
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update athlete with HealthKit data: \(error)")
        }
    }

    func updateSaveToHealth(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.saveToHealthEnabled = enabled
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update save-to-health setting: \(error)")
        }
    }

    // MARK: - HealthKit Import

    func updateHealthKitAutoImport(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.healthKitAutoImportEnabled = enabled
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
            if enabled {
                await importFromHealthKit()
            }
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update HealthKit auto-import: \(error)")
        }
    }

    func importFromHealthKit() async {
        guard let athlete, let importService = healthKitImportService else { return }
        isImportingFromHealth = true
        do {
            lastImportResult = try await importService.importNewWorkouts(athleteId: athlete.id)
        } catch {
            Logger.healthKit.error("HealthKit import failed: \(error)")
        }
        isImportingFromHealth = false
    }

    // MARK: - Auto Pause

    func updateAutoPause(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.autoPauseEnabled = enabled

        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update auto-pause setting: \(error)")
        }
    }

    // MARK: - Voice Coaching

    func updateVoiceCoachingConfig(_ config: VoiceCoachingConfig) async {
        settings.voiceCoachingConfig = config
        await saveSettings()
    }

    private func saveSettings() async {
        guard var current = appSettings else { return }
        current = settings
        do {
            try await appSettingsRepository.updateSettings(current)
            appSettings = current
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to save settings: \(error)")
        }
    }

    // MARK: - Pacing Alerts

    func updatePacingAlerts(_ enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.pacingAlertsEnabled = enabled

        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update pacing alerts setting: \(error)")
        }
    }

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

    // MARK: - Quiet Hours

    func updateQuietHours(enabled: Bool) async {
        guard var settings = appSettings else { return }
        settings.quietHoursEnabled = enabled
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update quiet hours: \(error)")
        }
    }

    func updateQuietHoursStart(_ hour: Int) async {
        guard var settings = appSettings else { return }
        settings.quietHoursStart = hour
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update quiet hours start: \(error)")
        }
    }

    func updateQuietHoursEnd(_ hour: Int) async {
        guard var settings = appSettings else { return }
        settings.quietHoursEnd = hour
        do {
            try await appSettingsRepository.updateSettings(settings)
            appSettings = settings
        } catch {
            self.error = error.localizedDescription
            Logger.settings.error("Failed to update quiet hours end: \(error)")
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
