import SwiftUI

struct WorkoutBlocksSection: View {
    let workout: IntervalWorkout
    var athlete: Athlete?

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

            Text(workout.descriptionText)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            ForEach(orderedPhases) { phase in
                if phase.phaseType == .work || phase.phaseType == .recovery {
                    // Work + recovery grouped visually
                    if phase.phaseType == .work {
                        workRecoveryGroup(work: phase)
                    }
                    // Skip standalone recovery — it's rendered inside the group
                } else {
                    WorkoutBlockCard(phase: phase, easyPaceLabel: easyPaceLabel(for: phase))
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
        .cardStyle()
    }

    // MARK: - Ordered Phases

    /// Reorders phases so work comes right before its matching recovery.
    private var orderedPhases: [IntervalPhase] {
        let warmUps = workout.phases.filter { $0.phaseType == .warmUp }
        let works = workout.phases.filter { $0.phaseType == .work }
        let coolDowns = workout.phases.filter { $0.phaseType == .coolDown }
        return warmUps + works + coolDowns
    }

    private var recoveryPhase: IntervalPhase? {
        workout.phases.first { $0.phaseType == .recovery }
    }

    // MARK: - Work + Recovery Group

    @ViewBuilder
    private func workRecoveryGroup(work: IntervalPhase) -> some View {
        if work.repeatCount > 1, let recovery = recoveryPhase {
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
        } else {
            WorkoutBlockCard(phase: work)
            if let recovery = recoveryPhase {
                WorkoutBlockCard(phase: recovery, easyPaceLabel: easyPaceLabel(for: recovery))
            }
        }
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
