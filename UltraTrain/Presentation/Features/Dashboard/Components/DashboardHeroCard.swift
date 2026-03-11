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
                            .foregroundStyle(.white)
                        Text("days to go")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    } else {
                        Text("Training")
                            .font(.system(size: trainingTitleSize, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    if let name = raceName {
                        Text(name)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                }

                Spacer()

                if weeklyProgress.total > 0 {
                    progressRing
                }
            }

            Divider()
                .overlay(.white.opacity(0.3))

            HStack(spacing: Theme.Spacing.lg) {
                if let phase = currentPhase {
                    Label(phase.displayName, systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                }

                HStack(spacing: 4) {
                    Image(systemName: "figure.run")
                    Text(String(format: "%.0f / %.0f km", weeklyDistanceKm, weeklyTargetDistanceKm))
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))

                if let fitness = fitnessStatus {
                    Label(fitness, systemImage: "heart.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(gradientBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
        .shadow(color: Theme.Colors.shadow, radius: 8, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.2), lineWidth: 5)
            Circle()
                .trim(from: 0, to: progressFraction)
                .stroke(
                    .white,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: .white.opacity(0.5), radius: 4)
            VStack(spacing: 0) {
                Text("\(weeklyProgress.completed)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text("/\(weeklyProgress.total)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .opacity(0.8)
            }
            .foregroundStyle(.white)
        }
        .frame(width: 56, height: 56)
    }

    private var progressFraction: Double {
        guard weeklyProgress.total > 0 else { return 0 }
        return Double(weeklyProgress.completed) / Double(weeklyProgress.total)
    }

    private var gradientBackground: some View {
        Group {
            if let phase = currentPhase {
                Theme.Gradients.phaseGradient(phase)
            } else {
                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
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
