import SwiftUI

struct DashboardNextSessionCard: View {
    @Environment(\.unitPreference) private var units
    let session: TrainingSession?
    let hasPlan: Bool
    let currentPhase: TrainingPhase?
    let onStartRun: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Next Session")
                    .font(.headline)
                if let currentPhase {
                    PhaseBadge(phase: currentPhase)
                }
                Spacer()
            }

            if let session {
                sessionContent(session)
            } else {
                Text(hasPlan
                     ? "All sessions completed this week!"
                     : "Generate a training plan to see your next session")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func sessionContent(_ session: TrainingSession) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: session.type.icon)
                    .font(.title2)
                    .foregroundStyle(session.intensity.color)
                    .frame(width: 40)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.type.displayName)
                        .fontWeight(.medium)
                    Text(session.date.formatted(.dateTime.weekday(.wide).month().day()))
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    if session.plannedDistanceKm > 0 {
                        Text(UnitFormatter.formatDistance(session.plannedDistanceKm, unit: units))
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                    if session.isGutTrainingRecommended {
                        GutTrainingBadge()
                    }
                }

                Spacer()

                Text(session.intensity.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(session.intensity.color)
                    .clipShape(Capsule())
            }

            Button(action: onStartRun) {
                Label("Start Run", systemImage: "figure.run")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }
}
