import SwiftUI
import Charts

struct FinishTimeEvolutionView: View {
    let race: Race
    let estimate: FinishEstimate
    let experience: ExperienceLevel
    var trainingPhilosophy: TrainingPhilosophy = .balanced
    var preferredRunsPerWeek: Int = 5

    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedWeek: Int?

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
                }

                // Legend reuses the SAME color coding as the scenario
                // tiles elsewhere on this screen (Optimistic = green,
                // Expected = primary, Conservative = orange) — the chart
                // previously used one color for everything, so it had no
                // way to visually agree with the tiles the athlete already
                // understands as three distinct scenarios.
                HStack(spacing: 12) {
                    legendSwatch(color: Theme.Colors.success, dashed: true, label: String(localized: "fe.scn.optimistic", defaultValue: "Optimistic"))
                    legendSwatch(color: primaryTint, dashed: false, label: String(localized: "fe.scn.expected", defaultValue: "Expected"))
                    legendSwatch(color: Theme.Colors.warning, dashed: true, label: String(localized: "fe.scn.conservative", defaultValue: "Conservative"))
                    Spacer()
                }

                chart
                    .frame(height: 220)

                HStack(spacing: 4) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 9))
                    Text(String(localized: "fte.dragHint", defaultValue: "Drag across the chart to explore any week"))
                        .font(.caption2)
                }
                .foregroundStyle(cardSubLabel)
            }
            .padding(Theme.Spacing.md)
        }
        .shadow(color: primaryTint.opacity(0.12), radius: 20, y: 6)
        .shadow(color: .black.opacity(cardShadowOpacity), radius: 10, y: 3)
    }

    private func legendSwatch(color: Color, dashed: Bool, label: String) -> some View {
        HStack(spacing: 4) {
            if dashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1).fill(color).frame(width: 3, height: 2)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(color)
                    .frame(width: 14, height: 3)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(cardLabel.opacity(0.75))
        }
    }

    private var chart: some View {
        Chart {
            // ── ONE neutral fill spanning the whole range. Deliberately
            // NOT color-coded — the colored boundary lines below do the
            // "which scenario is which" work; a neutral fill just reads
            // as "this is the uncertain zone" instead of competing with
            // them for meaning ─────────────────────────────────────────
            ForEach(points) { p in
                AreaMark(
                    x: .value("Week", p.week),
                    yStart: .value("Seconds", p.optimisticSeconds),
                    yEnd: .value("Seconds", p.conservativeSeconds)
                )
                .foregroundStyle(cardLabel.opacity(0.06))
                .interpolationMethod(.catmullRom)
            }

            // ── Optimistic bound — green, matching the "Optimistic"
            // scenario tile elsewhere on this screen. Colored via
            // `.foregroundStyle(by:)` + `.chartForegroundStyleScale`
            // below rather than a literal `.foregroundStyle(Color)` —
            // with three LineMarks sharing the same x/y value labels,
            // Charts was resolving them all to one style (everything
            // rendered green) despite each mark's own literal color.
            // An explicit named scale is the documented, reliable way
            // to give each series its own color ──────────────────────
            ForEach(points) { p in
                LineMark(
                    x: .value("Week", p.week),
                    y: .value("Seconds", p.optimisticSeconds)
                )
                .foregroundStyle(by: .value("Scenario", ScenarioSeries.optimistic.rawValue))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                .interpolationMethod(.catmullRom)
            }
            // ── Conservative bound — orange, matching the "Conservative"
            // scenario tile ────────────────────────────────────────────
            ForEach(points) { p in
                LineMark(
                    x: .value("Week", p.week),
                    y: .value("Seconds", p.conservativeSeconds)
                )
                .foregroundStyle(by: .value("Scenario", ScenarioSeries.conservative.rawValue))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                .interpolationMethod(.catmullRom)
            }

            // ── Expected line — tight glow pass (literal color; not
            // part of the named scenario scale, purely decorative) ───
            ForEach(points) { p in
                LineMark(
                    x: .value("Week", p.week),
                    y: .value("Seconds", p.expectedSeconds)
                )
                .foregroundStyle(primaryTint.opacity(0.15))
                .lineStyle(StrokeStyle(lineWidth: 7, lineCap: .round))
                .interpolationMethod(.catmullRom)
            }
            // ── Expected line — bold and solid, unmistakably the "main"
            // line since it's the only solid (non-dashed) stroke and the
            // only one at full opacity ────────────────────────────────
            ForEach(points) { p in
                LineMark(
                    x: .value("Week", p.week),
                    y: .value("Seconds", p.expectedSeconds)
                )
                .foregroundStyle(by: .value("Scenario", ScenarioSeries.expected.rawValue))
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .interpolationMethod(.catmullRom)
            }

            // ── NOW rule ─────────────────────────────────────────────
            RuleMark(x: .value("Week", currentWeekIndex))
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
                          y: .value("Seconds", cp.expectedSeconds))
                    .foregroundStyle(primaryTint.opacity(0.20))
                    .symbolSize(380)
                PointMark(x: .value("Week", cp.week),
                          y: .value("Seconds", cp.expectedSeconds))
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
                          y: .value("Seconds", last.expectedSeconds))
                    .foregroundStyle(Theme.Colors.success.opacity(0.20))
                    .symbolSize(380)
                PointMark(x: .value("Week", last.week),
                          y: .value("Seconds", last.expectedSeconds))
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

            // ── Scrub selection ──────────────────────────────────────
            if let sp = selectedPoint {
                RuleMark(x: .value("Selected week", sp.week))
                    .foregroundStyle(cardLabel.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .annotation(position: .top, alignment: .center, spacing: 6) {
                        selectionAnnotation(sp)
                    }
                PointMark(x: .value("Selected week", sp.week), y: .value("Seconds", sp.optimisticSeconds))
                    .foregroundStyle(Theme.Colors.success)
                    .symbolSize(45)
                PointMark(x: .value("Selected week", sp.week), y: .value("Seconds", sp.expectedSeconds))
                    .foregroundStyle(primaryTint)
                    .symbolSize(55)
                PointMark(x: .value("Selected week", sp.week), y: .value("Seconds", sp.conservativeSeconds))
                    .foregroundStyle(Theme.Colors.warning)
                    .symbolSize(45)
            }
        }
        .chartForegroundStyleScale(
            domain: [
                ScenarioSeries.optimistic.rawValue,
                ScenarioSeries.expected.rawValue,
                ScenarioSeries.conservative.rawValue
            ],
            range: [
                Theme.Colors.success.opacity(0.85),
                primaryTint,
                Theme.Colors.warning.opacity(0.85)
            ]
        )
        .chartLegend(.hidden)
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
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in handleDrag(value: value, proxy: proxy, geometry: geometry) }
                            .onEnded { _ in selectedWeek = nil }
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chartAccessibilitySummary)
    }

    // MARK: - Scrub Selection

    private var selectedPoint: EvolutionPoint? {
        guard let selectedWeek else { return nil }
        return points.first { $0.week == selectedWeek }
    }

    private func handleDrag(value: DragGesture.Value, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let plotFrame = proxy.plotFrame else { return }
        let frame = geometry[plotFrame]
        let xPosition = value.location.x - frame.origin.x
        guard let week: Int = proxy.value(atX: xPosition) else { return }
        selectedWeek = min(max(week, 1), prepWeeks)
    }

    private func selectionAnnotation(_ point: EvolutionPoint) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(String(localized: "chart.week", defaultValue: "W\(point.week)"))
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(cardSubLabel)
            selectionRow(color: Theme.Colors.success, value: point.optimisticSeconds)
            selectionRow(color: primaryTint, value: point.expectedSeconds, emphasized: true)
            selectionRow(color: Theme.Colors.warning, value: point.conservativeSeconds)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
        )
        .accessibilityHidden(true)
    }

    private func selectionRow(color: Color, value: TimeInterval, emphasized: Bool = false) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(formatShort(value))
                .font(.system(size: emphasized ? 11 : 10, weight: emphasized ? .bold : .semibold, design: .monospaced))
                .foregroundStyle(cardLabel)
        }
    }

    private var chartAccessibilitySummary: String {
        "Projected finish time evolution chart from \(formatShort(points.first?.expectedSeconds ?? estimate.expectedTime)) to \(formatShort(raceDayExpected)) on race day. Drag to explore any week."
    }

    /// Put the "Now" annotation below the dot when it's in the upper half
    /// of the plot (so the card drops into free space instead of pushing
    /// past the top of the chart/screen), above when it's in the lower
    /// half. This was previously inverted — a dot near the top of the
    /// plot got a `.top` annotation, which had nowhere to go but off the
    /// top edge of the card (and on a real device, off the top of the
    /// screen).
    private var nowAnnotationPosition: AnnotationPosition {
        guard let cp = points.first(where: { $0.week == currentWeekIndex }) else { return .bottom }
        let mid = (safeDomain.lowerBound + safeDomain.upperBound) / 2
        return cp.expectedSeconds < mid ? .top : .bottom
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

    /// How hard this athlete is actually training for THIS race — two
    /// athletes with identical current fitness and the same weeks to race
    /// shouldn't project the same race-day time otherwise, see
    /// `FinishTimeEstimator.trainingIntensityMultiplier`.
    private var trainingIntensityMultiplier: Double {
        FinishTimeEstimator.trainingIntensityMultiplier(
            philosophy: trainingPhilosophy, sessionsPerWeek: preferredRunsPerWeek
        )
    }

    private var raceDayExpected: TimeInterval {
        let optimistic = estimate.optimisticTime
        let expected   = estimate.expectedTime
        let modelProjection = FinishTimeEstimator.projectedRaceDayEstimate(
            optimisticTime: optimistic, expectedTime: expected,
            weeksToRace: weeksToRace, intensityMultiplier: trainingIntensityMultiplier
        )
        guard let goal = goalTime else { return modelProjection }
        if goal >= expected { return optimistic + (expected - optimistic) * 0.10 }
        if goal <= optimistic { return optimistic }
        // Goal sits realistically between optimistic and expected: the plan
        // is aimed at it, but never show LESS improvement than the model's
        // own unprompted projection would — otherwise a goal picked only
        // slightly faster than today's expected (a very normal choice)
        // flattens the whole evolution curve into a near-flat line, even
        // though a full training window should genuinely move the needle
        // more than that.
        return min(goal, modelProjection)
    }

    /// Race-day optimistic/conservative bounds scale by the SAME
    /// proportion `raceDayExpected` improved by, rather than a small fixed
    /// offset from it. A fixed offset (e.g. "4 minutes faster than
    /// race-day expected") looks fine when `raceDayExpected` barely moves,
    /// but once it improves by an hour on a 14+ hour race, that same
    /// 4-minute offset collapses the whole band — the optimistic bound
    /// ends up barely better than today's, while expected improves far
    /// more, so the optimistic line's head-start over expected shrinks to
    /// nothing over the course of the chart and visually reads as the
    /// optimistic scenario getting WORSE during training. Scaling
    /// proportionally keeps the bands' relative spread consistent as the
    /// whole projection shifts.
    private var raceDayImprovementRatio: Double {
        guard estimate.expectedTime > 0 else { return 1.0 }
        return raceDayExpected / estimate.expectedTime
    }
    private var raceDayOptimistic: TimeInterval {
        estimate.optimisticTime * raceDayImprovementRatio
    }
    private var raceDayConservative: TimeInterval {
        estimate.conservativeTime * raceDayImprovementRatio
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

/// Named series keys for the chart's `.chartForegroundStyleScale` — gives
/// each scenario line an explicit, stable color mapping instead of relying
/// on per-mark literal `.foregroundStyle(Color)`, which Charts was
/// collapsing into a single resolved style across the three LineMarks.
private enum ScenarioSeries: String {
    case optimistic = "Optimistic"
    case expected = "Expected"
    case conservative = "Conservative"
}

struct EvolutionPoint: Identifiable {
    let week: Int
    let expectedSeconds: TimeInterval
    let optimisticSeconds: TimeInterval
    let conservativeSeconds: TimeInterval
    var id: Int { week }
}
