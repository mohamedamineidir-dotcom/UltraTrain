import SwiftUI

struct SessionRowView: View {
    @Environment(\.unitPreference) private var units
    let session: TrainingSession
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Button(action: onToggle) {
                Circle()
                    .fill(toggleBackground)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: toggleIcon)
                            .font(.caption.bold())
                            .foregroundStyle(toggleForeground)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(statusAccessibilityLabel)
            .accessibilityHint("Double-tap to toggle completion")

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: session.type.icon)
                        .font(.caption)
                        .foregroundStyle(session.isSkipped ? Theme.Colors.secondaryLabel : .white)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(session.isSkipped ? Theme.Colors.secondaryLabel.opacity(0.2) : session.intensity.color.opacity(0.85))
                        )
                        .accessibilityHidden(true)

                    Text(session.type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .strikethrough(session.isCompleted || session.isSkipped)

                    if session.isSkipped {
                        Text(String(localized: "session.skipped", defaultValue: "Skipped"))
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.orange.opacity(0.15))
                            .clipShape(Capsule())
                    } else if session.type != .rest && !session.isCompleted {
                        Text(session.intensity.displayName)
                            .font(.caption2)
                            .foregroundStyle(session.intensity.color)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(session.intensity.color.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                if hasWorkoutDescription {
                    Text(session.description)
                        .font(.caption)
                        .foregroundStyle(session.intensity.color)
                        .lineLimit(1)
                } else if isTimeBased && session.plannedDuration > 0 {
                    Text(formattedTimeBased)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                } else if session.plannedDistanceKm > 0 {
                    Text(UnitFormatter.formatDistance(session.plannedDistanceKm, unit: units))
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }

                if hasBadges {
                    HStack(spacing: Theme.Spacing.xs) {
                        if session.isKeySession && !session.isSkipped && !session.isCompleted {
                            Text(String(localized: "session.key", defaultValue: "Key"))
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Theme.Colors.primary)
                                .clipShape(Capsule())
                        }

                        if session.isGutTrainingRecommended && !session.isSkipped {
                            GutTrainingBadge()
                        }
                    }
                }
            }

            Spacer()

            dayLabel
        }
        .padding(.vertical, session.type == .rest ? Theme.Spacing.xs : Theme.Spacing.sm)
        .padding(.horizontal, session.isKeySession && !session.isSkipped && !session.isCompleted ? Theme.Spacing.xs : 0)
        .background(
            session.isKeySession && !session.isSkipped && !session.isCompleted
                ? Theme.Colors.primary.opacity(0.04)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .opacity(session.type == .rest || session.isSkipped ? 0.4 : 1.0)
        .accessibilityElement(children: .combine)
    }

    private var dayLabel: some View {
        let isToday = Calendar.current.isDateInToday(session.date)
        return Text(session.date.formatted(.dateTime.weekday(.abbreviated)))
            .font(.caption.weight(isToday ? .bold : .regular))
            .foregroundStyle(isToday ? .white : Theme.Colors.secondaryLabel)
            .padding(.horizontal, isToday ? 8 : 0)
            .padding(.vertical, isToday ? 3 : 0)
            .background(isToday ? Theme.Colors.accentColor : .clear, in: Capsule())
    }

    private var toggleBackground: Color {
        if session.isCompleted { return Theme.Colors.success }
        if session.isSkipped { return .orange.opacity(0.2) }
        return session.intensity.color.opacity(0.15)
    }

    private var toggleForeground: Color {
        if session.isCompleted { return .white }
        if session.isSkipped { return .orange }
        return session.intensity.color
    }

    private var toggleIcon: String {
        if session.isCompleted { return "checkmark" }
        if session.isSkipped { return "forward.fill" }
        return ""
    }

    private var hasBadges: Bool {
        (session.isKeySession && !session.isSkipped && !session.isCompleted)
            || (session.isGutTrainingRecommended && !session.isSkipped)
    }

    private var hasWorkoutDescription: Bool {
        (session.type == .intervals || session.type == .verticalGain || session.type == .tempo)
            && session.intervalWorkoutId != nil
            && session.description.contains("×")
    }

    private var isTimeBased: Bool {
        session.type == .longRun || session.type == .backToBack
    }

    private var formattedTimeBased: String {
        let hours = Int(session.plannedDuration) / 3600
        let minutes = (Int(session.plannedDuration) % 3600) / 60
        let timeStr = hours > 0 ? "\(hours)h\(String(format: "%02d", minutes))" : "\(minutes)min"
        if session.plannedElevationGainM > 0 {
            let elev = UnitFormatter.formatElevation(session.plannedElevationGainM, unit: units)
            return "\(timeStr) · \(elev) D+"
        }
        return timeStr
    }

    private var statusIcon: String {
        if session.isCompleted { return "checkmark.circle.fill" }
        if session.isSkipped { return "forward.circle.fill" }
        return "circle"
    }

    private var statusAccessibilityLabel: String {
        if session.isCompleted { return "\(session.type.displayName), completed" }
        if session.isSkipped { return "\(session.type.displayName), skipped" }
        return "Mark \(session.type.displayName) as completed"
    }

    private var statusColor: Color {
        if session.isCompleted { return Theme.Colors.success }
        if session.isSkipped { return .orange }
        return Theme.Colors.secondaryLabel
    }
}

extension SessionType {
    var displayName: String {
        switch self {
        case .longRun:       String(localized: "session.longRun", defaultValue: "Long Run")
        case .tempo:         String(localized: "session.tempo", defaultValue: "Tempo")
        case .intervals:     String(localized: "session.intervals", defaultValue: "Intervals")
        case .verticalGain:  String(localized: "session.verticalGain", defaultValue: "Vertical Gain")
        case .backToBack:    String(localized: "session.backToBack", defaultValue: "Long Run (B2B)")
        case .recovery:      String(localized: "session.recovery", defaultValue: "Recovery")
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
        case .recovery:      "heart.fill"
        case .crossTraining: "figure.mixed.cardio"
        case .rest:          "bed.double.fill"
        }
    }
}

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
