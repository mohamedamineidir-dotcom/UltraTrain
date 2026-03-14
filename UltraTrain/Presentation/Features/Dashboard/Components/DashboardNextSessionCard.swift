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
        .futuristicGlassStyle(phaseTint: currentPhase?.color)
    }

    private func sessionContent(_ session: TrainingSession) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                // Icon glow circle
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [session.intensity.color.opacity(0.2), session.intensity.color.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    Image(systemName: session.type.icon)
                        .font(.title3)
                        .foregroundStyle(session.intensity.color)
                        .shadow(color: session.intensity.color.opacity(0.4), radius: 3)
                }
                .shadow(color: session.intensity.color.opacity(0.2), radius: 6)
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
                    .shadow(color: session.intensity.color.opacity(0.4), radius: 4)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(sessionAccessibilityLabel(session))

            // Warm coral gradient CTA
            Button(action: onStartRun) {
                Label("Start Run", systemImage: "figure.run")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        Theme.Gradients.warmCoralCTA,
                        in: RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    )
                    .shadow(color: Theme.Colors.warmCoral.opacity(0.3), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("dashboard.startRunButton")
            .accessibilityHint("Starts GPS tracking for this session")
        }
        .accessibilityElement(children: .contain)
    }

    private func sessionAccessibilityLabel(_ session: TrainingSession) -> String {
        var label = "\(session.type.displayName), \(session.date.formatted(.dateTime.weekday(.wide).month().day())), \(session.intensity.displayName) intensity"
        if session.plannedDistanceKm > 0 {
            label += ", \(AccessibilityFormatters.distance(session.plannedDistanceKm, unit: units))"
        }
        if session.isGutTrainingRecommended {
            label += ", gut training recommended"
        }
        return label
    }
}
