import SwiftUI

struct WorkoutBlocksSection: View {
    let workout: IntervalWorkout
    var athlete: Athlete?
    /// One-line "why" derived from the session's `intervalFocus`.
    /// Rendered as a small accent line between name and description so
    /// the athlete sees *what* and *why* together. Pass `nil` to skip.
    var purposeLine: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(String(localized: "workout.title", defaultValue: "Workout"))
                    .font(.headline)
                Spacer()
                Text(workout.name)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            if let purposeLine, !purposeLine.isEmpty {
                Text(purposeLine)
                    .font(.footnote.italic())
                    .foregroundStyle(Theme.Colors.label.opacity(0.75))
                    .accessibilityLabel("Purpose: \(purposeLine)")
            }

            Text(workout.descriptionText)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            ForEach(renderedBlocks) { block in
                switch block {
                case .solo(let phase):
                    WorkoutBlockCard(phase: phase, easyPaceLabel: easyPaceLabel(for: phase))
                case .group(let work, let recovery):
                    workRecoveryGroup(work: work, recovery: recovery)
                }
            }

            if workout.totalWorkDuration > 0 {
                HStack(spacing: Theme.Spacing.lg) {
                    Label {
                        Text("\(String(localized: "workout.totalWork", defaultValue: "Work")): \(formatMinutes(workout.totalWorkDuration))")
                            .font(.caption)
                    } icon: {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.warning)
                    }

                    if workout.totalRecoveryDuration > 0 {
                        Label {
                            Text("\(String(localized: "workout.totalRecovery", defaultValue: "Recovery")): \(formatMinutes(workout.totalRecoveryDuration))")
                                .font(.caption)
                        } icon: {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.success)
                        }
                    }
                }
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .padding(.top, Theme.Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: Theme.Colors.accentColor)
    }

    // MARK: - Rendered Blocks

    /// One unit of rendering: either a single phase card, or a work
    /// phase grouped visually with the recovery phase that immediately
    /// follows it.
    private enum RenderedBlock: Identifiable {
        case solo(IntervalPhase)
        case group(work: IntervalPhase, recovery: IntervalPhase)

        var id: UUID {
            switch self {
            case .solo(let phase): phase.id
            case .group(let work, _): work.id
            }
        }
    }

    /// Walks `workout.phases` in their ORIGINAL order (never reorders,
    /// never assumes "one warmup, one work, one recovery, one cooldown"
    /// — a freeform, owner-edited workout can have any number of work/
    /// recovery pairs, or standalone blocks of any type interspersed
    /// between them) and pairs each repeated work phase with the
    /// specific recovery phase that follows it, not "the first recovery
    /// phase anywhere in the array" — the previous bucket-by-type
    /// approach silently dropped every recovery phase after the first
    /// and reused that one recovery for every repeat group.
    private var renderedBlocks: [RenderedBlock] {
        let phases = workout.phases
        var result: [RenderedBlock] = []
        var i = 0
        while i < phases.count {
            let phase = phases[i]
            if phase.phaseType == .work,
               phase.repeatCount > 1,
               i + 1 < phases.count,
               phases[i + 1].phaseType == .recovery {
                result.append(.group(work: phase, recovery: phases[i + 1]))
                i += 2
            } else {
                result.append(.solo(phase))
                i += 1
            }
        }
        return result
    }

    // MARK: - Work + Recovery Group

    private func workRecoveryGroup(work: IntervalPhase, recovery: IntervalPhase) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Repeat header
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "repeat")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Theme.Colors.secondaryLabel.opacity(0.5))
                    .clipShape(Circle())
                Text(String(localized: "workout.repeatTimes \(work.repeatCount)"))
                    .font(.subheadline.bold())
            }

            // Work → Recovery flow
            VStack(spacing: 0) {
                WorkoutBlockCard(phase: work)

                // Down arrow connector
                HStack {
                    Spacer()
                    Image(systemName: "arrow.down")
                        .font(.caption2.bold())
                        .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.5))
                    Spacer()
                }
                .padding(.vertical, 2)

                WorkoutBlockCard(phase: recovery, easyPaceLabel: easyPaceLabel(for: recovery))
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.secondaryLabel.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .strokeBorder(Theme.Colors.secondaryLabel.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func formatMinutes(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        return "\(mins)min"
    }

    private func easyPaceLabel(for phase: IntervalPhase) -> String? {
        guard phase.phaseType == .warmUp || phase.phaseType == .coolDown,
              let athlete,
              let threshold = athlete.thresholdPace60MinPerKm,
              threshold > 0 else { return nil }
        let range = PaceCalculator.paceRange(for: .easy, thresholdPacePerKm: threshold)
        return "~\(PaceCalculator.formatPace(range.min))-\(PaceCalculator.formatPace(range.max)) /km"
    }
}
