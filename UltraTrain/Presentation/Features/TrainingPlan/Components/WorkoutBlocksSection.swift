import SwiftUI

struct WorkoutBlocksSection: View {
    let workout: IntervalWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Workout")
                    .font(.headline)
                Spacer()
                Text(workout.name)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Text(workout.descriptionText)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)

            ForEach(workout.phases) { phase in
                WorkoutBlockCard(phase: phase)
            }

            if workout.totalWorkDuration > 0 {
                HStack(spacing: Theme.Spacing.lg) {
                    Label {
                        Text("Work: \(formatMinutes(workout.totalWorkDuration))")
                            .font(.caption)
                    } icon: {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.warning)
                    }

                    if workout.totalRecoveryDuration > 0 {
                        Label {
                            Text("Recovery: \(formatMinutes(workout.totalRecoveryDuration))")
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

    private func formatMinutes(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        return "\(mins)min"
    }
}
