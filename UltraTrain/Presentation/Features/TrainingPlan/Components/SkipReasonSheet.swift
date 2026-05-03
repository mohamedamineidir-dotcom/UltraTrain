import SwiftUI

struct SkipReasonSheet: View {
    let sessionType: SessionType
    let onConfirm: (SkipReason, MenstrualSymptomCluster?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: SkipReason?
    @State private var selectedCluster: MenstrualSymptomCluster?

    /// Confirm requires a reason. If menstrualCycle is picked, a
    /// cluster sub-selection is also required so the adaptation
    /// calculator gets the right symptom signal — McNulty (2020):
    /// symptom-driven, never phase-based.
    private var canConfirm: Bool {
        guard let reason = selectedReason else { return false }
        if reason == .menstrualCycle { return selectedCluster != nil }
        return true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Text("Why are you skipping this session?")
                        .font(.headline)
                        .padding(.horizontal, Theme.Spacing.md)

                    Text("This helps us adapt your training plan intelligently.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .padding(.horizontal, Theme.Spacing.md)

                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(SkipReason.allCases, id: \.self) { reason in
                            reasonRow(reason)
                            if reason == .menstrualCycle && selectedReason == .menstrualCycle {
                                menstrualClusterSection
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
                .padding(.vertical, Theme.Spacing.md)
                .animation(.easeInOut(duration: 0.2), value: selectedReason)
            }
            .navigationTitle("Skip Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Skip") {
                        if let reason = selectedReason {
                            // Only forward the cluster when the reason
                            // matches — defensive against UI state lag.
                            let cluster = reason == .menstrualCycle ? selectedCluster : nil
                            onConfirm(reason, cluster)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!canConfirm)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Menstrual cluster section

    /// Inline sub-prompt that appears under the menstrualCycle row
    /// when it's selected. Visual language matches the parent reason
    /// rows: full-width glass cards with accent-tinted fill + stroke
    /// when selected, and a custom icon per cluster so the choice
    /// feels deliberate rather than a generic radio list. Indigo
    /// accent throughout — same hue as the parent row's selected
    /// state so the section reads as nested children.
    private var menstrualClusterSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(Color.indigo)
                Text("Which describes today best?")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.label)
            }
            .padding(.top, Theme.Spacing.sm)

            Text("We tailor the suggestion to the symptom — never to judge.")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(MenstrualSymptomCluster.allCases, id: \.self) { cluster in
                    clusterRow(cluster)
                }
            }
            .padding(.top, Theme.Spacing.xs)
        }
        .padding(.bottom, Theme.Spacing.sm)
    }

    private func clusterRow(_ cluster: MenstrualSymptomCluster) -> some View {
        let isSelected = selectedCluster == cluster
        let accent = Color.indigo
        return Button {
            selectedCluster = cluster
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                // Compact icon tile — visually distinct from the
                // parent row's plain icon (signals "sub-option") but
                // smaller than the parent rhythm so the nested rows
                // don't outweigh their parent.
                ZStack {
                    Circle()
                        .fill(isSelected ? accent : accent.opacity(0.15))
                        .frame(width: 26, height: 26)
                    Image(systemName: cluster.iconName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? .white : accent)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(cluster.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.Colors.label)
                        .lineLimit(1)
                    Text(cluster.hint)
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .lineLimit(1)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(accent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(isSelected ? accent.opacity(0.18) : Theme.Colors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(
                        isSelected ? accent : Color.clear,
                        lineWidth: isSelected ? 1.5 : 0
                    )
            )
            .shadow(
                color: isSelected ? accent.opacity(0.22) : .clear,
                radius: isSelected ? 10 : 0,
                y: isSelected ? 3 : 0
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cluster.displayName)
        .accessibilityHint(cluster.hint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Reason Row

    private func reasonRow(_ reason: SkipReason) -> some View {
        let isSelected = selectedReason == reason
        return Button {
            selectedReason = reason
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: reason.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : reason.color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(reason.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isSelected ? .white : Theme.Colors.label)

                    Text(reason.hint)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : Theme.Colors.secondaryLabel)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(isSelected ? reason.color : Theme.Colors.secondaryBackground)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(reason.displayName)
        .accessibilityHint(reason.hint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - SkipReason UI Properties

extension SkipReason {
    var displayName: String {
        switch self {
        case .noTime:         "I don't have time"
        case .fatigue:        "I feel tired or fatigued"
        case .noMotivation:   "No motivation today"
        case .soreness:       "Muscle soreness or pain"
        case .illness:        "Feeling unwell or sick"
        case .weather:        "Bad weather or conditions"
        case .injury:         "I have an injury or sharp pain"
        case .other:          "Other reason"
        case .menstrualCycle: "Menstrual cycle"
        }
    }

    var hint: String {
        switch self {
        case .noTime:         "Work, family, or schedule conflict"
        case .fatigue:        "Legs heavy, body tired, need rest"
        case .noMotivation:   "Mentally not feeling it today"
        case .soreness:       "Joint discomfort or muscle tightness"
        case .illness:        "Cold, flu, or general malaise"
        case .injury:         "Strain, sprain, or acute pain"
        case .weather:        "Rain, extreme heat, unsafe trail"
        case .other:          "Something else"
        case .menstrualCycle: "Cramps, PMS, or period symptoms"
        }
    }

    var icon: String {
        switch self {
        case .noTime:         "clock"
        case .fatigue:        "battery.25percent"
        case .noMotivation:   "brain.head.profile"
        case .soreness:       "bandage"
        case .illness:        "cross.case"
        case .injury:         "exclamationmark.triangle"
        case .weather:        "cloud.rain"
        case .other:          "ellipsis.circle"
        case .menstrualCycle: "calendar.badge.clock"
        }
    }

    var color: Color {
        switch self {
        case .noTime:         .blue
        case .fatigue:        .orange
        case .noMotivation:   .purple
        case .soreness:       .red
        case .illness:        .pink
        case .injury:         .red
        case .weather:        .cyan
        case .other:          .gray
        case .menstrualCycle: .indigo
        }
    }
}

// MARK: - MenstrualSymptomCluster UI Properties

extension MenstrualSymptomCluster {
    var displayName: String {
        switch self {
        case .bleedDay:      "Bleed-day symptoms"
        case .prePeriod:     "Pre-period (PMS) symptoms"
        case .asymptomatic:  "Just bleeding, no symptoms"
        case .unspecified:   "Prefer not to specify"
        }
    }

    var hint: String {
        switch self {
        case .bleedDay:      "Cramps, heavy flow, fatigue"
        case .prePeriod:     "Mood, GI, sleep, breast pain, bloating"
        case .asymptomatic:  "Logged for tracking — no plan change"
        case .unspecified:   "Skip will be logged without a sub-reason"
        }
    }

    var iconName: String {
        switch self {
        case .bleedDay:      "drop.fill"
        case .prePeriod:     "wind"
        case .asymptomatic:  "checkmark.shield.fill"
        case .unspecified:   "ellipsis.circle.fill"
        }
    }
}
