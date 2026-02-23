import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    @State private var showingShareSheet = false

    private let appSettingsRepository: any AppSettingsRepository
    private let emergencyContactRepository: (any EmergencyContactRepository)?
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
            authService: authService
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
                .accessibilityIdentifier("settings.trainingRemindersToggle")
                .accessibilityHint("Sends reminders about upcoming training sessions")

                Toggle("Nutrition Reminders", isOn: Binding(
                    get: { settings.nutritionRemindersEnabled },
                    set: { newValue in
                        Task { await viewModel.updateNutritionReminders(newValue) }
                    }
                ))
                .accessibilityIdentifier("settings.nutritionRemindersToggle")
                .accessibilityHint("Sends hydration, fuel, and electrolyte reminders during runs")

                if settings.nutritionRemindersEnabled {
                    Toggle("Sound & Haptic Alerts", isOn: Binding(
                        get: { settings.nutritionAlertSoundEnabled },
                        set: { newValue in
                            Task { await viewModel.updateNutritionAlertSound(newValue) }
                        }
                    ))
                    .accessibilityHint("Plays sound and vibration for nutrition reminders")

                    NutritionIntervalPicker(
                        label: "Hydration Interval",
                        valueMinutes: Binding(
                            get: { Int(settings.hydrationIntervalSeconds / 60) },
                            set: { newMin in
                                Task { await viewModel.updateHydrationInterval(TimeInterval(newMin * 60)) }
                            }
                        ),
                        range: Array(stride(from: 10, through: 60, by: 5))
                    )

                    NutritionIntervalPicker(
                        label: "Fuel Interval",
                        valueMinutes: Binding(
                            get: { Int(settings.fuelIntervalSeconds / 60) },
                            set: { newMin in
                                Task { await viewModel.updateFuelInterval(TimeInterval(newMin * 60)) }
                            }
                        ),
                        range: Array(stride(from: 15, through: 90, by: 5))
                    )

                    NutritionIntervalPicker(
                        label: "Electrolyte Interval",
                        valueMinutes: Binding(
                            get: { Int(settings.electrolyteIntervalSeconds / 60) },
                            set: { newMin in
                                Task { await viewModel.updateElectrolyteInterval(TimeInterval(newMin * 60)) }
                            }
                        ),
                        range: Array(stride(from: 15, through: 120, by: 15)),
                        allowOff: true
                    )

                    Toggle("Smart Reminders", isOn: Binding(
                        get: { settings.smartRemindersEnabled },
                        set: { newValue in
                            Task { await viewModel.updateSmartReminders(newValue) }
                        }
                    ))
                    .accessibilityHint("Adjusts reminder timing based on your pace and conditions")
                }

                Toggle("Race Countdown", isOn: Binding(
                    get: { settings.raceCountdownEnabled },
                    set: { newValue in
                        Task { await viewModel.updateRaceCountdown(newValue) }
                    }
                ))
                .accessibilityIdentifier("settings.raceCountdownToggle")
                .accessibilityHint("Shows a countdown notification as race day approaches")

                Toggle("Recovery Reminders", isOn: Binding(
                    get: { settings.recoveryRemindersEnabled },
                    set: { newValue in
                        Task { await viewModel.updateRecoveryReminders(newValue) }
                    }
                ))
                .accessibilityIdentifier("settings.recoveryRemindersToggle")
                .accessibilityHint("Sends reminders on rest days to stretch and hydrate")

                Toggle("Weekly Summary", isOn: Binding(
                    get: { settings.weeklySummaryEnabled },
                    set: { newValue in
                        Task { await viewModel.updateWeeklySummary(newValue) }
                    }
                ))
                .accessibilityIdentifier("settings.weeklySummaryToggle")
                .accessibilityHint("Sends a weekly training summary notification on Sundays")

                Toggle("Quiet Hours", isOn: Binding(
                    get: { settings.quietHoursEnabled },
                    set: { newValue in
                        Task { await viewModel.updateQuietHours(enabled: newValue) }
                    }
                ))
                .accessibilityHint("Suppresses notifications during specified hours")

                if settings.quietHoursEnabled {
                    Picker("Start", selection: Binding(
                        get: { settings.quietHoursStart },
                        set: { hour in
                            Task { await viewModel.updateQuietHoursStart(hour) }
                        }
                    )) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }

                    Picker("End", selection: Binding(
                        get: { settings.quietHoursEnd },
                        set: { hour in
                            Task { await viewModel.updateQuietHoursEnd(hour) }
                        }
                    )) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
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
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .combine)

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
                .accessibilityHint("Requests permission to read and write health data")
            case .authorized:
                if let rhr = viewModel.healthKitRestingHR {
                    LabeledContent("Resting HR", value: "\(rhr) bpm")
                }
                if let mhr = viewModel.healthKitMaxHR {
                    LabeledContent("Max HR (30d)", value: "\(mhr) bpm")
                }
                if let weight = viewModel.healthKitBodyWeight {
                    LabeledContent("Body Weight", value: bodyWeightFormatted(weight))
                }
                if viewModel.healthKitRestingHR != nil || viewModel.healthKitMaxHR != nil || viewModel.healthKitBodyWeight != nil {
                    Button("Update Profile with Health Data") {
                        Task { await viewModel.updateAthleteWithHealthKitData() }
                    }
                    .accessibilityHint("Updates your athlete profile with the latest Apple Health data")
                }
                if let settings = viewModel.appSettings {
                    Toggle("Save Runs to Apple Health", isOn: Binding(
                        get: { settings.saveToHealthEnabled },
                        set: { newValue in
                            Task { await viewModel.updateSaveToHealth(newValue) }
                        }
                    ))
                    .accessibilityHint("Saves completed runs as workouts in Apple Health")
                    Toggle("Auto-import from Apple Health", isOn: Binding(
                        get: { settings.healthKitAutoImportEnabled },
                        set: { newValue in
                            Task { await viewModel.updateHealthKitAutoImport(newValue) }
                        }
                    ))
                    .accessibilityHint("Automatically imports running workouts from Apple Health")
                    if settings.healthKitAutoImportEnabled {
                        if viewModel.isImportingFromHealth {
                            HStack(spacing: Theme.Spacing.sm) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Importing workouts...")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.secondaryLabel)
                            }
                        } else if let result = viewModel.lastImportResult {
                            Text(importResultText(result))
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.secondaryLabel)
                        }
                    }
                }
                Button("Refresh Health Data") {
                    Task { await viewModel.fetchHealthKitData() }
                }
                .accessibilityHint("Fetches the latest heart rate, weight, and workout data from Apple Health")
            case .denied:
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .accessibilityHint("Opens iOS Settings to enable Apple Health access for UltraTrain")
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
            Text("UltraTrain will read your heart rate, body weight, and running workouts from Apple Health, and can save completed runs back to Health.")
        }
    }

    @Environment(\.unitPreference) private var units
    @Environment(\.syncStatusMonitor) private var syncStatusMonitor
    @Environment(\.syncService) private var syncService

    private func bodyWeightFormatted(_ kg: Double) -> String {
        UnitFormatter.formatWeight(kg, unit: units)
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

    private func importResultText(_ result: HealthKitImportResult) -> String {
        if result.importedCount == 0 {
            return "All runs up to date"
        }
        var text = "Imported \(result.importedCount) run\(result.importedCount == 1 ? "" : "s")"
        if result.matchedSessionCount > 0 {
            text += ", \(result.matchedSessionCount) matched to plan"
        }
        return text
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
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .combine)

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
                .accessibilityHint("Connects your Strava account to automatically upload runs")

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
                    .accessibilityHint("Automatically uploads completed runs to Strava")
                }
                if viewModel.stravaQueuePendingCount > 0 {
                    LabeledContent(
                        "Pending Uploads",
                        value: "\(viewModel.stravaQueuePendingCount)"
                    )
                }
                Button(role: .destructive) {
                    Task { await viewModel.disconnectStrava() }
                } label: {
                    Text("Disconnect Strava")
                }
                .accessibilityHint("Removes the connection to your Strava account")
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

    // MARK: - iCloud Section

    private var iCloudSection: some View {
        Section {
            Toggle("iCloud Sync", isOn: Binding(
                get: { viewModel.iCloudSyncEnabled },
                set: { newValue in viewModel.toggleiCloudSync(newValue) }
            ))
            .accessibilityHint("Syncs your training data across all your Apple devices via iCloud")

            if viewModel.iCloudSyncEnabled {
                Label {
                    Text("Data syncs automatically across your devices.")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                } icon: {
                    Image(systemName: "checkmark.icloud.fill")
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                }
            } else {
                Label {
                    Text("Enable to sync training data across iPhone and iPad.")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                } icon: {
                    Image(systemName: "icloud.slash")
                        .foregroundStyle(.gray)
                        .accessibilityHidden(true)
                }
            }
        } header: {
            Text("iCloud")
        } footer: {
            Text("Changing this setting requires an app restart to take effect.")
        }
        .alert("Restart Required", isPresented: $viewModel.showRestartAlert) {
            Button("OK") {}
        } message: {
            Text("Please close and reopen UltraTrain for the iCloud sync change to take effect.")
        }
    }

    // MARK: - Sync Queue Section

    @ViewBuilder
    private var syncQueueSection: some View {
        if let syncService {
            Section {
                NavigationLink {
                    SyncQueueView(syncService: syncService)
                } label: {
                    HStack {
                        Label("Sync Queue", systemImage: "arrow.triangle.2.circlepath.circle")
                        Spacer()
                        if let monitor = syncStatusMonitor {
                            if monitor.hasFailures {
                                Text("\(monitor.failedCount) failed")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.danger)
                            } else if monitor.hasPending {
                                Text("\(monitor.pendingCount) pending")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.secondaryLabel)
                            } else {
                                Text("All synced")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Colors.secondaryLabel)
                            }
                        }
                    }
                }
                .accessibilityHint("View and manage pending and failed sync items")
            } header: {
                Text("Server Sync")
            }
        }
    }

    // MARK: - Data Retention Section

    @ViewBuilder
    private var dataRetentionSection: some View {
        if let settings = viewModel.appSettings {
            Section {
                Picker("Keep Data For", selection: Binding(
                    get: { settings.dataRetentionMonths },
                    set: { months in
                        Task { await viewModel.updateDataRetention(months) }
                    }
                )) {
                    Text("Forever").tag(0)
                    Text("6 Months").tag(6)
                    Text("12 Months").tag(12)
                    Text("24 Months").tag(24)
                }
                .accessibilityHint("Choose how long to keep training data")
            } header: {
                Text("Data Retention")
            } footer: {
                Text("Older data will be automatically removed. Set to Forever to keep all data.")
            }
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
            .accessibilityIdentifier("settings.exportButton")
            .accessibilityHint("Exports all your training data as a CSV file for sharing")
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
            .accessibilityIdentifier("settings.clearDataButton")
            .accessibilityHint("Permanently deletes all training data, plans, and settings")
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section("Account") {
            Button {
                viewModel.showingChangePassword = true
            } label: {
                Label("Change Password", systemImage: "key")
            }
            .accessibilityHint("Change your account password")

            Button(role: .destructive) {
                viewModel.showingLogoutConfirmation = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .accessibilityHint("Signs out of your UltraTrain account")

            Button(role: .destructive) {
                viewModel.showingDeleteAccountConfirmation = true
            } label: {
                if viewModel.isDeletingAccount {
                    ProgressView()
                } else {
                    Label("Delete Account", systemImage: "person.crop.circle.badge.minus")
                }
            }
            .disabled(viewModel.isDeletingAccount)
            .accessibilityIdentifier("settings.deleteAccountButton")
            .accessibilityHint("Permanently deletes your account and all data from the server")
        }
        .confirmationDialog(
            "Sign Out",
            isPresented: $viewModel.showingLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task { await viewModel.logout() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your local training data will remain on this device.")
        }
        .confirmationDialog(
            "Delete Account",
            isPresented: $viewModel.showingDeleteAccountConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                Task { await viewModel.deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all data from the server. This action cannot be undone.")
        }
        .onChange(of: viewModel.didLogout) { _, didLogout in
            if didLogout { onLogout?() }
        }
        .sheet(isPresented: $viewModel.showingChangePassword) {
            changePasswordSheet
        }
        .alert("Password Changed", isPresented: $viewModel.changePasswordSuccess) {
            Button("OK") {}
        } message: {
            Text("Your password has been changed successfully.")
        }
    }

    private var changePasswordSheet: some View {
        NavigationStack {
            Form {
                SecureField("Current Password", text: $viewModel.currentPassword)
                    .textContentType(.password)
                SecureField("New Password", text: $viewModel.newPassword)
                    .textContentType(.newPassword)
                SecureField("Confirm New Password", text: $viewModel.confirmPassword)
                    .textContentType(.newPassword)

                if let error = viewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.danger)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showingChangePassword = false
                        viewModel.currentPassword = ""
                        viewModel.newPassword = ""
                        viewModel.confirmPassword = ""
                        viewModel.error = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await viewModel.changePassword() }
                    } label: {
                        if viewModel.isChangingPassword {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(
                        viewModel.isChangingPassword
                        || viewModel.currentPassword.isEmpty
                        || viewModel.newPassword.isEmpty
                        || viewModel.confirmPassword.isEmpty
                    )
                }
            }
            .onChange(of: viewModel.changePasswordSuccess) { _, success in
                if success { viewModel.showingChangePassword = false }
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: AppConfiguration.appVersion)
            LabeledContent("Build", value: AppConfiguration.buildNumber)

            Link(destination: URL(string: "https://apps.apple.com/app/ultratrain")!) {
                Label("Rate on App Store", systemImage: "star")
            }
            .accessibilityHint("Opens the App Store to rate UltraTrain")

            Link(destination: URL(string: "mailto:support@ultratrain.app?subject=UltraTrain%20Feedback")!) {
                Label("Send Feedback", systemImage: "envelope")
            }
            .accessibilityHint("Opens an email to send feedback to the UltraTrain team")

            Link(destination: URL(string: "https://ultratrain.app/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            .accessibilityHint("Opens the privacy policy in your browser")

            Link(destination: URL(string: "https://ultratrain.app/terms")!) {
                Label("Terms of Service", systemImage: "doc.text")
            }
            .accessibilityHint("Opens the terms of service in your browser")
        }
    }

    // MARK: - Helpers

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let date = Calendar.current.date(from: DateComponents(hour: hour, minute: 0))!
        return formatter.string(from: date)
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
