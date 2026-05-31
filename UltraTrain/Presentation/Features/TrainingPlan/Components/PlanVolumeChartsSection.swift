import SwiftUI
import Charts

enum VolumeChartMetric: String, CaseIterable {
    case duration = "Duration"
    case elevation = "Elevation"
    case distance = "Distance"

    var localizedName: String {
        switch self {
        case .duration:  String(localized: "chart.duration", defaultValue: "Duration")
        case .elevation: String(localized: "chart.elevation", defaultValue: "Elevation")
        case .distance:  String(localized: "chart.distance", defaultValue: "Distance")
        }
    }
}

struct PlanVolumeChartsSection: View {
    @Environment(\.unitPreference) private var units
    let plan: TrainingPlan
    var isRoad: Bool = false
    @State private var selectedMetric: VolumeChartMetric = .duration
    @State private var selectedWeek: WeekChartDataPoint?
    @State private var sheetWeek: WeekChartDataPoint?

    private var dataPoints: [WeekChartDataPoint] {
        PlanVolumeChartData.extract(from: plan.weeks)
    }

    private var availableMetrics: [VolumeChartMetric] {
        isRoad ? [.duration, .distance] : VolumeChartMetric.allCases
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            headerRow
            metricPicker
            summaryStats

            if dataPoints.isEmpty {
                Text("No plan data")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                chartView
                chartLegend
            }
        }
        .futuristicGlassStyle()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Training volume chart")
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text(String(localized: "chart.trainingVolume", defaultValue: "Training Volume"))
                .font(.headline)
            Spacer()
            if selectedMetric != .distance, let peak = peakWeekValue {
                Text("chart.peak \(peak)")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }

    // MARK: - Metric Picker

    private var metricPicker: some View {
        Picker("Metric", selection: $selectedMetric) {
            ForEach(availableMetrics, id: \.self) { metric in
                Text(metric.localizedName).tag(metric)
            }
        }
        .pickerStyle(.segmented)
        .onAppear {
            if !availableMetrics.contains(selectedMetric) {
                selectedMetric = .duration
            }
        }
    }

    // MARK: - Summary Stats

    private var summaryStats: some View {
        HStack(spacing: 0) {
            summaryStatItem(
                value: totalFormattedValue,
                label: String(localized: "chart.total", defaultValue: "Total")
            )
            Spacer()
            summaryStatItem(
                value: avgFormattedValue,
                label: String(localized: "chart.avgPerWeek", defaultValue: "Avg / week")
            )
            Spacer()
            summaryStatItem(
                value: "\(completedWeeks)/\(dataPoints.count)",
                label: String(localized: "chart.weeksDone", defaultValue: "Weeks done")
            )
        }
    }

    private func summaryStatItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Chart

