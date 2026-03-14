import SwiftUI

struct DashboardHeroCard: View {
    @ScaledMetric(relativeTo: .largeTitle) private var daysCounterSize: CGFloat = 52
    @ScaledMetric(relativeTo: .largeTitle) private var trainingTitleSize: CGFloat = 32

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
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    if let days = daysUntilRace {
                        Text("\(days)")
                            .font(.system(size: daysCounterSize, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.Colors.label)
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
                            .foregroundStyle(Theme.Colors.label.opacity(0.9))
                            .lineLimit(1)
                    }
                }

                Spacer()

                if weeklyProgress.total > 0 {
                    progressRing
                }
            }

            Divider()
                .overlay(Theme.Colors.secondaryLabel.opacity(0.2))

            HStack(spacing: Theme.Spacing.lg) {
                if let phase = currentPhase {
                    Label(phase.displayName, systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption.bold())
                        .foregroundStyle(phaseAccentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(phaseAccentColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                HStack(spacing: 4) {
                    Image(systemName: "figure.run")
                    Text(String(format: "%.0f / %.0f km", weeklyDistanceKm, weeklyTargetDistanceKm))
                }
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)

                if let fitness = fitnessStatus {
                    Label(fitness, systemImage: "heart.fill")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.Colors.label)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.secondaryLabel.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(Theme.Colors.secondaryLabel.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: Theme.Colors.shadow, radius: 4, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Theme.Colors.secondaryLabel.opacity(0.15), lineWidth: 5)
            Circle()
                .trim(from: 0, to: progressFraction)
                .stroke(
                    phaseAccentColor,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: phaseAccentColor.opacity(0.4), radius: 3)
            VStack(spacing: 0) {
                Text("\(weeklyProgress.completed)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text("/\(weeklyProgress.total)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .opacity(0.8)
            }
            .foregroundStyle(Theme.Colors.label)
        }
        .frame(width: 56, height: 56)
    }

    private var progressFraction: Double {
        guard weeklyProgress.total > 0 else { return 0 }
        return Double(weeklyProgress.completed) / Double(weeklyProgress.total)
    }

    private var phaseAccentColor: Color {
        currentPhase?.color ?? Theme.Colors.accentColor
    }

    @ViewBuilder
    private var heroBackground: some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(phaseAccentColor.opacity(0.10))
            )
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
