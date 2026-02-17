import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    @State private var showingShareSheet = false

    init(
        athleteRepository: any AthleteRepository,
        appSettingsRepository: any AppSettingsRepository,
        clearAllDataUseCase: any ClearAllDataUseCase,
        healthKitService: any HealthKitServiceProtocol,
        exportService: any ExportServiceProtocol,
        runRepository: any RunRepository,
        stravaAuthService: any StravaAuthServiceProtocol
    ) {
        _viewModel = State(initialValue: SettingsViewModel(
            athleteRepository: athleteRepository,
            appSettingsRepository: appSettingsRepository,
            clearAllDataUseCase: clearAllDataUseCase,
            healthKitService: healthKitService,
            exportService: exportService,
            runRepository: runRepository,
            stravaAuthService: stravaAuthService
        ))
    }

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            } else {
                unitsSection
                runTrackingSection
                notificationsSection
                healthKitSection
                stravaSection
                dataManagementSection
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
            } header: {
                Text("Run Tracking")
            } footer: {
                Text("Automatically pause and resume your run when you stop and start moving.")
            }
        }
    }

    // MARK: - Notifications Section

    @ViewBuilder
    private var notificationsSection: some View {
        if let settings = viewModel.appSettings {
            Section("Notifications") {
                Toggle("Training Reminders", isOn: Binding(
                    get: { settings.trainingRemindersEnabled },
                    set: { newValue in
                        Task { await viewModel.updateTrainingReminders(newValue) }
                    }
                ))

                Toggle("Nutrition Reminders", isOn: Binding(
                    get: { settings.nutritionRemindersEnabled },
                    set: { newValue in
                        Task { await viewModel.updateNutritionReminders(newValue) }
                    }
                ))

                if settings.nutritionRemindersEnabled {
                    Toggle("Sound & Haptic Alerts", isOn: Binding(
                        get: { settings.nutritionAlertSoundEnabled },
                        set: { newValue in
                            Task { await viewModel.updateNutritionAlertSound(newValue) }
                        }
                    ))
                }
            }
        }
    }

    // MARK: - HealthKit Section

    private var healthKitSection: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Apple Health")
                    Text(healthKitStatusDescription)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            } icon: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(healthKitStatusColor)
            }

            switch viewModel.healthKitStatus {
            case .unavailable:
                Text("HealthKit is not available on this device.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            case .notDetermined:
                Button {
                    viewModel.showHealthKitExplanation = true
                } label: {
                    if viewModel.isRequestingHealthKit {
                        ProgressView()
                    } else {
                        Text("Connect Apple Health")
                    }
                }
                .disabled(viewModel.isRequestingHealthKit)
            case .authorized:
                if let rhr = viewModel.healthKitRestingHR {
                    LabeledContent("Resting HR", value: "\(rhr) bpm")
                }
                if let mhr = viewModel.healthKitMaxHR {
                    LabeledContent("Max HR (30d)", value: "\(mhr) bpm")
                }
                if viewModel.healthKitRestingHR != nil || viewModel.healthKitMaxHR != nil {
                    Button("Update Profile with Health Data") {
                        Task { await viewModel.updateAthleteWithHealthKitData() }
                    }
                }
                Button("Refresh Health Data") {
                    Task { await viewModel.fetchHealthKitData() }
                }
            case .denied:
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        } header: {
            Text("Health")
        }
        .alert(
            "Connect Apple Health",
            isPresented: $viewModel.showHealthKitExplanation
        ) {
            Button("Continue") {
                Task { await viewModel.requestHealthKitAuthorization() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("UltraTrain will read your heart rate, resting heart rate, and running workouts from Apple Health to enhance your training insights.")
        }
    }

    private var healthKitStatusDescription: String {
        switch viewModel.healthKitStatus {
        case .unavailable: "Not available on this device"
        case .notDetermined: "Connect to sync heart rate and workouts"
        case .authorized: "Connected"
        case .denied: "Access denied — enable in iOS Settings"
        }
    }

    private var healthKitStatusColor: Color {
        switch viewModel.healthKitStatus {
        case .unavailable, .denied: .gray
        case .notDetermined: .red
        case .authorized: .green
        }
    }

    // MARK: - Strava Section

    private var stravaSection: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Strava")
                    Text(stravaStatusDescription)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            } icon: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(stravaStatusColor)
            }

            switch viewModel.stravaStatus {
            case .disconnected, .error:
                Button {
                    Task { await viewModel.connectStrava() }
                } label: {
                    if viewModel.isConnectingStrava {
                        ProgressView()
                    } else {
                        Text("Connect to Strava")
                            .foregroundStyle(Color.orange)
                    }
                }
                .disabled(viewModel.isConnectingStrava)

            case .connecting:
                ProgressView("Connecting...")

            case .connected:
                if let settings = viewModel.appSettings {
                    Toggle("Auto-Upload Runs", isOn: Binding(
                        get: { settings.stravaAutoUploadEnabled },
                        set: { newValue in
                            Task { await viewModel.updateStravaAutoUpload(newValue) }
                        }
                    ))
                }
                Button(role: .destructive) {
                    Task { await viewModel.disconnectStrava() }
                } label: {
                    Text("Disconnect Strava")
                }
            }
        } header: {
            Text("Connected Services")
        }
    }

    private var stravaStatusDescription: String {
        switch viewModel.stravaStatus {
        case .disconnected: "Not connected"
        case .connecting: "Connecting..."
        case .connected(let name): "Connected as \(name)"
        case .error(let msg): "Error: \(msg)"
        }
    }

    private var stravaStatusColor: Color {
        switch viewModel.stravaStatus {
        case .disconnected, .error: .gray
        case .connecting: .orange
        case .connected: .orange
        }
    }

    // MARK: - Data Management Section

    private var dataManagementSection: some View {
        Section("Data") {
            Button {
                Task { await viewModel.exportAllRunsAsCSV() }
            } label: {
                HStack {
                    Label("Export Training Data", systemImage: "square.and.arrow.up")
                    Spacer()
                    if viewModel.isExporting {
                        ProgressView()
                    }
                }
            }
            .disabled(viewModel.isExporting)
            .onChange(of: viewModel.exportedFileURL) {
                if viewModel.exportedFileURL != nil {
                    showingShareSheet = true
                }
            }

            Button(role: .destructive) {
                viewModel.showingClearDataConfirmation = true
            } label: {
                Label("Clear All Data", systemImage: "trash")
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: AppConfiguration.appVersion)
            LabeledContent("Build", value: AppConfiguration.buildNumber)
        }
    }
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
