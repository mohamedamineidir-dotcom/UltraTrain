import SwiftUI
import Charts

/// Detail view shown when the athlete taps the "Predicted Finish Time"
/// card. Plots how today's predicted finish time is expected to evolve
/// across the prep cycle if the athlete sticks with the plan: a
/// descending expected-time curve flanked by an optimistic/conservative
/// confidence band, with today's position marked.
///
/// The curve is a projection, not a record of past estimates, until we
/// persist per-week snapshots the chart shows what we predict the
/// trajectory looks like, given the athlete's current estimate and the
/// typical improvement curve for their experience tier.
struct FinishTimeEvolutionView: View {
    let race: Race
    let estimate: FinishEstimate
    let experience: ExperienceLevel

    @Environment(\.colorScheme) private var colorScheme

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
                    primaryTint.opacity(colorScheme == .dark ? 0.08 : 0.04),
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
        .futuristicGlassStyle(phaseTint: primaryTint)
    }

    // MARK: - Chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(primaryTint)
                Text("Projected curve")
                    .font(.subheadline.bold())
                    .foregroundStyle(primaryTint)
                Spacer()
                legendDot(color: primaryTint, label: "Expected")
                legendDot(color: bandLegendColor, label: "Range")
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
                                primaryTint.opacity(bandOpacityTop),
                                primaryTint.opacity(bandOpacityBottom)
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
                    .foregroundStyle(primaryTint)
                    .lineStyle(StrokeStyle(lineWidth: 2.6, lineCap: .round))
                    .interpolationMethod(.catmullRom)
                }

                // Today rule. Annotation lives at the BOTTOM so the
                // "NOW" label sits inside the chart's bottom margin
                // and doesn't collide with the section header above.
                RuleMark(x: .value("Now", currentWeekIndex))
                    .foregroundStyle(Theme.Colors.label.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .annotation(position: .bottom, alignment: .center, spacing: 2) {
                        Text("NOW")
                            .font(.caption2.weight(.bold))
                            .tracking(0.6)
                            .foregroundStyle(Theme.Colors.label.opacity(0.75))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(
                                Capsule().fill(Theme.Colors.background.opacity(0.85))
                            )
                    }

                if let currentPoint = points.first(where: { $0.week == currentWeekIndex }) {
                    PointMark(
                        x: .value("Week", currentPoint.week),
                        y: .value("Expected", currentPoint.expectedSeconds)
                    )
                    .foregroundStyle(primaryTint)
                    .symbolSize(120)
                }
            }
            .chartXScale(domain: 1...prepWeeks)
            .chartYScale(domain: yAxisRange)
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(gridLineColor)
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
                    AxisGridLine().foregroundStyle(gridLineColor)
                    AxisValueLabel {
                        if let w = value.as(Int.self) {
                            Text("W\(w)").font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 260)
            .padding(.top, 4)
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: primaryTint)
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
                value: FinishEstimate.formatDuration(
                    points.first?.expectedSeconds ?? estimate.expectedTime,
                    raceDistanceKm: race.distanceKm
                ),
                tint: Theme.Colors.warning
            )
            statTile(
                label: "Today",
                value: FinishEstimate.formatDuration(currentPointExpected, raceDistanceKm: race.distanceKm),
                tint: primaryTint
            )
            statTile(
                label: "Race day",
                value: FinishEstimate.formatDuration(raceDayExpected, raceDistanceKm: race.distanceKm),
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

    // MARK: - Theming helpers

    private var primaryTint: Color { Theme.Colors.primary }

    /// Confidence-band opacity. In light mode the default 0.22/0.06
    /// renders almost invisible against the white card; bump it so the
    /// range is readable on both themes.
    private var bandOpacityTop: Double {
        colorScheme == .dark ? 0.24 : 0.38
    }
    private var bandOpacityBottom: Double {
        colorScheme == .dark ? 0.06 : 0.14
    }
    private var bandLegendColor: Color {
        primaryTint.opacity(colorScheme == .dark ? 0.45 : 0.55)
    }
    private var gridLineColor: Color {
        Theme.Colors.tertiaryLabel.opacity(colorScheme == .dark ? 0.15 : 0.25)
    }

    // MARK: - Distance / prep window

    private enum DistanceClass {
        case short5K, tenK, hm, marathon, ultraShort, ultraLong, multiDay
        static func from(distanceKm: Double) -> DistanceClass {
            switch distanceKm {
            case ..<8:   return .short5K
            case ..<15:  return .tenK
            case ..<30:  return .hm
            case ..<50:  return .marathon
            case ..<80:  return .ultraShort   // 50K-50mi
            case ..<160: return .ultraLong    // 100K-100mi
            default:     return .multiDay
            }
        }
    }

    private var distanceClass: DistanceClass {
        DistanceClass.from(distanceKm: race.distanceKm)
    }

    /// Total prep window. Stretches to fit how many weeks remain to
    /// the race so the curve always starts before today and ends on
    /// race week, never compresses an athlete who's 22 weeks out
    /// into a fixed 20-week window with a clipped NOW marker.
    ///
    /// Keeps a small floor (4 weeks) so the chart still reads as a
    /// curve, but no longer pads to 16 weeks. Padding to 16 for a
    /// B-race 1 week out drew a long timeline with NOW hugging the
    /// right edge and forced `computeInitialExpected` to extrapolate
    /// wildly (1 - easedAtNow shrinks to ~0.07, blowing the formula
    /// up).
    private var prepWeeks: Int {
        max(4, weeksToRace + 1)
    }

    private var weeksToRace: Int {
        let secs = race.date.timeIntervalSinceNow
        guard secs > 0 else { return 0 }
        return max(0, Int((secs / 86400 / 7).rounded()))
    }

    /// 1-based index of the current week within the prep cycle.
    private var currentWeekIndex: Int {
        let elapsed = prepWeeks - weeksToRace
        return max(1, min(prepWeeks, elapsed))
    }

    /// Y-axis domain. Window scales by race distance so the curve
    /// actually reads as a curve, a marathon athlete shouldn't see
    /// their 2h52 line floating in a 0h-5h33 range, and a 10K runner
    /// shouldn't see the band collapse into a 2 px stripe.
    private var yAxisRange: ClosedRange<TimeInterval> {
        let center = estimate.expectedTime
        let halfBelow: TimeInterval
        let halfAbove: TimeInterval
        switch distanceClass {
        case .short5K:    halfBelow = 4 * 60;  halfAbove = 5 * 60
        case .tenK:       halfBelow = 5 * 60;  halfAbove = 7 * 60
        case .hm:         halfBelow = 8 * 60;  halfAbove = 12 * 60
        case .marathon:   halfBelow = 14 * 60; halfAbove = 18 * 60
        case .ultraShort: halfBelow = 25 * 60; halfAbove = 40 * 60
        case .ultraLong:  halfBelow = 60 * 60; halfAbove = 90 * 60
        case .multiDay:   halfBelow = 3 * 3600; halfAbove = 5 * 3600
        }
        return max(0, center - halfBelow)...(center + halfAbove)
    }

    // MARK: - Projection model

    /// Today's goal time when the athlete declared one. Drives the
    /// race-day anchor and pulls the curve toward something concrete
    /// instead of a tier-based abstraction.
    private var goalTime: TimeInterval? {
        if case .targetTime(let t) = race.goalType, t > 0 { return t }
        return nil
    }

    /// Race-day expected finish. Anchored on today's optimistic time
    /// (the "if you stick with the plan" projection the estimator
    /// already produces), then nudged toward the goal when it sits
    /// between optimistic and expected, that's the "reachable
    /// stretch" band where coach belief in the goal should move the
    /// prediction. Goals more aggressive than optimistic don't bend
    /// the line further; goals slower than expected don't either.
    private var raceDayExpected: TimeInterval {
        let optimistic = estimate.optimisticTime
        let expected = estimate.expectedTime
        guard let goal = goalTime else {
            // No goal, project to optimistic with a small realism
            // buffer (15% of the optimistic-expected gap).
            return optimistic + (expected - optimistic) * 0.15
        }
        if goal >= expected {
            // Goal slower than expected, athlete will likely beat it.
            return optimistic + (expected - optimistic) * 0.10
        }
        if goal <= optimistic {
            // Goal more aggressive than the model's best case, don't
            // promise it, project to optimistic.
            return optimistic
        }
        // Goal sits inside the reachable stretch, project to goal.
        return goal
    }

    /// Race-day optimistic and conservative endpoints. Both follow the
    /// expected projection's direction but with a tightening band:
    /// uncertainty shrinks as race day approaches.
    private var raceDayOptimistic: TimeInterval {
        max(estimate.optimisticTime * 0.97, raceDayExpected - 4 * 60)
    }
    private var raceDayConservative: TimeInterval {
        max(raceDayExpected + 3 * 60, estimate.expectedTime * 0.985)
    }

    /// Where today's expected line sits on the curve. Always equals
    /// `estimate.expectedTime` so the marker dot lines up exactly with
    /// the value the athlete sees on the main estimate card.
    private var currentPointExpected: TimeInterval {
        estimate.expectedTime
    }

    /// Phase-weighted progression: improvement isn't linear across a
    /// 20-week marathon plan. The aerobic-base stage (first ~30%)
    /// adds little to the finish-time prediction; the build + peak
    /// stages (~30-90%) carry the bulk of the gain; the taper (~90-
    /// 100%) plateaus. Matches the consensus across Pfitzinger,
    /// Daniels, Hudson and Magness that race-pace specificity and
    /// VO2max gains in build/peak are where the time drops happen.
    private func easedProgress(_ t: Double) -> Double {
        let clamped = min(max(t, 0), 1)
        if clamped < 0.30 {
            // Base: 0-30% of prep yields ~12% of total improvement.
            let local = clamped / 0.30
            return 0.12 * local
        }
        if clamped < 0.90 {
            // Build + peak: bulk of the gain (78%).
            let local = (clamped - 0.30) / 0.60
            // Slight ease-out so the curve flattens toward taper.
            let easedLocal = 1 - pow(1 - local, 1.8)
            return 0.12 + 0.78 * easedLocal
        }
        // Taper: last 10% adds the final 10% (supercompensation only).
        let local = (clamped - 0.90) / 0.10
        return 0.90 + 0.10 * local
    }

    /// Per-week curve points. Initial time anchors above today (we've
    /// "already realised" `progressAtNow × totalImprovement` of the
    /// total drop) so the dot lands exactly on `expectedTime`. Race-
    /// day point anchors on `raceDayExpected`. The curve interpolates
    /// between them using `easedProgress` so build/peak weeks see the
    /// steepest drop.
    var points: [EvolutionPoint] {
        let initialExpected = computeInitialExpected()
        let initialOptimistic = computeInitialOptimistic()
        let initialConservative = computeInitialConservative()

        return (1...prepWeeks).map { week in
            let t = Double(week - 1) / max(1.0, Double(prepWeeks - 1))
            let eased = easedProgress(t)
            let expected = initialExpected + (raceDayExpected - initialExpected) * eased
            let optimistic = initialOptimistic + (raceDayOptimistic - initialOptimistic) * eased
            let conservative = initialConservative + (raceDayConservative - initialConservative) * eased
            // Floor the optimistic 60s under expected and ceiling the
            // conservative 60s above so the three lines stay readable.
            return EvolutionPoint(
                week: week,
                expectedSeconds: expected,
                optimisticSeconds: min(optimistic, expected - 60),
                conservativeSeconds: max(conservative, expected + 60)
            )
        }
    }

    /// Computes the projection's starting expected time so the curve
    /// passes through `estimate.expectedTime` exactly at the current
    /// week. Inverts the eased function so the dot aligns.
    private func computeInitialExpected() -> TimeInterval {
        let nowT = Double(currentWeekIndex - 1) / max(1.0, Double(prepWeeks - 1))
        let easedAtNow = easedProgress(nowT)
        // expectedNow = initial + (raceDay - initial) * easedAtNow
        // initial = (expectedNow - raceDay * easedAtNow) / (1 - easedAtNow)
        guard easedAtNow < 0.999 else {
            // Race-week edge case: initial is irrelevant, return expected.
            return estimate.expectedTime
        }
        let raw = (estimate.expectedTime - raceDayExpected * easedAtNow) / (1 - easedAtNow)
        return clampInitial(raw, anchor: estimate.expectedTime)
    }

    private func computeInitialOptimistic() -> TimeInterval {
        let nowT = Double(currentWeekIndex - 1) / max(1.0, Double(prepWeeks - 1))
        let easedAtNow = easedProgress(nowT)
        guard easedAtNow < 0.999 else { return estimate.optimisticTime }
        let raw = (estimate.optimisticTime - raceDayOptimistic * easedAtNow) / (1 - easedAtNow)
        return clampInitial(raw, anchor: estimate.optimisticTime)
    }

    private func computeInitialConservative() -> TimeInterval {
        let nowT = Double(currentWeekIndex - 1) / max(1.0, Double(prepWeeks - 1))
        let easedAtNow = easedProgress(nowT)
        guard easedAtNow < 0.999 else { return estimate.conservativeTime }
        let raw = (estimate.conservativeTime - raceDayConservative * easedAtNow) / (1 - easedAtNow)
        return clampInitial(raw, anchor: estimate.conservativeTime)
    }

    /// Caps the back-extrapolated "initial" time so a NOW that sits late
    /// in the prep window doesn't blow the value up. Without this cap a
    /// B-race close to today (NOW at week N-1 of N weeks) drives
    /// `(1 - easedAtNow)` toward zero and the formula explodes (a 36-min
    /// 10K predicted with INITIAL = 1h08, more than 2× today's expected).
    /// Realistic baselines for a runner inside a structured prep sit at
    /// most ~25-30% slower than today's projection.
    private func clampInitial(_ raw: TimeInterval, anchor: TimeInterval) -> TimeInterval {
        guard anchor > 0 else { return raw }
        let cap = anchor * initialMultiplierCap
        return min(max(raw, anchor), cap)
    }

    private var initialMultiplierCap: Double {
        switch distanceClass {
        case .short5K, .tenK: return 1.20
        case .hm:             return 1.22
        case .marathon:       return 1.25
        case .ultraShort:     return 1.30
        case .ultraLong:      return 1.35
        case .multiDay:       return 1.40
        }
    }

    /// Tick stops on the X axis: ~5 stops, plus the current week.
    private var xAxisStops: [Int] {
        let step = max(1, prepWeeks / 5)
        var stops = stride(from: 1, through: prepWeeks, by: step).map { $0 }
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