    private var chartView: some View {
        Chart {
            // 1) Planned curve, neutral grey background, visible across
            //    the whole prep so the athlete can read the shape of the
            //    block (build, peak, taper). Hidden on the distance tab
            //    because trail plans don't pre-plan distance.
            if selectedMetric != .distance {
                ForEach(dataPoints) { point in
                    AreaMark(
                        x: .value("Week", point.weekNumber),
                        y: .value("Planned", plannedValue(for: point)),
                        series: .value("Series", "Planned"),
                        stacking: .unstacked
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                Theme.Colors.label.opacity(0.18),
                                Theme.Colors.label.opacity(0.04)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.linear)
                }
                ForEach(dataPoints) { point in
                    LineMark(
                        x: .value("Week", point.weekNumber),
                        y: .value("Planned", plannedValue(for: point)),
                        series: .value("Series", "Planned")
                    )
                    .foregroundStyle(Theme.Colors.label.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .interpolationMethod(.linear)
                }
            }

            // 2) Completed overlay, phase-coloured area + line that
            //    "fills in" the planned curve as the athlete validates
            //    sessions. Colour changes by phase block, matching the
            //    same palette used elsewhere in the app (Base = blue,
            //    Build = orange, Peak = red/coral, Taper = green,
            //    Recovery = mint, Race = purple). Renders one segment
            //    per phase so transitions read as discrete colour
            //    bands, the way Campus Coach surfaces progress without
            //    losing the phase narrative.
            ForEach(phaseSegments) { segment in
                if segment.points.count == 1, let only = segment.points.first {
                    // Single-week segment (athlete has just validated
                    // W1). Swift Charts can't draw a Line or Area with
                    // one point, so render a thin phase-coloured
                    // vertical stem from baseline up to the completed
                    // value. No permanent dot on top, dots are
                    // reserved for the drag-inspect interaction so the
                    // chart stays clean while idle.
                    RuleMark(
                        x: .value("Week", only.weekNumber),
                        yStart: .value("Floor", 0),
                        yEnd: .value("Completed", completedValue(for: only))
                    )
                    .foregroundStyle(phaseColor(segment.phase))
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                } else {
                    ForEach(segment.points) { point in
                        AreaMark(
                            x: .value("Week", point.weekNumber),
                            y: .value("Completed", completedValue(for: point)),
                            series: .value("Phase", segment.id),
                            stacking: .unstacked
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [
                                    phaseColor(segment.phase).opacity(0.55),
                                    phaseColor(segment.phase).opacity(0.15)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.linear)

                        LineMark(
                            x: .value("Week", point.weekNumber),
                            y: .value("Completed", completedValue(for: point)),
                            series: .value("Phase", segment.id)
                        )
                        .foregroundStyle(phaseColor(segment.phase))
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .interpolationMethod(.linear)
                    }
                }
            }

            // Interactive dot. Only appears while the athlete is
            // dragging on the chart, moves with the rule mark to
            // surface the precise value at the inspected week. No
            // permanent per-week dots so the curve stays clean.
            if let selected = selectedWeek {
                PointMark(
                    x: .value("Selected week", selected.weekNumber),
                    y: .value("Completed", completedValue(for: selected))
                )
                .foregroundStyle(phaseColor(selected.phase))
                .symbolSize(55)
            }

            // Recovery week background shading
            ForEach(dataPoints.filter(\.isRecoveryWeek)) { point in
                RectangleMark(
                    x: .value("Week", point.weekNumber),
                    yStart: .value("Start", 0),
                    yEnd: .value("End", maxPlannedValue * 1.05),
                    width: .ratio(1)
                )
                .foregroundStyle(Color.mint.opacity(0.08))
            }

            // Current week, filled accent pill
            // Shortened RuleMark (yEnd ~60% of max) keeps the NOW badge inside
            // the plot area so it never overlaps the summary stats above.
            // Annotation alignment flips toward the chart's interior when the
            // current week sits within ~2 weeks of either edge so the pill
            // never gets clipped against the left/right plot boundary
            // (.fit(to: .chart) alone left the "N" of "NOW" cut on Week 1
            // and would do the same in the final 2 weeks).
            if let currentWeek = dataPoints.first(where: \.isCurrentWeek) {
                RuleMark(
                    x: .value("Current", currentWeek.weekNumber),
                    yStart: .value("Start", 0),
                    yEnd: .value("End", nowRuleMarkYEnd)
                )
                    .foregroundStyle(Theme.Colors.accentColor.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .annotation(
                        position: .top,
                        alignment: nowPillAlignment(weekNumber: currentWeek.weekNumber),
                        spacing: 2,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
                    ) {
                        Text("NOW")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Theme.Colors.accentColor)
                                    .shadow(color: Theme.Colors.accentColor.opacity(0.4), radius: 4, y: 2)
                            )
                    }
            }

            // Selected week line
            if let selected = selectedWeek {
                RuleMark(x: .value("Selected", selected.weekNumber))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        // Domain pins to the exact week range. We don't override the
        // range padding here, adding inward padding shrinks the
        // PLANNED grey curve too, which was already laid out
        // correctly. The poke-out only affects the completed
        // overlay's stroke; we handle that by clipping the plot
        // content below (chartPlotStyle.clipShape) so the strokes
        // straddling the boundary get visually cropped to the plot
        // frame.
        .chartXScale(domain: weekDomain)
        .chartXAxis {
            // Auto axis renders only the faint vertical grid lines +
            // ticks at the labeled week positions. The W-labels
            // themselves are rendered manually via `chartOverlay`
            // below using `proxy.position(forX:)`, every other
            // approach (centered: true on the string init, custom
            // Text content with manual frame, even default leading
            // anchor) drifts the labels off their data columns by
            // ~2 weeks on long plans because SwiftUI Charts adds
            // implicit edge padding that AxisValueLabel positioning
            // doesn't account for. Drawing labels at the exact
            // resolved x-position bypasses the quirk entirely.
            AxisMarks(values: visibleWeekNumbers) { _ in
                AxisGridLine()
                    .foregroundStyle(Theme.Colors.label.opacity(0.08))
                AxisTick(length: 4)
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.45))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                AxisValueLabel()
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.5))
            }
        }
        .chartPlotStyle { plot in
            plot
                .frame(height: 200)
                .background(
                    // Soft accent-tinted plot background, gives the
                    // chart its branded "blue glow" feel even when the
                    // plot is empty (initial state, or the Distance
                    // tab where the planned curve is intentionally
                    // hidden). Subtle vertical gradient: stronger near
                    // the bottom where data sits, fading out toward
                    // the top so the line/area marks remain readable.
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.Colors.accentColor.opacity(0.04),
                                    Theme.Colors.accentColor.opacity(0.10),
                                    Theme.Colors.accentColor.opacity(0.14)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                // Hard-clip the plot region to its rounded frame.
                // Marks at the absolute X-domain edges (W1 and the
                // last week) have their stroke widths straddling the
                // boundary pixel; without clipping, half the stroke
                // renders outside the visible plot. Clipping crops
                // those tiny outside-strokes to the frame so the
                // overlay never appears to poke out, without
                // shrinking the planned curve or the chart itself.
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
        }
        .shadow(color: Theme.Colors.accentColor.opacity(0.15), radius: 8)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                let x = drag.location.x - geo[proxy.plotFrame!].origin.x
                                if let weekNum: Int = proxy.value(atX: x) {
                                    selectedWeek = dataPoints.first { $0.weekNumber == weekNum }
                                }
                            }
                            .onEnded { _ in
                                sheetWeek = selectedWeek
                                selectedWeek = nil
                            }
                    )
            }
        }
        .chartOverlay { proxy in
            // Manual X-axis labels. Resolves each week number to its
            // exact pixel position via `proxy.position(forX:)` then
            // centres the label on it. Sidesteps the Swift Charts
            // bug where `AxisValueLabel(_:centered:)` with Int values
            // drifts off the data column on long plans.
            GeometryReader { geo in
                if let plotAnchor = proxy.plotFrame {
                    let plot = geo[plotAnchor]
                    ZStack(alignment: .topLeading) {
                        ForEach(visibleWeekNumbers, id: \.self) { weekNum in
                            if let xPos = proxy.position(forX: weekNum) {
                                Text("W\(weekNum)")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.75))
                                    .fixedSize()
                                    .position(
                                        x: plot.minX + xPos,
                                        y: plot.maxY + 12
                                    )
                            }
                        }
                    }
                }
            }
            .allowsHitTesting(false)
        }
        .sheet(item: $sheetWeek) { point in
            let matchingWeek = plan.weeks.first { $0.weekNumber == point.weekNumber }
            WeekSummarySheet(point: point, week: matchingWeek, isRoad: isRoad)
        }
    }

    // MARK: - Chart Legend

    private var chartLegend: some View {
        // Legend reads as "what colour means what phase", matches
        // what the chart actually shows now (phase-coloured overlay
        // over the planned grey background) instead of the old
        // per-session-type stacked bars.
        let phases = activePhases
        var items: [(String, Color)] = []
        if selectedMetric != .distance {
            items.append(("Planned", Theme.Colors.label.opacity(0.35)))
        }
        for phase in phases {
            items.append((phaseLabel(phase), phaseColor(phase)))
        }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(item.1)
                            .frame(width: 10, height: 10)
                        Text(item.0)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
            }
        }
    }

    private func phaseLabel(_ phase: TrainingPhase) -> String {
        switch phase {
        case .base:     return "Base"
        case .build:    return "Build"
        case .peak:     return "Peak"
        case .taper:    return "Taper"
        case .recovery: return "Recovery"
        case .race:     return "Race"
        }
    }

    private var activeSessionTypes: [SessionType] {
        var seen = Set<SessionType>()
        var result: [SessionType] = []
        for point in dataPoints {
            for slice in point.completedByType where !seen.contains(slice.type) {
                seen.insert(slice.type)
                result.append(slice.type)
            }
        }
        return result
    }

    // MARK: - Phase Segments

    struct PhaseSegment: Identifiable {
        let id: String
        let phase: TrainingPhase
        let points: [WeekChartDataPoint]
    }

    /// Slices the completed timeline into contiguous phase segments,
    /// each rendered as its own Area+Line in the chart. Stops at the
    /// current week so the overlay only "fills in" the planned curve
    /// up to today, like Campus Coach. Adjacent segments share their
    /// boundary point so the colour transition has no visual gap.
    private var phaseSegments: [PhaseSegment] {
        let currentIdx = dataPoints.firstIndex(where: \.isCurrentWeek)
            ?? dataPoints.lastIndex(where: { hasAnyCompleted($0) })
        guard let upTo = currentIdx else { return [] }
        let visible = Array(dataPoints.prefix(through: upTo))
        guard !visible.isEmpty else { return [] }

        var segments: [PhaseSegment] = []
        var current: [WeekChartDataPoint] = [visible[0]]
        var currentPhase = visible[0].phase
        for idx in 1..<visible.count {
            let p = visible[idx]
            if p.phase == currentPhase {
                current.append(p)
            } else {
                // Anchor the new segment to the previous segment's
                // last point so the colour band starts exactly where
                // the previous one ends, no visual gap.
                current.append(p)
                segments.append(PhaseSegment(
                    id: "\(currentPhase.rawValue)-\(segments.count)",
                    phase: currentPhase,
                    points: current
                ))
                current = [p]
                currentPhase = p.phase
            }
        }
        if !current.isEmpty {
            segments.append(PhaseSegment(
                id: "\(currentPhase.rawValue)-\(segments.count)",
                phase: currentPhase,
                points: current
            ))
        }
        return segments
    }

    /// Phases that actually appear in the visible (up-to-now) overlay.
    /// Used for the legend so we only list bands the athlete can see.
    private var activePhases: [TrainingPhase] {
        var seen = Set<TrainingPhase>()
        var result: [TrainingPhase] = []
        for seg in phaseSegments where !seen.contains(seg.phase) {
            seen.insert(seg.phase)
            result.append(seg.phase)
        }
        return result
    }

    private func hasAnyCompleted(_ point: WeekChartDataPoint) -> Bool {
        let v: Double
        switch selectedMetric {
        case .distance:  v = point.completedDistanceKm
        case .duration:  v = point.completedDurationSeconds
        case .elevation: v = point.completedElevationM
        }
        return v > 0
    }

    // MARK: - Visible Week Labels

    /// X-axis domain that exactly matches the data range. Used by
    /// `.chartXScale(domain:)` so the first/last data points pin to
    /// the chart edges and the axis ticks align under their data
    /// points (instead of Swift Charts adding default Int-axis
    /// padding that pushes W1 off the left edge).
    private var weekDomain: ClosedRange<Int> {
        let weeks = dataPoints.map(\.weekNumber)
        let lo = weeks.min() ?? 1
        let hi = weeks.max() ?? 1
        return lo...hi
    }

    /// X-axis tick positions. Returns Ints (week numbers) so the
    /// chart's X axis stays numeric and ordered. Previously these
    /// were strings ("W1", "W2", ...), which Swift Charts treats as
    /// categorical and renders in alphabetical order, so a 24-week
    /// plan rendered W1, W11, W13... W2, W20... W3, W4... instead of
    /// W1, W2, W3 sequentially. Numeric values + a string formatter
    /// in the AxisValueLabel keep the labels reading "W1, W3, W5..."
    /// in proper week order.
    private var visibleWeekNumbers: [Int] {
        let weeks = dataPoints.map(\.weekNumber)
        guard let first = weeks.first, let last = weeks.last else { return [] }
        let total = weeks.count
        // Spacing tuned so a 22-week plan reads roughly "W3 W7 W11
        // W15 W19" instead of "W1 W3 W5 ..." cramming the axis. We
        // start one step in from the first week and stop one step
        // before the last so labels never sit at the absolute chart
        // edges, Swift Charts clips/drifts labels positioned exactly
        // at the chart bounds, which is what was misaligning W1 vs
        // its data point.
        let stride: Int
        switch total {
        case 0...8:   stride = 1
        case 9...14:  stride = 3
        case 15...22: stride = 4
        case 23...30: stride = 5
        default:      stride = 7
        }
        // For short plans (≤ 8 weeks) keep first + last; otherwise
        // start at `first + 2` so the leftmost label sits cleanly
        // inside the plot area.
        var ticks: [Int] = []
        if total <= 8 {
            var w = first
            while w <= last {
                ticks.append(w)
                w += stride
            }
            if let lastTick = ticks.last, lastTick != last {
                ticks.append(last)
            }
        } else {
            var w = first + 2
            while w <= last - 1 {
                ticks.append(w)
                w += stride
            }
        }
        return ticks.sorted()
    }

    // MARK: - Summary Calculations

    private var totalFormattedValue: String {
        switch selectedMetric {
        case .distance:
            let total = dataPoints.reduce(0) { $0 + $1.completedDistanceKm }
            if total == 0 { return "-" }
            return UnitFormatter.formatDistance(total, unit: units, decimals: 0)
        case .duration:
            let totalSec = dataPoints.reduce(0) { $0 + $1.plannedDurationSeconds }
            let hours = Int(totalSec / 3600)
            return "\(hours)h"
        case .elevation:
            let total = dataPoints.reduce(0) { $0 + $1.plannedElevationM }
            return UnitFormatter.formatElevation(total, unit: units)
        }
    }

    private var avgFormattedValue: String {
        guard !dataPoints.isEmpty else { return "-" }
        let count = Double(dataPoints.count)
        switch selectedMetric {
        case .distance:
            let total = dataPoints.reduce(0) { $0 + $1.completedDistanceKm }
            let completedCount = Double(dataPoints.filter { $0.completedDistanceKm > 0 }.count)
            if completedCount == 0 { return "-" }
            return UnitFormatter.formatDistance(total / completedCount, unit: units)
        case .duration:
            let avgSec = dataPoints.reduce(0) { $0 + $1.plannedDurationSeconds } / count
            let hours = Int(avgSec / 3600)
            let mins = Int(avgSec.truncatingRemainder(dividingBy: 3600) / 60)
            return "\(hours)h\(String(format: "%02d", mins))"
        case .elevation:
            let avg = dataPoints.reduce(0) { $0 + $1.plannedElevationM } / count
            return UnitFormatter.formatElevation(avg, unit: units)
        }
    }

    private var completedWeeks: Int {
        dataPoints.filter { point in
            let active = plan.weeks.first { $0.weekNumber == point.weekNumber }?
                .sessions.filter { $0.type != .rest && !$0.isSkipped } ?? []
            return !active.isEmpty && active.allSatisfy(\.isCompleted)
        }.count
    }

    private var maxPlannedValue: Double {
        dataPoints.map { plannedValue(for: $0) }.max() ?? 1
    }

    private var nowRuleMarkYEnd: Double {
        let base = max(maxPlannedValue, 1)
        return base * 0.6
    }

    /// Horizontal alignment of the "NOW" pill relative to its rule mark.
    /// `.center` for middle weeks; flips inward at the edges so the pill
    /// never overflows the chart on early or late weeks. Edge threshold
    /// scales with plan length: 2 weeks on each side for typical plans,
    /// 1 week for very short plans (≤6 weeks) so we don't accidentally
    /// reposition the pill on most of the plan.
    private func nowPillAlignment(weekNumber: Int) -> Alignment {
        let total = dataPoints.count
        let edgeThreshold = total <= 6 ? 1 : 2
        if weekNumber <= edgeThreshold { return .leading }
        if weekNumber > total - edgeThreshold { return .trailing }
        return .center
    }

    private var peakWeekValue: String? {
        guard let peak = dataPoints.max(by: { plannedValue(for: $0) < plannedValue(for: $1) }) else {
            return nil
        }
        return "W\(peak.weekNumber)"
    }

    // MARK: - Value Accessors

    private func plannedValue(for point: WeekChartDataPoint) -> Double {
        switch selectedMetric {
        case .distance:
            return UnitFormatter.distanceValue(point.plannedDistanceKm, unit: units)
        case .duration:
            return point.plannedDurationSeconds / 3600.0
        case .elevation:
            return UnitFormatter.elevationValue(point.plannedElevationM, unit: units)
        }
    }

    private func completedValue(for point: WeekChartDataPoint) -> Double {
        switch selectedMetric {
        case .distance:
            return UnitFormatter.distanceValue(point.completedDistanceKm, unit: units)
        case .duration:
            return point.completedDurationSeconds / 3600.0
        case .elevation:
            return UnitFormatter.elevationValue(point.completedElevationM, unit: units)
        }
    }

    private func formattedPlannedValue(for point: WeekChartDataPoint) -> String {
        switch selectedMetric {
        case .distance:
            return UnitFormatter.formatDistance(point.plannedDistanceKm, unit: units)
        case .duration:
            let hours = Int(point.plannedDurationSeconds / 3600)
            let mins = Int((point.plannedDurationSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h\(mins)m"
        case .elevation:
            return UnitFormatter.formatElevation(point.plannedElevationM, unit: units)
        }
    }

    private func formattedCompletedValue(for point: WeekChartDataPoint) -> String {
        switch selectedMetric {
        case .distance:
            return UnitFormatter.formatDistance(point.completedDistanceKm, unit: units)
        case .duration:
            let hours = Int(point.completedDurationSeconds / 3600)
            let mins = Int((point.completedDurationSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h\(mins)m"
        case .elevation:
            return UnitFormatter.formatElevation(point.completedElevationM, unit: units)
        }
    }

    private func phaseColor(_ phase: TrainingPhase) -> Color {
        switch phase {
        case .base: .blue
        case .build: .orange
        case .peak: .red
        case .taper: .green
        case .recovery: .mint
        case .race: .purple
        }
    }

    private func sliceValue(for slice: SessionTypeSlice) -> Double {
        switch selectedMetric {
        case .distance:
            return UnitFormatter.distanceValue(slice.distanceKm, unit: units)
        case .duration:
            return slice.durationSeconds / 3600.0
        case .elevation:
            return UnitFormatter.elevationValue(slice.elevationM, unit: units)
        }
    }

    private func sessionTypeColor(_ type: SessionType) -> Color {
        switch type {
        case .longRun:       .indigo
        case .tempo:         .blue
        case .intervals:     .orange
        case .verticalGain:  .red
        case .backToBack:    .purple
        case .recovery:      .mint
        case .crossTraining:        .teal
        case .strengthConditioning: .mint
        case .race:          .yellow
        case .rest:                 .gray
        }
    }
}
