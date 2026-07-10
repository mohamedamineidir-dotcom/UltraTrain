import SwiftUI
import Charts

struct FinishTimeEvolutionView: View {
    let race: Race
    let estimate: FinishEstimate
    let experience: ExperienceLevel

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerCard
                chartCard
                statRow
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.sm)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .navigationTitle(String(localized: "fte.title", defaultValue: "Time evolution"))
        .navigationBarTitleDisplayMode(.inline)
        .background(backgroundGradient.ignoresSafeArea())
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Theme.Colors.premiumBgTop.opacity(0.35),
                Theme.Colors.background
            ],
            startPoint: .top,
            endPoint: .center
        )
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(race.name)
                        .font(.title2.bold())
                    HStack(spacing: 6) {
                        Label(race.date.formatted(date: .abbreviated, time: .omitted),
                              systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        if weeksToRace > 0 {
                            Text("·")
                                .foregroundStyle(Theme.Colors.tertiaryLabel)
                                .font(.caption)
                            Text(String(localized: "fte.weeksToGo",
                                        defaultValue: "\(weeksToRace) weeks to go"))
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.secondaryLabel)
                        }
                    }
                }
                Spacer()
                // Live badge
                HStack(spacing: 5) {
                    Circle()
                        .fill(Theme.Colors.success)
                        .frame(width: 6, height: 6)
                    Text(String(localized: "fte.live", defaultValue: "Live"))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.Colors.success)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(Theme.Colors.success.opacity(0.12))
                )
            }

            Text(String(localized: "fte.intro",
                        defaultValue: "If you stick with the plan, your projected finish time evolves like this:"))
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.md)
        .futuristicGlassStyle(phaseTint: primaryTint)
    }

    // MARK: - Chart Card
    // Dark mode  → deep navy/indigo (high contrast, premium sports feel).
    // Light mode → soft lavender/periwinkle (same purple family, bright,
    //              on-brand without the harsh black-on-white contrast).

    // Soft lavender tones for the light-mode card — derived from the
    // accent family so the chart stays on-DNA.
    private var cardBgTop: Color {
        colorScheme == .dark
            ? Theme.Colors.premiumBgTop
            : Color(red: 0.90, green: 0.88, blue: 0.98)
    }
    private var cardBgMid: Color {
        colorScheme == .dark
            ? Theme.Colors.premiumBgMid
            : Color(red: 0.93, green: 0.92, blue: 0.99)
    }
    private var cardBgBottom: Color {
        colorScheme == .dark
            ? Theme.Colors.premiumBgBottom
            : Color(red: 0.95, green: 0.95, blue: 1.0)
    }
    // Text that reads on both backgrounds: white in dark, deep navy in light.
    private var cardLabel: Color {
        colorScheme == .dark ? .white : Color(red: 0.10, green: 0.08, blue: 0.30)
    }
    private var cardSubLabel: Color {
        colorScheme == .dark
            ? .white.opacity(0.50)
            : Color(red: 0.10, green: 0.08, blue: 0.30).opacity(0.50)
    }
    private var cardGridLine: Color {
        colorScheme == .dark ? .white.opacity(0.07) : .black.opacity(0.06)
    }
    private var cardShadowOpacity: Double { colorScheme == .dark ? 0.35 : 0.12 }

    private var chartCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [cardBgTop, cardBgMid, cardBgBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [primaryTint.opacity(0.30), primaryTint.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(primaryTint)
                    Text(String(localized: "fte.projectedCurve",
                                defaultValue: "Projected curve"))
                        .font(.footnote.bold())
                        .foregroundStyle(cardLabel.opacity(0.90))
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(primaryTint.opacity(0.45)).frame(width: 6, height: 6)
                        Text(String(localized: "fe.scn.range", defaultValue: "Range"))
                            .font(.caption2).foregroundStyle(cardSubLabel)
                    }
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(primaryTint).frame(width: 14, height: 2.5)
                        Text(String(localized: "fe.scn.expected", defaultValue: "Expected"))
                            .font(.caption2).foregroundStyle(cardLabel.opacity(0.65))
                    }
                }

                chart
                    .frame(height: 220)
            }
            .padding(Theme.Spacing.md)
        }
        .shadow(color: primaryTint.opacity(0.12), radius: 20, y: 6)
        .shadow(color: .black.opacity(cardShadowOpacity), radius: 10, y: 3)
    }

    private var chart: some View {
        Chart {
            // ── Lower band: expected → conservative (risk side, deeper) ──
            ForEach(points) { p in
                AreaMark(
                    x: .value("Week", p.week),
                    yStart: .value("Exp", p.expectedSeconds),
                    yEnd: .value("Con", p.conservativeSeconds)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [primaryTint.opacity(0.10),
                                 primaryTint.opacity(0.26)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // ── Upper band: optimistic → expected (upside, lighter) ───
            ForEach(points) { p in
                AreaMark(
                    x: .value("Week", p.week),
                    yStart: .value("Opt", p.optimisticSeconds),
                    yEnd: .value("Exp2", p.expectedSeconds)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [primaryTint.opacity(0.26),
                                 primaryTint.opacity(0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // ── Crisp boundary lines at the optimistic/conservative
            // edges, so the three "lanes" read as distinct zones instead
            // of blending into one soft gradient blob ──────────────────
            ForEach(points) { p in
                LineMark(
                    x: .value("Week", p.week),
                    y: .value("Optimistic", p.optimisticSeconds)
                )
                .foregroundStyle(primaryTint.opacity(0.35))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .interpolationMethod(.catmullRom)
            }
            ForEach(points) { p in
                LineMark(
                    x: .value("Week", p.week),
                    y: .value("Conservative", p.conservativeSeconds)
                )
                .foregroundStyle(primaryTint.opacity(0.35))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .interpolationMethod(.catmullRom)
            }

            // ── Expected line — tight glow pass ───────────────────────
            ForEach(points) { p in
                LineMark(
                    x: .value("Week", p.week),
                    y: .value("Expected", p.expectedSeconds)
                )
                .foregroundStyle(primaryTint.opacity(0.12))
                .lineStyle(StrokeStyle(lineWidth: 6, lineCap: .round))
                .interpolationMethod(.catmullRom)
            }
            // ── Expected line — crisp adaptive line on top ────────────
            ForEach(points) { p in
                LineMark(
                    x: .value("Week", p.week),
                    y: .value("Expected", p.expectedSeconds)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [cardLabel, primaryTint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .interpolationMethod(.catmullRom)
            }

            // ── NOW rule ─────────────────────────────────────────────
            RuleMark(x: .value("Now", currentWeekIndex))
                .foregroundStyle(cardLabel.opacity(0.18))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 5]))
                .annotation(position: .bottom, alignment: .center, spacing: 5) {
                    Text(String(localized: "fte.now", defaultValue: "NOW"))
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .tracking(1.5)
                        .foregroundStyle(cardLabel.opacity(0.55))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(cardLabel.opacity(0.07))
                                .overlay(Capsule().stroke(cardLabel.opacity(0.14), lineWidth: 0.5))
                        )
                }

            // ── Today dot ────────────────────────────────────────────
            if let cp = points.first(where: { $0.week == currentWeekIndex }) {
                PointMark(x: .value("Week", cp.week),
                          y: .value("Expected", cp.expectedSeconds))
                    .foregroundStyle(primaryTint.opacity(0.20))
                    .symbolSize(380)
                PointMark(x: .value("Week", cp.week),
                          y: .value("Expected", cp.expectedSeconds))
                    .foregroundStyle(cardLabel)
                    .symbolSize(50)
                    .annotation(position: nowAnnotationPosition, alignment: .center, spacing: 6) {
                        VStack(spacing: 1) {
                            Text(String(localized: "fte.now", defaultValue: "NOW"))
                                .font(.system(size: 7, weight: .black))
                                .tracking(1)
                                .foregroundStyle(primaryTint.opacity(0.90))
                            Text(formatShort(cp.expectedSeconds))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(cardLabel)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(primaryTint.opacity(colorScheme == .dark ? 0.22 : 0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(primaryTint.opacity(0.50), lineWidth: 0.75)
                                )
                        )
                    }
            }

            // ── Race-day dot ─────────────────────────────────────────
            if let last = points.last {
                PointMark(x: .value("Week", last.week),
                          y: .value("Expected", last.expectedSeconds))
                    .foregroundStyle(Theme.Colors.success.opacity(0.20))
                    .symbolSize(380)
                PointMark(x: .value("Week", last.week),
                          y: .value("Expected", last.expectedSeconds))
                    .foregroundStyle(Theme.Colors.success)
                    .symbolSize(50)
                    .annotation(position: .top, alignment: .trailing, spacing: 6) {
                        VStack(spacing: 1) {
                            HStack(spacing: 3) {
                                Image(systemName: "flag.checkered")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(Theme.Colors.success.opacity(0.85))
                                Text(String(localized: "fte.raceDay", defaultValue: "Race day"))
                                    .font(.system(size: 7, weight: .black))
                                    .tracking(0.5)
                                    .foregroundStyle(Theme.Colors.success.opacity(0.85))
                            }
                            Text(formatShort(last.expectedSeconds))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(cardLabel)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.Colors.success.opacity(colorScheme == .dark ? 0.18 : 0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.Colors.success.opacity(0.45), lineWidth: 0.75)
                                )
                        )
                    }
            }
        }
        .chartYScale(domain: safeDomain)
        .chartXScale(domain: 1...prepWeeks)
        .chartYAxis {
            AxisMarks(values: yAxisTicks) { _ in
                AxisGridLine()
                    .foregroundStyle(cardGridLine)
            }
        }
        .chartXAxis {
            AxisMarks(values: xAxisStops) { value in
                AxisGridLine()
                    .foregroundStyle(cardGridLine)
                AxisValueLabel {
                    if let w = value.as(Int.self), w != currentWeekIndex {
                        Text(String(localized: "chart.week",
                                    defaultValue: "W\(w)"))
                            .font(.system(size: 9))
                            .foregroundStyle(cardLabel.opacity(0.30))
                    }
                }
            }
        }
        .chartPlotStyle { area in
            area.padding(.horizontal, 4)
        }
    }

    /// Put the "Now" annotation above when the dot is in the upper half
    /// of the plot, below when it's in the lower half, to avoid clipping.
    private var nowAnnotationPosition: AnnotationPosition {
        guard let cp = points.first(where: { $0.week == currentWeekIndex }) else { return .top }
        let mid = (safeDomain.lowerBound + safeDomain.upperBound) / 2
        return cp.expectedSeconds < mid ? .bottom : .top
    }

    // MARK: - Stat Row

    private var statRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            statTile(
                icon: "hourglass",
                label: String(localized: "fte.stat.initial", defaultValue: "Start"),
                value: formatShort(points.first?.expectedSeconds ?? estimate.expectedTime),
                tint: Theme.Colors.warning
            )
            statTile(
                icon: "mappin",
                label: String(localized: "fte.stat.today", defaultValue: "Today"),
                value: formatShort(estimate.expectedTime),
                tint: primaryTint,
                emphasized: true
            )
            statTile(
                icon: "flag.checkered",
                label: String(localized: "fte.stat.raceDay", defaultValue: "Race day"),
                value: formatShort(raceDayExpected),
                tint: Theme.Colors.success
            )
        }
    }

    private func statTile(
        icon: String,
        label: String,
        value: String,
        tint: Color,
        emphasized: Bool = false
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint.opacity(0.8))
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.Colors.tertiaryLabel)
            Text(value)
                .font(.system(emphasized ? .title3 : .callout,
                              design: .monospaced).bold())
                .foregroundStyle(tint)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(tint.opacity(emphasized ? 0.10 : 0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .stroke(tint.opacity(emphasized ? 0.28 : 0.14), lineWidth: 1)
                )
        )
        .shadow(color: emphasized ? tint.opacity(0.15) : .clear, radius: 10, y: 4)
    }

    // MARK: - Y-axis domain (clipping fix)

    /// Compute min/max from ALL generated points — not just the center
    /// of the expected line. Without this the conservative curve clips
    /// at the bottom when it falls outside the fixed window.
    private var safeDomain: ClosedRange<TimeInterval> {
        guard !points.isEmpty else {
            let c = estimate.expectedTime
            return (c - 3600)...(c + 3600)
        }
        let allMin = points.map { $0.optimisticSeconds }.min()!
        let allMax = points.map { $0.conservativeSeconds }.max()!
        let span = allMax - allMin
        let pad = max(span * 0.12, 240)   // at least 4 min breathing room
        return (allMin - pad)...(allMax + pad)
    }

    /// 4 evenly-spaced Y ticks within the safe domain.
    private var yAxisTicks: [TimeInterval] {
        let lo = safeDomain.lowerBound
        let hi = safeDomain.upperBound
        let step = (hi - lo) / 3
        return [lo, lo + step, lo + 2 * step, hi]
    }

    // MARK: - Formatting

    private func formatShort(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        return String(format: "%dh%02d", h, m)
    }

    // MARK: - Theming

    private var primaryTint: Color { Theme.Colors.primary }

    // MARK: - Prep window

    private enum DistanceClass {
        case short5K, tenK, hm, marathon, ultraShort, ultraLong, multiDay
        static func from(distanceKm: Double) -> DistanceClass {
            switch distanceKm {
            case ..<8:   return .short5K
            case ..<15:  return .tenK
            case ..<30:  return .hm
            case ..<50:  return .marathon
            case ..<80:  return .ultraShort
            case ..<160: return .ultraLong
            default:     return .multiDay
            }
        }
    }

    private var distanceClass: DistanceClass { .from(distanceKm: race.distanceKm) }

    private var prepWeeks: Int { max(4, weeksToRace + 1) }

    private var weeksToRace: Int {
        let secs = race.date.timeIntervalSinceNow
        guard secs > 0 else { return 0 }
        return max(0, Int((secs / 86400 / 7).rounded()))
    }

    private var currentWeekIndex: Int {
        let elapsed = prepWeeks - weeksToRace
        return max(1, min(prepWeeks, elapsed))
    }

    // MARK: - Projection

    private var goalTime: TimeInterval? {
        if case .targetTime(let t) = race.goalType, t > 0 { return t }
        return nil
    }

    private var raceDayExpected: TimeInterval {
        let optimistic = estimate.optimisticTime
        let expected   = estimate.expectedTime
        guard let goal = goalTime else {
            return FinishTimeEstimator.projectedRaceDayEstimate(optimisticTime: optimistic, expectedTime: expected)
        }
        if goal >= expected { return optimistic + (expected - optimistic) * 0.10 }
        if goal <= optimistic { return optimistic }
        return goal
    }

    private var raceDayOptimistic: TimeInterval {
        max(estimate.optimisticTime * 0.97, raceDayExpected - 4 * 60)
    }
    private var raceDayConservative: TimeInterval {
        max(raceDayExpected + 3 * 60, estimate.expectedTime * 0.985)
    }

    private func easedProgress(_ t: Double) -> Double {
        let c = min(max(t, 0), 1)
        if c < 0.30 { return 0.12 * (c / 0.30) }
        if c < 0.90 {
            let l = (c - 0.30) / 0.60
            return 0.12 + 0.78 * (1 - pow(1 - l, 1.8))
        }
        return 0.90 + 0.10 * ((c - 0.90) / 0.10)
    }

    var points: [EvolutionPoint] {
        let ie = computeInitial(current: estimate.expectedTime,   raceDay: raceDayExpected)
        let io = computeInitial(current: estimate.optimisticTime, raceDay: raceDayOptimistic)
        let ic = computeInitial(current: estimate.conservativeTime, raceDay: raceDayConservative)
        return (1...prepWeeks).map { week in
            let t     = Double(week - 1) / max(1.0, Double(prepWeeks - 1))
            let eased = easedProgress(t)
            let exp   = ie + (raceDayExpected - ie) * eased
            let opt   = io + (raceDayOptimistic - io) * eased
            let con   = ic + (raceDayConservative - ic) * eased
            return EvolutionPoint(
                week: week,
                expectedSeconds: exp,
                optimisticSeconds: min(opt, exp - 60),
                conservativeSeconds: max(con, exp + 60)
            )
        }
    }

    private func computeInitial(current: TimeInterval, raceDay: TimeInterval) -> TimeInterval {
        let nowT      = Double(currentWeekIndex - 1) / max(1.0, Double(prepWeeks - 1))
        let easedNow  = easedProgress(nowT)
        guard easedNow < 0.999 else { return current }
        let raw = (current - raceDay * easedNow) / (1 - easedNow)
        let cap = current * initialMultiplierCap
        return min(max(raw, current), cap)
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

    private var xAxisStops: [Int] {
        let step = max(1, prepWeeks / 5)
        var stops = stride(from: 1, through: prepWeeks, by: step).map { $0 }
        if !stops.contains(currentWeekIndex) { stops.append(currentWeekIndex) }
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
