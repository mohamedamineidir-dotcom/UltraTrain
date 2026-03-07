import SwiftUI

struct SettingsView: View {
    @State var viewModel: SettingsViewModel

    @State var showingShareSheet = false

    let appSettingsRepository: any AppSettingsRepository
    let emergencyContactRepository: (any EmergencyContactRepository)?
    let referralRepository: (any ReferralRepository)?
    var onLogout: (() -> Void)?

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
        emergencyContactRepository: (any EmergencyContactRepository)? = nil,
        referralRepository: (any ReferralRepository)? = nil,
        authService: (any AuthServiceProtocol)? = nil,
        privacyTrackingService: (any PrivacyTrackingServiceProtocol)? = nil,
        onLogout: (() -> Void)? = nil
    ) {
        self.appSettingsRepository = appSettingsRepository
        self.emergencyContactRepository = emergencyContactRepository
        self.referralRepository = referralRepository
        self.onLogout = onLogout
        _viewModel = State(initialValue: SettingsViewModel(
            athleteRepository: athleteRepository,
            appSettingsRepository: appSettingsRepository,
            clearAllDataUseCase: clearAllDataUseCase,
            healthKitService: healthKitService,
            exportService: exportService,
            runRepository: runRepository,
            stravaAuthService: stravaAuthService,
            stravaUploadQueueService: stravaUploadQueueService,
            notificationService: notificationService,
            planRepository: planRepository,
            raceRepository: raceRepository,
            biometricAuthService: biometricAuthService,
            healthKitImportService: healthKitImportService,
            authService: authService,
            privacyTrackingService: privacyTrackingService
        ))
    }

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            } else {
                unitsSection
                trainingPreferencesSection
                appearanceSection
                runTrackingSection
                safetySection
                securitySection
                notificationsSection
                notificationSoundsSection
                healthKitSection
                stravaSection
                iCloudSection
                privacySection
                syncQueueSection
                dataRetentionSection
                dataManagementSection
                if referralRepository != nil {
                    referralSection
                }
                accountSection
                aboutSection
            }
        }
        .navigationTitle("Settings")
        .task {
            await viewModel.load()
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .confirmationDialog(
            "Clear All Data",
            isPresented: $viewModel.showingClearDataConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All Data", role: .destructive) {
                Task { await viewModel.clearAllData() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your training data, plans, and settings. This action cannot be undone.")
        }
        .alert("Data Cleared", isPresented: $viewModel.didClearData) {
            Button("OK") {}
        } message: {
            Text("All data has been cleared. Please restart the app to begin fresh.")
        }
        .sheet(isPresented: $showingShareSheet, onDismiss: {
            viewModel.exportedFileURL = nil
        }) {
            if let url = viewModel.exportedFileURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    // MARK: - Environment

    @Environment(\.unitPreference) var units
    @Environment(\.syncStatusMonitor) var syncStatusMonitor
    @Environment(\.syncService) var syncService
}
