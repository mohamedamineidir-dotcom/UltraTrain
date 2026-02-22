import SwiftUI

struct SafetySettingsView: View {
    @State private var viewModel: SafetySettingsViewModel

    private let emergencyContactRepository: any EmergencyContactRepository

    init(
        appSettingsRepository: any AppSettingsRepository,
        emergencyContactRepository: any EmergencyContactRepository
    ) {
        _viewModel = State(initialValue: SafetySettingsViewModel(
            appSettingsRepository: appSettingsRepository
        ))
        self.emergencyContactRepository = emergencyContactRepository
    }

    var body: some View {
        Form {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                emergencyContactsLink
                sosSection
                fallDetectionSection
                noMovementSection
                safetyTimerSection
                alertSettingsSection
            }
        }
        .navigationTitle("Safety")
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
    }

    // MARK: - Emergency Contacts Link

    private var emergencyContactsLink: some View {
        Section {
            NavigationLink {
                EmergencyContactsView(repository: emergencyContactRepository)
            } label: {
                Label("Emergency Contacts", systemImage: "person.2.fill")
            }
            .accessibilityHint("Manage contacts who will be notified in an emergency")
        }
    }

    // MARK: - SOS Section

    private var sosSection: some View {
        Section {
            Toggle("SOS Alert", isOn: configBinding(\.sosEnabled))
                .accessibilityHint("Enables the SOS button during runs to send an emergency alert")
        } header: {
            Text("SOS")
        } footer: {
            Text("When enabled, an SOS button appears during active runs. Pressing it triggers an alert to your emergency contacts.")
        }
    }

    // MARK: - Fall Detection Section

    private var fallDetectionSection: some View {
        Section {
            Toggle("Fall Detection", isOn: configBinding(\.fallDetectionEnabled))
                .accessibilityHint("Automatically detects falls and triggers an alert if you don't respond")
        } header: {
            Text("Fall Detection")
        } footer: {
            Text("Uses motion sensors to detect a potential fall. If no response is detected, an alert is sent to your emergency contacts.")
        }
    }

    // MARK: - No Movement Section

    private var noMovementSection: some View {
        Section {
            Toggle("No Movement Alert", isOn: configBinding(\.noMovementAlertEnabled))
                .accessibilityHint("Alerts emergency contacts if no movement is detected for the specified duration")

            if viewModel.config.noMovementAlertEnabled {
                Stepper(
                    "Threshold: \(viewModel.config.noMovementThresholdMinutes) min",
                    value: configBinding(\.noMovementThresholdMinutes),
                    in: 1...30,
                    step: 1
                )
                .accessibilityLabel("No movement threshold")
                .accessibilityValue("\(viewModel.config.noMovementThresholdMinutes) minutes")
                .accessibilityHint("Time without movement before an alert is triggered")
            }
        } header: {
            Text("No Movement Alert")
        } footer: {
            Text("Triggers an alert if no movement is detected during an active run for the specified number of minutes.")
        }
    }

    // MARK: - Safety Timer Section

    private var safetyTimerSection: some View {
        Section {
            Toggle("Safety Timer", isOn: configBinding(\.safetyTimerEnabled))
                .accessibilityHint("Sends an alert if your run exceeds the expected duration")

            if viewModel.config.safetyTimerEnabled {
                Stepper(
                    "Duration: \(viewModel.config.safetyTimerDurationMinutes) min",
                    value: configBinding(\.safetyTimerDurationMinutes),
                    in: 30...720,
                    step: 30
                )
                .accessibilityLabel("Safety timer duration")
                .accessibilityValue("\(viewModel.config.safetyTimerDurationMinutes) minutes")
                .accessibilityHint("Maximum expected run duration before triggering an alert")
            }
        } header: {
            Text("Safety Timer")
        } footer: {
            Text("If your run exceeds this duration without being stopped, an alert is sent to your emergency contacts.")
        }
    }

    // MARK: - Alert Settings Section

    private var alertSettingsSection: some View {
        Section {
            Stepper(
                "Countdown: \(viewModel.config.countdownBeforeSendingSeconds)s",
                value: configBinding(\.countdownBeforeSendingSeconds),
                in: 10...120,
                step: 5
            )
            .accessibilityLabel("Countdown before sending alert")
            .accessibilityValue("\(viewModel.config.countdownBeforeSendingSeconds) seconds")
            .accessibilityHint("Time you have to cancel an alert before it is sent")

            Toggle("Include Location", isOn: configBinding(\.includeLocationInMessage))
                .accessibilityHint("Attaches your current GPS coordinates to the emergency alert message")
        } header: {
            Text("Alert Settings")
        } footer: {
            Text("A countdown gives you time to cancel a false alarm. Location sharing sends your GPS coordinates to emergency contacts.")
        }
    }

    // MARK: - Binding Helper

    private func configBinding<T: Equatable>(
        _ keyPath: WritableKeyPath<SafetyConfig, T>
    ) -> Binding<T> {
        Binding(
            get: { viewModel.config[keyPath: keyPath] },
            set: { newValue in
                viewModel.config[keyPath: keyPath] = newValue
                Task { await viewModel.save() }
            }
        )
    }
}
