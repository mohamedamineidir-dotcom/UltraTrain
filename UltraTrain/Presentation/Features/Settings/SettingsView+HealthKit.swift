import SwiftUI

// MARK: - HealthKit Section

extension SettingsView {
    var healthKitSection: some View {
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
}
