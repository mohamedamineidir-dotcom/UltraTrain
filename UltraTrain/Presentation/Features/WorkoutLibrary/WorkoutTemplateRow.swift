import SwiftUI

struct WorkoutTemplateRow: View {
    let template: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(template.name)
                    .font(.subheadline.bold())

                Spacer()

                if template.isUserCreated {
                    Text("Custom")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.Colors.primary.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: Theme.Spacing.md) {
                if template.targetDistanceKm > 0 {
                    Label(
                        String(format: "%.0f km", template.targetDistanceKm),
                        systemImage: "ruler"
                    )
                }

                if template.targetElevationGainM > 0 {
                    Label(
                        String(format: "%.0f m", template.targetElevationGainM),
                        systemImage: "arrow.up.right"
                    )
                }

                Label(
                    RunStatisticsCalculator.formatDuration(template.estimatedDuration),
                    systemImage: "clock"
                )
            }
            .font(.caption)
            .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}
