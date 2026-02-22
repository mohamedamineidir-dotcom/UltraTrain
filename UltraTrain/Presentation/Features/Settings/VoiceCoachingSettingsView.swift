import SwiftUI

struct VoiceCoachingSettingsView: View {
    @Binding var config: VoiceCoachingConfig
    let onConfigChanged: (VoiceCoachingConfig) -> Void

    var body: some View {
        List {
            Section {
                Toggle("Voice Coaching", isOn: binding(\.enabled))
                    .accessibilityHint("Enables hands-free audio announcements during your runs")
            } footer: {
                Text("Hands-free audio announcements during your runs. Lowers music volume while speaking.")
            }

            if config.enabled {
                splitAnnouncementsSection
                eventAnnouncementsSection
                speechRateSection
            }
        }
        .navigationTitle("Voice Coaching")
    }

    // MARK: - Sections

    private var splitAnnouncementsSection: some View {
        Section("Split Announcements") {
            Toggle("Distance Splits", isOn: binding(\.announceDistanceSplits))
                .accessibilityHint("Announces your pace and distance at each kilometer or mile split")

            Toggle("Time Splits", isOn: binding(\.announceTimeSplits))
                .accessibilityHint("Announces your progress at regular time intervals")

            if config.announceTimeSplits {
                Picker("Interval", selection: binding(\.timeSplitIntervalMinutes)) {
                    ForEach([1, 2, 5, 10, 15, 20, 30], id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .accessibilityHint("How often time-based announcements are made")
            }
        }
    }

    private var eventAnnouncementsSection: some View {
        Section("Event Announcements") {
            Toggle("HR Zone Changes", isOn: binding(\.announceHRZoneChanges))
                .accessibilityHint("Announces when you move into a different heart rate zone")
            Toggle("Nutrition Reminders", isOn: binding(\.announceNutritionReminders))
                .accessibilityHint("Announces hydration and fuel reminders by voice")
            Toggle("Checkpoint Crossings", isOn: binding(\.announceCheckpoints))
                .accessibilityHint("Announces when you reach a race checkpoint")
            Toggle("Pacing Alerts", isOn: binding(\.announcePacingAlerts))
                .accessibilityHint("Announces when your pace deviates from the target")
            Toggle("Zone Drift Alerts", isOn: binding(\.announceZoneDriftAlerts))
                .accessibilityHint("Announces when you drift out of the target heart rate zone")
        }
    }

    private var speechRateSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Speech Rate")
                HStack {
                    Text("Slow")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .accessibilityHidden(true)
                    Slider(value: binding(\.speechRate), in: 0.3...0.7, step: 0.05)
                        .accessibilityLabel("Speech Rate")
                        .accessibilityValue(speechRateDescription)
                    Text("Fast")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private var speechRateDescription: String {
        let rate = config.speechRate
        if rate < 0.4 { return "Slow" }
        if rate < 0.55 { return "Normal" }
        return "Fast"
    }

    // MARK: - Helper

    private func binding<T>(_ keyPath: WritableKeyPath<VoiceCoachingConfig, T>) -> Binding<T> {
        Binding(
            get: { config[keyPath: keyPath] },
            set: { newValue in
                config[keyPath: keyPath] = newValue
                onConfigChanged(config)
            }
        )
    }
}
