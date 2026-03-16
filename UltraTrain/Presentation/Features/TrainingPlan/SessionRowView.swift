import SwiftUI

struct SessionRowView: View {
    @Environment(\.unitPreference) private var units
    let session: TrainingSession
    let onToggle: () -> Void

    var body: some View {
        if session.type == .rest {
            restRow
        } else {
            activeRow
        }
    }

    // MARK: - Rest Row (minimal)

    private var restRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(Theme.Colors.secondaryLabel.opacity(0.1))
                .frame(width: 24, height: 24)

            Text(session.type.displayName)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            Spacer()

            dayLabel
        }
        .padding(.vertical, Theme.Spacing.xs)
        .opacity(0.5)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Active Session Row

    private var activeRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Icon glow circle with toggle overlay
            iconGlow

            // Session info
            VStack(alignment: .leading, spacing: 3) {
                topLine
                bottomLine
            }

            Spacer()

            // Metrics + Day
            VStack(alignment: .trailing, spacing: 3) {
                if session.plannedDistanceKm > 0 {
                    Text(UnitFormatter.formatDistance(session.plannedDistanceKm, unit: units))
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(session.isCompleted || session.isSkipped
                            ? Theme.Colors.secondaryLabel : Theme.Colors.label)
                } else if session.plannedDuration > 0 {
                    Text(formattedDuration)
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(session.isCompleted || session.isSkipped
                            ? Theme.Colors.secondaryLabel : Theme.Colors.label)
                }
                dayLabel
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
        .padding(.horizontal, Theme.Spacing.xs)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
        .opacity(session.isSkipped ? 0.5 : 1.0)
        .accessibilityElement(children: .combine)
    }

    private var iconGlow: some View {
        Button(action: onToggle) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: session.isCompleted
                                ? [Theme.Colors.success.opacity(0.25), Theme.Colors.success.opacity(0.1)]
                                : [accentColor.opacity(0.15), accentColor.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                if session.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.Colors.success)
                } else if session.isSkipped {
                    Image(systemName: "forward.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    Image(systemName: session.type.icon)
                        .font(.caption)
                        .foregroundStyle(accentColor)
                }
            }
            .shadow(color: session.isCompleted
                ? Theme.Colors.success.opacity(0.3) : accentColor.opacity(0.15),
                radius: 4)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: session.isCompleted)
        .accessibilityLabel(statusAccessibilityLabel)
        .accessibilityHint("Double-tap to toggle completion")
    }

    // MARK: - Top Line (icon + name + badges)

    private var topLine: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(session.type.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(session.isCompleted || session.isSkipped
                    ? Theme.Colors.secondaryLabel : Theme.Colors.label)
                .strikethrough(session.isSkipped)

            if session.isSkipped {
                skippedBadge
            }

            if session.isKeySession && !session.isSkipped && !session.isCompleted {
                keyBadge
            }

            if session.linkedRunId != nil {
                Image(systemName: "link.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.success)
                    .accessibilityLabel("Linked to activity")
            }
        }
    }

    // MARK: - Bottom Line (elevation + gut training)

    private var bottomLine: some View {
        HStack(spacing: Theme.Spacing.xs) {
            if !session.isSkipped && !session.isCompleted {
                Text(session.intensity.displayName)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(accentColor)
            }

            if session.plannedDuration > 0 && session.plannedDistanceKm > 0 {
                Text("·").font(.caption2).foregroundStyle(Theme.Colors.tertiaryLabel)
                Text(formattedDuration)
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            if session.plannedElevationGainM > 0 {
                Text("·").font(.caption2).foregroundStyle(Theme.Colors.tertiaryLabel)
                Label("\(UnitFormatter.formatElevation(session.plannedElevationGainM, unit: units))", systemImage: "mountain.2.fill")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            if session.isGutTrainingRecommended && !session.isSkipped {
                GutTrainingBadge()
            }
        }
    }

    // MARK: - Components

    private var dayLabel: some View {
        let isToday = Calendar.current.isDateInToday(session.date)
        return Text(session.date.formatted(.dateTime.weekday(.abbreviated)))
            .font(.caption.weight(isToday ? .bold : .regular))
            .foregroundStyle(isToday ? .white : Theme.Colors.secondaryLabel)
            .padding(.horizontal, isToday ? 8 : 0)
            .padding(.vertical, isToday ? 3 : 0)
            .background(isToday ? Theme.Colors.accentColor : .clear, in: Capsule())
    }

    private var skippedBadge: some View {
        Text(String(localized: "session.skipped", defaultValue: "Skipped"))
            .font(.caption2)
            .foregroundStyle(.orange)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(.orange.opacity(0.15))
            .clipShape(Capsule())
    }

    private var keyBadge: some View {
        Text(String(localized: "session.key", defaultValue: "Key"))
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(Theme.Colors.primary)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var rowBackground: some View {
        if session.isCompleted {
            Theme.Colors.success.opacity(0.04)
        } else if session.isKeySession && !session.isSkipped {
            Theme.Colors.primary.opacity(0.04)
        } else {
            Color.clear
        }
    }

    // MARK: - Formatting

    private var formattedDuration: String {
        let total = Int(session.plannedDuration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return hours > 0 ? "\(hours)h\(String(format: "%02d", minutes))" : "\(minutes)min"
    }

    private var accentColor: Color {
        session.isSkipped ? Theme.Colors.secondaryLabel : session.intensity.color
    }

    // MARK: - Toggle State

    private var statusAccessibilityLabel: String {
        if session.isCompleted { return "\(session.type.displayName), completed" }
        if session.isSkipped { return "\(session.type.displayName), skipped" }
        return "Mark \(session.type.displayName) as completed"
    }
}

// MARK: - SessionType Extensions

extension SessionType {
    var displayName: String {
        switch self {
        case .longRun:       String(localized: "session.longRun", defaultValue: "Long Run")
        case .tempo:         String(localized: "session.tempo", defaultValue: "Tempo")
        case .intervals:     String(localized: "session.intervals", defaultValue: "Intervals")
        case .verticalGain:  String(localized: "session.verticalGain", defaultValue: "Vertical Gain")
        case .backToBack:    String(localized: "session.backToBack", defaultValue: "Long Run (B2B)")
        case .recovery:      String(localized: "session.recovery", defaultValue: "Base Endurance")
        case .crossTraining: String(localized: "session.crossTraining", defaultValue: "Cross-Training")
        case .rest:          String(localized: "session.rest", defaultValue: "Rest")
        }
    }

    var icon: String {
        switch self {
        case .longRun:       "figure.run"
        case .tempo:         "speedometer"
        case .intervals:     "timer"
        case .verticalGain:  "mountain.2.fill"
        case .backToBack:    "arrow.triangle.2.circlepath"
        case .recovery:      "figure.walk"
        case .crossTraining: "figure.mixed.cardio"
        case .rest:          "bed.double.fill"
        }
    }
}

// MARK: - Intensity Extensions

extension Intensity {
    var color: Color {
        switch self {
        case .easy:      Theme.Colors.zone2
        case .moderate:  Theme.Colors.zone3
        case .hard:      Theme.Colors.zone4
        case .maxEffort: Theme.Colors.zone5
        }
    }

    var displayName: String {
        switch self {
        case .easy:      String(localized: "intensity.easy", defaultValue: "Easy")
        case .moderate:  String(localized: "intensity.moderate", defaultValue: "Moderate")
        case .hard:      String(localized: "intensity.hard", defaultValue: "Hard")
        case .maxEffort: String(localized: "intensity.maxEffort", defaultValue: "Max Effort")
        }
    }
}
