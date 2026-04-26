import SwiftUI

/// Modal sheet for "I need to pause training" — illness or injury.
/// Wires to the existing `suspendTraining(forDays:reason:)` and
/// `reportMidCycleInjury(...)` methods. One sheet, two reasons,
/// minimal chrome — coach-style: quick to log when the athlete is
/// already feeling lousy.
struct PauseTrainingSheet: View {

    enum Mode: String, CaseIterable, Identifiable {
        case illness
        case injury
        var id: String { rawValue }

        var title: String {
            switch self {
            case .illness: return "I'm sick"
            case .injury:  return "I'm injured"
            }
        }

        var subtitle: String {
            switch self {
            case .illness:
                return "Cold, flu, GI bug. We'll skip the next few days and rebuild gradually."
            case .injury:
                return "Niggle, strain, sharp pain. Future plan will gate hard sessions until cleared."
            }
        }

        var iconName: String {
            switch self {
            case .illness: return "thermometer.medium"
            case .injury:  return "bandage.fill"
            }
        }

        var skipReason: SkipReason {
            switch self {
            case .illness: return .illness
            case .injury:  return .injury
            }
        }
    }

    let onSuspend: (Int, SkipReason) async -> Void
    let onReportInjury: (Int, Bool) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode = .illness
    @State private var days: Int = 3
    @State private var bumpPainFrequency: Bool = false
    @State private var isSubmitting: Bool = false

    private let dayOptions: [Int] = [1, 2, 3, 5, 7, 10, 14]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Reason", selection: $mode) {
                        ForEach(Mode.allCases) { option in
                            Label(option.title, systemImage: option.iconName)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 4)

                    Text(mode.subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .listRowSeparator(.hidden)
                }

                Section("How many days off?") {
                    Picker("Days", selection: $days) {
                        ForEach(dayOptions, id: \.self) { value in
                            Text(daysLabel(value)).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if mode == .injury {
                    Section {
                        Toggle(isOn: $bumpPainFrequency) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Persistent pain")
                                    .font(.subheadline.weight(.semibold))
                                Text("If pain is recurring, we'll switch base-phase to threshold-only and gate VO2max work in future plan rebuilds.")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.Colors.tertiaryLabel)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(submitLabel)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSubmitting)
                    .accessibilityIdentifier("trainingPlan.pause.submit")
                }
            }
            .navigationTitle("Pause Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var submitLabel: String {
        switch mode {
        case .illness: return "Skip next \(days) day\(days == 1 ? "" : "s")"
        case .injury:  return "Report injury · skip \(days) day\(days == 1 ? "" : "s")"
        }
    }

    private func daysLabel(_ value: Int) -> String {
        value == 1 ? "1 day" : "\(value) days"
    }

    private func submit() async {
        isSubmitting = true
        switch mode {
        case .illness:
            await onSuspend(days, .illness)
        case .injury:
            await onReportInjury(days, bumpPainFrequency)
        }
        isSubmitting = false
        dismiss()
    }
}
