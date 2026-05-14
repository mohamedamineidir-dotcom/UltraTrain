import SwiftUI
import Charts

/// Detail view shown when the athlete taps the "Predicted Finish Time"
/// card. Plots how today's predicted finish time is expected to evolve
/// across the prep cycle if the athlete sticks with the plan: a
/// descending expected-time curve flanked by an optimistic/conservative
/// confidence band, with today's position marked.
///
/// The curve is a projection, not a record of past estimates — until we
/// persist per-week snapshots the chart shows what we predict the
/// trajectory looks like, given the athlete's current estimate and the
/// typical improvement curve for their experience tier.
struct FinishTimeEvolutionView: View {
    let race: Race
    let estimate: FinishEstimate
    let experience: ExperienceLevel

    @Environment(\.colorScheme) private var colorScheme

    private let prepWeeks: Int = 20

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header
                chartCard
                stats
            }
            .padding(Theme.Spacing.md)
        }
        .navigationTitle("Time evolution")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                colors: [
                    Theme.Colors.primary.opacity(colorScheme == .dark ? 0.08 : 0.03),
                    .clear
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(race.name)
                .font(.title3.bold())
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(race.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text("·")
                    .foregroundStyle(Theme.Colors.tertiaryLabel)
                Text("\(weeksToRace) weeks to go")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Text("If you stick with the plan, your projected finish time evolves like this:")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.label)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: Theme.Colors.primary)
    }

    // MARK: - Chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.Colors.primary)
                Text("Projected curve")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.Colors.primary)
                Spacer()
                legendDot(color: Theme.Colors.primary, label: "Expected")
                legendDot(color: Theme.Colors.secondaryLabel.opacity(0.6), label: "Range")
            }

            Chart {
                // Confidence band: optimistic → conservative shaded area.
                ForEach(points) { p in
                    AreaMark(
                        x: .value("Week", p.week),
                        yStart: .value("Optimistic", p.optimisticSeconds),
                        yEnd: .value("Conservative", p.conservativeSeconds)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Theme.Colors.primary.opacity(0.22),
                                Theme.Colors.primary.opacity(0.06)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                // Expected curve.
                ForEach(points) { p in
                    LineMark(
                        x: .value("Week", p.week),
                        y: .value("Expected", p.expectedSeconds)
                    )
                    .foregroundStyle(Theme.Colors.primary)
                    .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round))
                    .interpolationMethod(.catmullRom)
                }

                // Today marker: vertical rule + filled dot at current week.
                RuleMark(x: .value("Now", currentWeekIndex))
                    .foregroundStyle(Theme.Colors.label.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .annotation(position: .top, alignment: .center, spacing: 4) {
                        Text("NOW")
                            .font(.caption2.weight(.bold))
                            .tracking(0.6)
                            .foregroundStyle(Theme.Colors.label.opacity(0.7))
                    }

                if let currentPoint = points.first(where: { $0.week == currentWeekIndex }) {
                    PointMark(
                        x: .value("Week", currentPoint.week),
                        y: .value("Expected", currentPoint.expectedSeconds)
                    )
                    .foregroundStyle(Theme.Colors.primary)
                    .symbolSize(110)
                }
            }
            .chartXScale(domain: 1...prepWeeks)
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(Theme.Colors.tertiaryLabel.opacity(0.15))
                    AxisValueLabel {
                        if let s = value.as(TimeInterval.self) {
                            Text(FinishEstimate.formatDuration(s))
                                .font(.caption2.monospacedDigit())
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: xAxisStops) { value in
                    AxisGridLine().foregroundStyle(Theme.Colors.tertiaryLabel.opacity(0.1))
                    AxisValueLabel {
                        if let w = value.as(Int.self) {
                            Text("W\(w)").font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 240)
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: Theme.Colors.primary)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.caption2).foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Stats

    private var stats: some View {
        HStack(spacing: Theme.Spacing.sm) {
            statTile(
                label: "Initial",
                value: FinishEstimate.formatDuration(points.first?.expectedSeconds ?? estimate.expectedTime),
                tint: Theme.Colors.warning
            )
            statTile(
                label: "Today",
                value: FinishEstimate.formatDuration(estimate.expectedTime),
                tint: Theme.Colors.primary
            )
            statTile(
                label: "Race day",
                value: FinishEstimate.formatDuration(points.last?.expectedSeconds ?? estimate.optimisticTime),
                tint: Theme.Colors.success
            )
        }
    }

    private func statTile(label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(0.5)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .futuristicGlassStyle(phaseTint: tint)
    }

    // MARK: - Projection model

    /// Weeks of prep we render across. Default 20 weeks (typical marathon
    /// prep length) when no plan is injected. The current-week marker
    /// is derived from race date — `weeksToRace` weeks remain, so the
    /// current week index = prepWeeks − weeksToRace.
    private var weeksToRace: Int {
        let secs = race.date.timeIntervalSinceNow
        guard secs > 0 else { return 0 }
        return max(0, Int((secs / 86400 / 7).rounded()))
    }

    /// 1-based index of the current week within the prep cycle. Clamped
    /// to [1, prepWeeks] so the marker always lands on the chart.
    private var currentWeekIndex: Int {
        let elapsed = prepWeeks - weeksToRace
        return max(1, min(prepWeeks, elapsed))
    }

    /// Per-tier total improvement assumption from plan start to race
    /// day. Anchored on the FasterRoadRacing / Pfitzinger consensus
    /// that newer athletes gain more across a single prep cycle.
    private var totalImprovementFraction: Double {
        switch experience {
        case .beginner:     return 0.10  // ~10% — large gains for newcomers
        case .intermediate: return 0.06
        case .advanced:     return 0.035
        case .elite:        return 0.02
        }
    }

    /// Projected per-week curve. Today's expectedTime is anchored to
    /// the current week (so the dot lands on it exactly). Initial =
    /// expectedTime × (1 + improvementToDate); race-day expected =
    /// expectedTime × (1 - improvementRemaining). Split scales by how
    /// far into the prep cycle the athlete already is.
    var points: [EvolutionPoint] {
        let total = totalImprovementFraction
        // How much of the total gain we model as "already realised" vs
        // "still to come" — proportional to the athlete's position in
        // the prep cycle. An athlete halfway through has captured ~half
        // of the gain; the remaining half is the descending curve.
        let progress = Double(currentWeekIndex - 1) / max(1.0, Double(prepWeeks - 1))
        let pastGain = total * progress
        let futureGain = total * (1 - progress)
        let initial = estimate.expectedTime * (1 + pastGain)
        let raceDay = estimate.expectedTime * (1 - futureGain)
        let optimisticRaceDay = estimate.optimisticTime * (1 - futureGain * 0.5)
        let conservativeInitial = estimate.conservativeTime * (1 + pastGain * 0.5)

        return (1...prepWeeks).map { week in
            let t = Double(week - 1) / max(1.0, Double(prepWeeks - 1))
            // Quadratic ease-in-out so the curve is gentler at the
            // edges (athlete adapting in W1-W3, sharpening in last
            // weeks) and steepest mid-block where build and peak
            // gains accumulate.
            let eased = t * t * (3 - 2 * t)
            let expected = initial + (raceDay - initial) * eased
            let optimistic = conservativeInitial + (optimisticRaceDay - conservativeInitial) * eased * 0.92
            let conservative = conservativeInitial + (raceDay * 1.05 - conservativeInitial) * eased
            return EvolutionPoint(
                week: week,
                expectedSeconds: expected,
                optimisticSeconds: min(optimistic, expected - 60),
                conservativeSeconds: max(conservative, expected + 60)
            )
        }
    }

    /// Tick stops on the X axis: every 5 weeks, plus the current week.
    private var xAxisStops: [Int] {
        var stops = stride(from: 1, through: prepWeeks, by: 5).map { $0 }
        if !stops.contains(currentWeekIndex) {
            stops.append(currentWeekIndex)
        }
        return stops.sorted()
    }
}

struct EvolutionPoint: Identifiable {
    let week: Int
    let expectedSeconds: TimeInterval
    let optimisticSeconds: TimeInterval
    let conservativeSeconds: TimeInterval
    var id: Int { week }
}
