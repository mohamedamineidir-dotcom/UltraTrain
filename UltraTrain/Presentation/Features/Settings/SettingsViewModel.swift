import Foundation
import os

@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - Dependencies

    let athleteRepository: any AthleteRepository
    let appSettingsRepository: any AppSettingsRepository
    let clearAllDataUseCase: any ClearAllDataUseCase
    let healthKitService: any HealthKitServiceProtocol
    let exportService: any ExportServiceProtocol
    let runRepository: any RunRepository
    let stravaAuthService: any StravaAuthServiceProtocol
    let stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)?
    let notificationService: any NotificationServiceProtocol
    let planRepository: any TrainingPlanRepository
    let raceRepository: any RaceRepository
    let biometricAuthService: any BiometricAuthServiceProtocol
    let healthKitImportService: (any HealthKitImportServiceProtocol)?
    let authService: (any AuthServiceProtocol)?
    let privacyTrackingService: (any PrivacyTrackingServiceProtocol)?

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
    var trackingStatus: TrackingAuthorizationStatus = .notDetermined

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
        authService: (any AuthServiceProtocol)? = nil,
        privacyTrackingService: (any PrivacyTrackingServiceProtocol)? = nil
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
        self.privacyTrackingService = privacyTrackingService
        if let privacyTrackingService {
            self.trackingStatus = privacyTrackingService.authorizationStatus
        }
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

    func saveSettings() async {
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
}
