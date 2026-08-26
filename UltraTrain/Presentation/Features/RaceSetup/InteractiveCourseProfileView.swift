import SwiftUI
import Charts

struct InteractiveCourseProfileView: View {
    @ScaledMetric(relativeTo: .caption2) private var annotationLabelSize: CGFloat = 7

    @Environment(\.unitPreference) private var units
    @Environment(\.colorScheme) private var colorScheme
    @State var viewModel: InteractiveCourseProfileViewModel
    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            axisCaption

            chart
                .frame(height: 270)
                // Bleeds all the way to the card's own edge inset so the
                // chart — the hero content here — uses the full width
                // available instead of sharing the same inset as text,
                // giving more precision to drag across and read the curve.
                .padding(.horizontal, -Theme.Spacing.md)
                .opacity(hasAppeared ? 1 : 0)
                .scaleEffect(hasAppeared ? 1 : 0.97, anchor: .bottom)
                .onAppear {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                        hasAppeared = true
                    }
                }

            gradientLegend

            scrubReadout
        }
        .padding(Theme.Spacing.md)
        .premiumChartCardStyle(tint: Theme.Colors.primary)
        // Selection changes drive several small text/mark updates at once
        // (readout values, rule mark, point mark); without this, SwiftUI's
        // implicit animation can interpolate a sub-pixel layout delta
        // between drags into a visible, if faint, resize motion.
        .animation(nil, value: viewModel.selectedDistance)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: viewModel.selectedDistance == nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Axis Caption
    // Rendered as plain sibling text above the chart (not an in-plot
    // `.chartYAxisLabel`) so it can never visually collide with a
    // checkpoint pin or the drag-selection line near the plot's edges.

    private var axisCaption: some View {
        HStack {
            Label("Course Profile", systemImage: "chart.xyaxis.line")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.Colors.label)
            Spacer()
            Text("Altitude (\(UnitFormatter.elevationShortLabel(units)))")
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Unit-aware selection text
    // Formatted here (not in the view model) so it always reflects the
    // athlete's current metric/imperial preference.

    private var selectedDistanceText: String? {
        viewModel.selectedDistance.map {
            UnitFormatter.formatDistance($0, unit: units, decimals: 2)
        }
    }

    private var selectedAltitudeText: String? {
        viewModel.selectedAltitude.map {
            UnitFormatter.formatElevation($0, unit: units)
        }
    }

    private var selectedCumulativeGainText: String? {
        viewModel.selectedCumulativeGain.map {
            UnitFormatter.formatElevation($0, unit: units)
        }
    }

    // MARK: - Adaptive Axis Domains
    // Converted to display units so they line up with the marks below,
    // which are plotted via the same `UnitFormatter` calls.

    private var altitudeAxisDomain: ClosedRange<Double> {
        let domain = viewModel.altitudeDomain
        let lower = UnitFormatter.elevationValue(domain.lowerBound, unit: units)
        let upper = UnitFormatter.elevationValue(domain.upperBound, unit: units)
        return lower...upper
    }

    private var distanceAxisDomain: ClosedRange<Double> {
        let domain = viewModel.distanceDomain
        let lower = UnitFormatter.distanceValue(domain.lowerBound, unit: units)
        let upper = UnitFormatter.distanceValue(domain.upperBound, unit: units)
        return lower...upper
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            areaFill
            terrainColoredLine
            checkpointMarks
            selectionRuleMark
            selectionPointMark
        }
        .chartXScale(domain: distanceAxisDomain)
        .chartYScale(domain: altitudeAxisDomain)
        .chartXAxis {
            AxisMarks(preset: .automatic) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [1, 3]))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.20))
                AxisValueLabel()
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .chartYAxis {
            AxisMarks(preset: .automatic) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.12))
                AxisValueLabel()
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .chartXAxisLabel("Distance (\(UnitFormatter.distanceLabel(units)))")
        // Reserves real clearance above the plot for checkpoint pins,
        // which are positioned relative to the PLOT's own top edge (not
        // the terrain data), so they need guaranteed room within the
        // chart's own frame — otherwise they render outside the frame
        // entirely and collide with the header row above it.
        .padding(.top, 26)
        .chartBackground { proxy in
            summitGlow(proxy: proxy)
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleDrag(value: value, proxy: proxy, geometry: geometry)
                            }
                            .onEnded { _ in
                                viewModel.clearSelection()
                            }
                    )
            }
        }
    }

    // MARK: - Summit Glow
    // A soft ambient glow behind the course's highest point — a subtle
    // "energy" accent rather than a literal light source, positioned via
    // the chart's own coordinate space so it always sits over the real
    // summit regardless of screen size or the adaptive Y domain.

    @ViewBuilder
    private func summitGlow(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            if let plotFrame = proxy.plotFrame {
                let frame = geometry[plotFrame]
                let peakX = UnitFormatter.distanceValue(viewModel.peakDistanceKm, unit: units)
                let peakY = UnitFormatter.elevationValue(viewModel.maxAltitude, unit: units)
                if let xPosition = proxy.position(forX: peakX),
                   let yPosition = proxy.position(forY: peakY) {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.Colors.primary.opacity(colorScheme == .dark ? 0.30 : 0.16), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 85
                            )
                        )
                        .frame(width: 170, height: 170)
                        .position(x: frame.minX + xPosition, y: frame.minY + yPosition)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Area Fill
    // A richer glass-like gradient — a bright band concentrated right at
    // the ridge line (light catching the top edge), fading through a
    // mid-tone, down to nearly transparent at the base — rather than a
    // flat linear fade. One cohesive accent tone for the whole course;
    // terrain difficulty reads on the line itself (see
    // `terrainColoredLine`), not by washing the entire filled area in
    // five saturated hues (which read as a green/blue duotone, a
    // "night-vision" look, rather than a clean chart surface).

    @ChartContentBuilder
    private var areaFill: some ChartContent {
        ForEach(viewModel.gradientSegments) { segment in
            AreaMark(
                x: .value("Distance", UnitFormatter.distanceValue(segment.distanceKm, unit: units)),
                yStart: .value("Base", UnitFormatter.elevationValue(viewModel.minAltitude, unit: units)),
                yEnd: .value("Altitude", UnitFormatter.elevationValue(segment.altitudeM, unit: units))
            )
            .foregroundStyle(premiumAreaGradient)

            AreaMark(
                x: .value("Distance", UnitFormatter.distanceValue(segment.endDistanceKm, unit: units)),
                yStart: .value("Base", UnitFormatter.elevationValue(viewModel.minAltitude, unit: units)),
                yEnd: .value("Altitude", UnitFormatter.elevationValue(segment.endAltitudeM, unit: units))
            )
            .foregroundStyle(premiumAreaGradient)
        }
    }

    private var premiumAreaGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Theme.Colors.primary.opacity(0.60), location: 0.0),
                .init(color: Theme.Colors.primary.opacity(0.24), location: 0.20),
                .init(color: Theme.Colors.primary.opacity(0.03), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Terrain-Colored Line
    // A single crisp line (no blurred glow underlay), colored per
    // segment by terrain category — the same information a rainbow-
    // filled area used to convey, now precise and legible instead of a
    // wash of color across the whole chart. Traces the exact same
    // 100m-sampled points as the area fill, so the two always agree.

    @ChartContentBuilder
    private var terrainColoredLine: some ChartContent {
        ForEach(viewModel.gradientSegments) { segment in
            let color = GradientColorHelper.color(for: segment.category)

            LineMark(
                x: .value("Distance", UnitFormatter.distanceValue(segment.distanceKm, unit: units)),
                y: .value("Altitude", UnitFormatter.elevationValue(segment.altitudeM, unit: units))
            )
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: 2.25, lineCap: .round, lineJoin: .round))

            LineMark(
                x: .value("Distance", UnitFormatter.distanceValue(segment.endDistanceKm, unit: units)),
                y: .value("Altitude", UnitFormatter.elevationValue(segment.endAltitudeM, unit: units))
            )
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: 2.25, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: - Checkpoint Marks

    @ChartContentBuilder
    private var checkpointMarks: some ChartContent {
        ForEach(viewModel.checkpoints) { checkpoint in
            RuleMark(
                x: .value("CP", UnitFormatter.distanceValue(checkpoint.distanceFromStartKm, unit: units))
            )
            .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.35))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .annotation(position: .top, spacing: 6) {
                checkpointAnnotation(checkpoint)
            }
        }
    }

    // MARK: - Selection Rule Mark
    // A single crisp vertical line — no blurred glow duplicate — ties
    // the fixed `scrubReadout` panel below to a position on the chart.

    @ChartContentBuilder
    private var selectionRuleMark: some ChartContent {
        if let distKm = viewModel.selectedDistance {
            RuleMark(x: .value("Selected", UnitFormatter.distanceValue(distKm, unit: units)))
                .foregroundStyle(Theme.Colors.label.opacity(0.55))
                .lineStyle(StrokeStyle(lineWidth: 1.5))
        }
    }

    // MARK: - Selection Point Mark
    // A ringed marker exactly where the selection line crosses the
    // terrain curve — the tactile, precise "you are here" touch used in
    // Apple's own Health/Stocks charts, and a much more satisfying
    // scrubbing affordance than the rule line alone.

    @ChartContentBuilder
    private var selectionPointMark: some ChartContent {
        if let distKm = viewModel.selectedDistance, let altM = viewModel.selectedAltitude {
            let x = UnitFormatter.distanceValue(distKm, unit: units)
            let y = UnitFormatter.elevationValue(altM, unit: units)
            PointMark(x: .value("Selected", x), y: .value("Altitude", y))
                .foregroundStyle(.white)
                .symbolSize(100)
            PointMark(x: .value("Selected", x), y: .value("Altitude", y))
                .foregroundStyle(Theme.Colors.primary)
                .symbolSize(44)
        }
    }

    // MARK: - Checkpoint Annotation
    // Compact by design — every extra point of height here is a point of
    // headroom the chart has to reserve above the plot (see the chart's
    // own `.padding(.top, 26)`) before it risks colliding with the
    // header row above the whole card. No time here (was tried and
    // reverted — too many pins each carrying a barely-legible time made
    // the chart noisier without being readable; the scrub readout below
    // is the one clear place for the live projected time).

    private func checkpointAnnotation(_ checkpoint: Checkpoint) -> some View {
        HStack(spacing: 2) {
            Image(systemName: checkpoint.hasAidStation ? "cross.circle.fill" : "mappin.circle.fill")
                .font(.system(size: annotationLabelSize))
                .foregroundStyle(checkpoint.hasAidStation ? Theme.Colors.danger : Theme.Colors.primary)
            Text(checkpoint.name)
                .font(.system(size: annotationLabelSize, weight: .semibold))
                .foregroundStyle(Theme.Colors.label)
                .lineLimit(1)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            Capsule().fill(.ultraThinMaterial)
        )
    }

    // MARK: - Scrub Readout
    // A fixed panel below the chart that ALWAYS renders the exact same
    // view types in the exact same structure — placeholder dashes and a
    // plain-text hint when idle, real values when scrubbing — so its
    // size can never change based on selection state. (An earlier
    // version mixed an SF Symbol into the idle row only; icon glyphs and
    // text glyphs don't always report identical intrinsic heights, which
    // was enough to produce a hairline size difference between states.)

    private var scrubReadout: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Equal-width columns (not content-sized) — each slot's width
            // is fixed by the row's own total width, never by how many
            // digits happen to be in the current value, so crossing a
            // digit-count boundary mid-drag (e.g. "9.11 km" -> "13.03 km")
            // can never nudge this row's layout by even a hairline.
            HStack(spacing: Theme.Spacing.sm) {
                readoutValue(label: "Distance", value: selectedDistanceText ?? "—")
                readoutValue(label: "Altitude", value: selectedAltitudeText ?? "—")
                readoutValue(label: "D+", value: selectedCumulativeGainText ?? "—", tint: Theme.Colors.danger)
                // Promoted to a peer of Distance/Altitude/D+ rather than a
                // small caption below — the projected time while scrubbing
                // is exactly as important to notice at a glance as the
                // others, not a footnote. `hasScenarioTimes` is fixed for
                // this instance's lifetime (set once at init), so this
                // never toggles mid-drag the way selection values do.
                if viewModel.hasScenarioTimes {
                    readoutValue(label: "Time", value: viewModel.selectedExpectedSplitText ?? "—", tint: Theme.Colors.primary)
                }
            }

            Group {
                if viewModel.selectedDistance != nil {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text(viewModel.selectedGradientText ?? "—")
                        Text(viewModel.selectedSegment.map { categoryLabel($0.category) } ?? "—")
                    }
                } else {
                    Text("Drag across the chart to explore")
                }
            }
            .font(.caption2)
            .foregroundStyle(Theme.Colors.secondaryLabel)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.primary.opacity(colorScheme == .dark ? 0.10 : 0.06),
                            Theme.Colors.primary.opacity(colorScheme == .dark ? 0.03 : 0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .stroke(Theme.Colors.primary.opacity(colorScheme == .dark ? 0.18 : 0.10), lineWidth: 0.75)
        )
    }

    private func readoutValue(label: LocalizedStringKey, value: String, tint: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(tint ?? Theme.Colors.label)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        // Each column claims an equal, fixed third of the row — sized by
        // the parent, never by this item's own content — so the value's
        // digit count can change freely without moving anything else.
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Gradient Legend
    // Chips flow onto a second row as whole units when they don't all
    // fit — never breaking a label mid-word, which is what made the
    // legend look broken (each chip wrapping onto a different number of
    // lines depending on its own label length and allotted width).

    private var gradientLegend: some View {
        FlowLayout(spacing: Theme.Spacing.xs) {
            ForEach(GradientCategory.allCases, id: \.self) { category in
                let color = GradientColorHelper.color(for: category)
                HStack(spacing: 5) {
                    Circle()
                        .fill(color)
                        .frame(width: 7, height: 7)
                    Text(categoryLabel(category))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .lineLimit(1)
                        .fixedSize()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(color.opacity(colorScheme == .dark ? 0.12 : 0.08))
                )
            }
        }
    }

    // MARK: - Drag Handling

    private func handleDrag(
        value: DragGesture.Value,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        let plotFrame = geometry[proxy.plotFrame!]
        let xPosition = value.location.x - plotFrame.origin.x
        guard let displayDistance: Double = proxy.value(atX: xPosition) else { return }
        let distKm = UnitFormatter.distanceToKm(displayDistance, unit: units)
        viewModel.selectPoint(at: distKm)
    }

    // MARK: - Helpers

    private func categoryLabel(_ category: GradientCategory) -> String {
        switch category {
        case .steepDown:
            String(localized: "course.gradient.steepDown", defaultValue: "Steep-")
        case .moderateDown:
            String(localized: "course.gradient.down", defaultValue: "Down")
        case .flat:
            String(localized: "course.gradient.flat", defaultValue: "Flat")
        case .moderateUp:
            String(localized: "course.gradient.up", defaultValue: "Up")
        case .steepUp:
            String(localized: "course.gradient.steepUp", defaultValue: "Steep+")
        }
    }

    private var accessibilitySummary: String {
        let dist = UnitFormatter.formatDistance(viewModel.totalDistanceKm, unit: units)
        let minAlt = UnitFormatter.formatElevation(viewModel.minAltitude, unit: units)
        let maxAlt = UnitFormatter.formatElevation(viewModel.maxAltitude, unit: units)
        return String(
            format: String(
                localized: "course.chart.a11ySummary",
                defaultValue: "Interactive course elevation profile. %@. Altitude %@ to %@. Drag to explore."
            ),
            dist, minAlt, maxAlt
        )
    }
}
