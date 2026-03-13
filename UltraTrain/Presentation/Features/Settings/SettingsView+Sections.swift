import SwiftUI

// MARK: - Extracted Sections

extension SettingsView {

    // MARK: - Units Section

    @ViewBuilder
    var unitsSection: some View {
        if let athlete = viewModel.athlete {
            Section("Units") {
                Picker("Measurement System", selection: Binding(
                    get: { athlete.preferredUnit },
                    set: { newUnit in
                        Task { await viewModel.updateUnitPreference(newUnit) }
                    }
                )) {
                    ForEach(UnitPreference.allCases, id: \.self) { unit in
                        Text(unit.settingsDisplayName).tag(unit)
                    }
                }
            }
        }
    }

    // MARK: - Training Preferences Section

    @ViewBuilder
    var trainingPreferencesSection: some View {
        if let athlete = viewModel.athlete {
            Section {
                Picker("Training Style", selection: Binding(
                    get: { athlete.trainingPhilosophy },
                    set: { newPhilosophy in
                        Task { await viewModel.updateTrainingPhilosophy(newPhilosophy) }
                    }
                )) {
                    ForEach(TrainingPhilosophy.allCases, id: \.self) { philosophy in
                        Text(philosophy.displayName).tag(philosophy)
                    }
                }
                .accessibilityHint("Choose how hard you want to train: enjoyment, balanced, or performance")

                Stepper(
                    "Runs per week: \(athlete.preferredRunsPerWeek ?? 4)",
                    value: Binding(
                        get: { athlete.preferredRunsPerWeek ?? 4 },
                        set: { newValue in
                            Task { await viewModel.updatePreferredRunsPerWeek(newValue) }
                        }
                    ),
                    in: 3...6
                )
                .accessibilityHint("Set how many running sessions per week you prefer")
            } header: {
                Text("Training Preferences")
            } footer: {
                Text("These preferences affect how your training plan is generated. Regenerate your plan to apply changes.")
            }
        }
    }

    // MARK: - Appearance Section

    @ViewBuilder
    var appearanceSection: some View {
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

    // MARK: - Language Section

    @ViewBuilder
    var languageSection: some View {
        if viewModel.appSettings != nil {
            Section {
                Picker("Language", selection: Binding(
                    get: { viewModel.selectedLanguage },
                    set: { newLang in
                        Task { await viewModel.updatePreferredLanguage(newLang) }
                    }
                )) {
                    Text("System").tag("system")
                    Text("English").tag("en")
                    Text("Français").tag("fr")
                }
                .accessibilityHint("Choose the app language")
            } header: {
                Text("Language")
            } footer: {
                Text("Changing the language requires restarting the app.")
            }
        }
    }

    // MARK: - Run Tracking Section

    @ViewBuilder
    var runTrackingSection: some View {
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

    // MARK: - Safety Section

    @ViewBuilder
    var safetySection: some View {
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

    // MARK: - Security Section

    @ViewBuilder
    var securitySection: some View {
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
}

// MARK: - UnitPreference Display

extension UnitPreference {
    var settingsDisplayName: String {
        switch self {
        case .metric: "Metric (km, m, kg)"
        case .imperial: "Imperial (mi, ft, lb)"
        }
    }
}
