import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    init(
        athleteRepository: any AthleteRepository,
        appSettingsRepository: any AppSettingsRepository,
        clearAllDataUseCase: any ClearAllDataUseCase
    ) {
        _viewModel = State(initialValue: SettingsViewModel(
            athleteRepository: athleteRepository,
            appSettingsRepository: appSettingsRepository,
            clearAllDataUseCase: clearAllDataUseCase
        ))
    }

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            } else {
                unitsSection
                notificationsSection
                healthKitSection
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
            }
        }
    }

    // MARK: - HealthKit Section

    private var healthKitSection: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Apple Health")
                    Text("Connect to sync heart rate, workouts, and activity data")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            } icon: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
            }

            Button("Connect HealthKit") {
                // HealthKit integration will be wired in a future update
            }
            .disabled(true)
        } header: {
            Text("Health")
        } footer: {
            Text("HealthKit integration coming soon.")
        }
    }

    // MARK: - Data Management Section

    private var dataManagementSection: some View {
        Section("Data") {
            Label {
                Text("Export Training Data")
            } icon: {
                Image(systemName: "square.and.arrow.up")
            }
            .foregroundStyle(Theme.Colors.secondaryLabel)

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
