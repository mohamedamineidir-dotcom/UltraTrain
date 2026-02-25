import SwiftUI

struct SettingsView: View {
    @State var viewModel: SettingsViewModel

    @State var showingShareSheet = false

    let appSettingsRepository: any AppSettingsRepository
    let emergencyContactRepository: (any EmergencyContactRepository)?
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
        authService: (any AuthServiceProtocol)? = nil,
        privacyTrackingService: (any PrivacyTrackingServiceProtocol)? = nil,
        onLogout: (() -> Void)? = nil
    ) {
        self.appSettingsRepository = appSettingsRepository
        self.emergencyContactRepository = emergencyContactRepository
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
                appearanceSection
                runTrackingSection
                safetySection
                securitySection
                notificationsSection
                healthKitSection
                stravaSection
                iCloudSection
                privacySection
                syncQueueSection
                dataRetentionSection
                dataManagementSection
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

    // MARK: - Safety Section

    @ViewBuilder
    private var safetySection: some View {
        if let emergencyContactRepository {
            Section {
                NavigationLink {
                    SafetySettingsView(
                        appSettingsRepository: appSettingsRepository,
                        emergencyContactRepository: emergencyContactRepository
                    )
                } label: {
                    Label("Safety & Emergency", systemImage: "sos")
                }
                .accessibilityHint("Manage SOS, fall detection, emergency contacts, and safety timer settings")
            } header: {
                Text("Safety")
            }
        }
    }

    // MARK: - Units Section

    @ViewBuilder
    private var unitsSection: some View {
        if let athlete = viewModel.athlete {
            Section("Units") {
                Picker("Measurement System", selection: Binding(
                    get: { athlete.preferredUnit },
                    set: { newUnit in
                        Task { await viewModel.updateUnitPreference(newUnit) }
                    }
                )) {
                    ForEach(UnitPreference.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
            }
        }
    }

    // MARK: - Appearance Section

    @ViewBuilder
    private var appearanceSection: some View {
        if let settings = viewModel.appSettings {
            Section("Appearance") {
                Picker("Theme", selection: Binding(
                    get: { settings.appearanceMode },
                    set: { newMode in
                        Task { await viewModel.updateAppearanceMode(newMode) }
                    }
                )) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityHint("Choose between system, light, or dark appearance")
            }
        }
    }

    // MARK: - Run Tracking Section

    @ViewBuilder
    private var runTrackingSection: some View {
        if let settings = viewModel.appSettings {
            Section {
                Toggle("Auto-Pause", isOn: Binding(
                    get: { settings.autoPauseEnabled },
                    set: { newValue in
                        Task { await viewModel.updateAutoPause(newValue) }
                    }
                ))
                .accessibilityIdentifier("settings.autoPauseToggle")
                .accessibilityHint("Automatically pauses your run when you stop moving")

                Toggle("Pacing Alerts", isOn: Binding(
                    get: { settings.pacingAlertsEnabled },
                    set: { newValue in
                        Task { await viewModel.updatePacingAlerts(newValue) }
                    }
                ))
                .accessibilityHint("Notifies you when your pace deviates from the planned target")

                NavigationLink {
                    VoiceCoachingSettingsView(
                        config: $viewModel.settings.voiceCoachingConfig,
                        onConfigChanged: { config in
                            Task { await viewModel.updateVoiceCoachingConfig(config) }
                        }
                    )
                } label: {
                    HStack {
                        Label("Voice Coaching", systemImage: "speaker.wave.2")
                        Spacer()
                        Text(viewModel.settings.voiceCoachingConfig.enabled ? "On" : "Off")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Run Tracking")
            } footer: {
                Text("Auto-Pause pauses your run when you stop moving. Pacing Alerts notify you when your pace deviates from the planned session target.")
            }
        }
    }

    // MARK: - Security Section

    @ViewBuilder
    private var securitySection: some View {
        if let settings = viewModel.appSettings, viewModel.isBiometricAvailable {
            Section {
                Toggle(isOn: Binding(
                    get: { settings.biometricLockEnabled },
                    set: { newValue in
                        Task { await viewModel.updateBiometricLock(newValue) }
                    }
                )) {
                    Label {
                        Text(viewModel.biometricTypeLabel)
                    } icon: {
                        Image(systemName: viewModel.biometricIconName)
                    }
                }
                .accessibilityHint("Requires \(viewModel.biometricTypeLabel) authentication to open the app")
            } header: {
                Text("Security")
            } footer: {
                Text("Require \(viewModel.biometricTypeLabel) to open UltraTrain.")
            }
        }
    }

    // MARK: - Environment

    @Environment(\.unitPreference) var units
    @Environment(\.syncStatusMonitor) var syncStatusMonitor
    @Environment(\.syncService) var syncService
}

// MARK: - UnitPreference Display

private extension UnitPreference {
    var displayName: String {
        switch self {
        case .metric: "Metric (km, m, kg)"
        case .imperial: "Imperial (mi, ft, lb)"
        }
    }
}
