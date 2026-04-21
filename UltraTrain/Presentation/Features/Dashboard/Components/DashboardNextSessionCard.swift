import SwiftUI

struct DashboardNextSessionCard: View {
    @Environment(\.unitPreference) private var units
    let session: TrainingSession?
    let hasPlan: Bool
    let currentPhase: TrainingPhase?
    let onStartRun: () -> Void
    /// Present the validation sheet (statistics entry, sync app, quick-complete).
    var onValidate: (() -> Void)? = nil
    /// Present the skip-reason sheet.
    var onSkip: (() -> Void)? = nil

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

            // Primary CTA — Start Run (warm coral gradient)
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

            // Secondary row — Validate + Skip. Same flows as the Training Plan
            // tab; validating opens the stats-entry sheet, skipping opens the
            // reason picker and feeds the plan-adjustment pipeline.
            if onValidate != nil || onSkip != nil {
                HStack(spacing: Theme.Spacing.sm) {
                    if let onValidate {
                        Button(action: onValidate) {
                            Label("Validate", systemImage: "checkmark.circle")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.xs)
                        }
                        .buttonStyle(.bordered)
                        .tint(Theme.Colors.success)
                        .accessibilityIdentifier("dashboard.validateSessionButton")
                    }
                    if let onSkip {
                        Button(action: onSkip) {
                            Label("Skip", systemImage: "forward.fill")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.xs)
                        }
                        .buttonStyle(.bordered)
                        .tint(Theme.Colors.warning)
                        .accessibilityIdentifier("dashboard.skipSessionButton")
                    }
                }
            }
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
