import SwiftUI

struct DashboardHeroCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .largeTitle) private var daysCounterSize: CGFloat = 52
    @ScaledMetric(relativeTo: .largeTitle) private var trainingTitleSize: CGFloat = 32
    @State private var borderPulse = false

    let daysUntilRace: Int?
    let raceName: String?
    let currentPhase: TrainingPhase?
    let weeklyProgress: (completed: Int, total: Int)
    let weeklyDistanceKm: Double
    let weeklyTargetDistanceKm: Double
    var fitnessStatus: String?
    var formDescription: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .top) {
                daysSection
                Spacer()
                if weeklyProgress.total > 0 { progressRing }
            }

            gradientSeparator

            HStack(spacing: Theme.Spacing.lg) {
                if let phase = currentPhase { phaseBadge(phase) }
                distanceLabel
                if let fitness = fitnessStatus { fitnessBadge(fitness) }
            }
        }
        .padding(Theme.Spacing.lg)
        .futuristicGlassStyle(phaseTint: phaseAccentColor)
        .overlay(animatedBorder)
        .onAppear {
            withAnimation(.pulseGlow) { borderPulse = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Days Section

    private var daysSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            if let days = daysUntilRace {
                Text("\(days)")
                    .font(.system(size: daysCounterSize, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.label, Theme.Colors.label.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("days to go")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                Text("Training")
                    .font(.system(size: trainingTitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.label)
            }

            if let name = raceName {
                Text(name)
                    .font(.headline)
                    .tracking(Theme.LetterSpacing.tight)
                    .foregroundStyle(Theme.Colors.label.opacity(0.9))
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Theme.Colors.secondaryLabel.opacity(0.1), lineWidth: 5)
            Circle()
                .trim(from: 0, to: progressFraction)
                .stroke(
                    AngularGradient(
                        colors: [phaseAccentColor.opacity(0.3), phaseAccentColor],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: phaseAccentColor.opacity(0.4), radius: 4)
            VStack(spacing: 0) {
                Text("\(weeklyProgress.completed)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("/\(weeklyProgress.total)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .opacity(0.7)
            }
            .foregroundStyle(Theme.Colors.label)
        }
        .frame(width: 72, height: 72)
    }

    // MARK: - Separator & Badges

    private var gradientSeparator: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [phaseAccentColor.opacity(0.3), Theme.Colors.secondaryLabel.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }

    private func phaseBadge(_ phase: TrainingPhase) -> some View {
        Label(phase.displayName, systemImage: "chart.line.uptrend.xyaxis")
            .font(.caption.bold())
            .foregroundStyle(phaseAccentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    colors: [phaseAccentColor.opacity(0.15), phaseAccentColor.opacity(0.06)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
    }

    private var distanceLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "figure.run")
            Text(String(format: "%.0f / %.0f km", weeklyDistanceKm, weeklyTargetDistanceKm))
        }
        .font(.caption)
        .foregroundStyle(Theme.Colors.secondaryLabel)
    }

    private func fitnessBadge(_ fitness: String) -> some View {
        Label(fitness, systemImage: "heart.fill")
            .font(.caption.bold())
            .foregroundStyle(Theme.Colors.label)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.Colors.secondaryLabel.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Animated Border

    private var animatedBorder: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
            .stroke(
                Theme.Gradients.glowBorder(color: phaseAccentColor),
                lineWidth: borderPulse ? 1.0 : 0.5
            )
            .opacity(borderPulse ? 0.8 : 0.3)
    }

    // MARK: - Helpers

    private var progressFraction: Double {
        guard weeklyProgress.total > 0 else { return 0 }
        return Double(weeklyProgress.completed) / Double(weeklyProgress.total)
    }

    private var phaseAccentColor: Color {
        currentPhase?.color ?? Theme.Colors.accentColor
    }

    private var accessibilityDescription: String {
        var desc = ""
        if let days = daysUntilRace, let name = raceName {
            desc += "\(days) days until \(name). "
        }
        if let phase = currentPhase {
            desc += "\(phase.displayName) phase. "
        }
        if weeklyProgress.total > 0 {
            desc += "\(weeklyProgress.completed) of \(weeklyProgress.total) sessions completed. "
        }
        desc += String(format: "%.0f of %.0f km this week.", weeklyDistanceKm, weeklyTargetDistanceKm)
        return desc
    }
}
