import SwiftUI

struct VoiceCoachingSettingsView: View {
    @Binding var config: VoiceCoachingConfig
    let onConfigChanged: (VoiceCoachingConfig) -> Void

    var body: some View {
        List {
            Section {
                Toggle("Voice Coaching", isOn: binding(\.enabled))
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

            Toggle("Time Splits", isOn: binding(\.announceTimeSplits))

            if config.announceTimeSplits {
                Picker("Interval", selection: binding(\.timeSplitIntervalMinutes)) {
                    ForEach([1, 2, 5, 10, 15, 20, 30], id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
            }
        }
    }

    private var eventAnnouncementsSection: some View {
        Section("Event Announcements") {
            Toggle("HR Zone Changes", isOn: binding(\.announceHRZoneChanges))
            Toggle("Nutrition Reminders", isOn: binding(\.announceNutritionReminders))
            Toggle("Checkpoint Crossings", isOn: binding(\.announceCheckpoints))
            Toggle("Pacing Alerts", isOn: binding(\.announcePacingAlerts))
            Toggle("Zone Drift Alerts", isOn: binding(\.announceZoneDriftAlerts))
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
                    Slider(value: binding(\.speechRate), in: 0.3...0.7, step: 0.05)
                    Text("Fast")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
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
