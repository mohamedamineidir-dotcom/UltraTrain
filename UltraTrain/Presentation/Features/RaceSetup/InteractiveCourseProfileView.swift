import SwiftUI
import Charts

struct InteractiveCourseProfileView: View {
    @ScaledMetric(relativeTo: .caption2) private var annotationIconSize: CGFloat = 8
    @ScaledMetric(relativeTo: .caption2) private var annotationLabelSize: CGFloat = 7

    @Environment(\.unitPreference) private var units
    @State var viewModel: InteractiveCourseProfileViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            chart
                .frame(height: 200)

            gradientLegend

            if viewModel.selectedDistance != nil {
                selectionInfo
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            gradientAreaMarks
            elevationLine
            checkpointMarks
            selectionRuleMark
        }
        .chartXAxisLabel("Distance (\(UnitFormatter.distanceLabel(units)))")
        .chartYAxisLabel("Altitude (\(UnitFormatter.elevationShortLabel(units)))")
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

    // MARK: - Gradient Area Marks

    @ChartContentBuilder
    private var gradientAreaMarks: some ChartContent {
        ForEach(viewModel.gradientSegments) { segment in
            let color = GradientColorHelper.color(for: segment.category)

            AreaMark(
                x: .value("Distance", UnitFormatter.distanceValue(segment.distanceKm, unit: units)),
                yStart: .value("Base", UnitFormatter.elevationValue(viewModel.minAltitude, unit: units)),
                yEnd: .value("Altitude", UnitFormatter.elevationValue(segment.altitudeM, unit: units))
            )
            .foregroundStyle(color.opacity(0.3))

            AreaMark(
                x: .value("Distance", UnitFormatter.distanceValue(segment.endDistanceKm, unit: units)),
                yStart: .value("Base", UnitFormatter.elevationValue(viewModel.minAltitude, unit: units)),
                yEnd: .value("Altitude", UnitFormatter.elevationValue(segment.endAltitudeM, unit: units))
            )
            .foregroundStyle(color.opacity(0.3))
        }
    }

    // MARK: - Elevation Line

    @ChartContentBuilder
    private var elevationLine: some ChartContent {
        ForEach(viewModel.elevationProfile) { point in
            LineMark(
                x: .value("Distance", UnitFormatter.distanceValue(point.distanceKm, unit: units)),
                y: .value("Altitude", UnitFormatter.elevationValue(point.altitudeM, unit: units))
            )
            .foregroundStyle(Theme.Colors.label.opacity(0.7))
            .lineStyle(StrokeStyle(lineWidth: 1.5))
        }
    }

    // MARK: - Checkpoint Marks

    @ChartContentBuilder
    private var checkpointMarks: some ChartContent {
        ForEach(viewModel.checkpoints) { checkpoint in
            RuleMark(
                x: .value("CP", UnitFormatter.distanceValue(checkpoint.distanceFromStartKm, unit: units))
            )
            .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.4))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .annotation(position: .top, spacing: 2) {
                checkpointAnnotation(checkpoint)
            }
        }
    }

    // MARK: - Selection Rule Mark

    @ChartContentBuilder
    private var selectionRuleMark: some ChartContent {
        if let distKm = viewModel.selectedDistance {
            RuleMark(x: .value("Selected", UnitFormatter.distanceValue(distKm, unit: units)))
                .foregroundStyle(Theme.Colors.primary)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .annotation(position: .top, spacing: 4) {
                    selectionAnnotation
                }
        }
    }

    // MARK: - Checkpoint Annotation

    private func checkpointAnnotation(_ checkpoint: Checkpoint) -> some View {
        VStack(spacing: 0) {
            if checkpoint.hasAidStation {
                Image(systemName: "cross.circle.fill")
                    .font(.system(size: annotationIconSize))
                    .foregroundStyle(Theme.Colors.danger)
            } else {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: annotationIconSize))
                    .foregroundStyle(Theme.Colors.primary)
            }
            Text(checkpoint.name)
                .font(.system(size: annotationLabelSize))
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .lineLimit(1)
        }
    }

    // MARK: - Selection Annotation

    @ViewBuilder
    private var selectionAnnotation: some View {
        if let distText = viewModel.selectedDistanceText,
           let altText = viewModel.selectedAltitudeText {
            VStack(alignment: .leading, spacing: 4) {
                ChartAnnotationCard(
                    title: distText,
                    value: altText,
                    subtitle: viewModel.selectedGradientText
                )
                if viewModel.hasScenarioTimes {
                    splitTimeAnnotation
                }
            }
        }
    }

    /// Projected elapsed time at the scrubbed point, one row per
    /// scenario — same color coding (green/primary/orange) used
    /// everywhere else optimistic/expected/conservative appear.
    @ViewBuilder
    private var splitTimeAnnotation: some View {
        if let opt = viewModel.selectedOptimisticSplitText,
           let exp = viewModel.selectedExpectedSplitText,
           let con = viewModel.selectedConservativeSplitText {
            VStack(alignment: .leading, spacing: 2) {
                splitRow(color: Theme.Colors.success, value: opt)
                splitRow(color: Theme.Colors.primary, value: exp, emphasized: true)
                splitRow(color: Theme.Colors.warning, value: con)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Theme.Colors.shadow, radius: 4, y: 2)
            )
            .accessibilityHidden(true)
        }
    }

    private func splitRow(color: Color, value: String, emphasized: Bool = false) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(value)
                .font(.system(size: emphasized ? 11 : 10, weight: emphasized ? .bold : .semibold, design: .monospaced))
        }
    }

    // MARK: - Selection Info

    private var selectionInfo: some View {
        HStack(spacing: Theme.Spacing.md) {
            if let distText = viewModel.selectedDistanceText {
                infoItem(label: "Distance", value: distText)
            }
            if let altText = viewModel.selectedAltitudeText {
                infoItem(label: "Altitude", value: altText)
            }
            if let gradText = viewModel.selectedGradientText {
                infoItem(label: "Grade", value: gradText)
            }
            if let segment = viewModel.selectedSegment {
                infoItem(label: "Terrain", value: categoryLabel(segment.category))
            }
            if let expSplit = viewModel.selectedExpectedSplitText {
                infoItem(label: "Est. Time", value: expSplit)
            }
        }
        .font(.caption2)
        .padding(.horizontal, Theme.Spacing.sm)
    }

    private func infoItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(value)
                .bold()
        }
    }

    // MARK: - Gradient Legend

    private var gradientLegend: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(GradientCategory.allCases, id: \.self) { category in
                HStack(spacing: 3) {
                    Circle()
                        .fill(GradientColorHelper.color(for: category))
                        .frame(width: 7, height: 7)
                    Text(categoryLabel(category))
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
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
        case .steepDown: "Steep-"
        case .moderateDown: "Down"
        case .flat: "Flat"
        case .moderateUp: "Up"
        case .steepUp: "Steep+"
        }
    }

    private var accessibilitySummary: String {
        let dist = UnitFormatter.formatDistance(viewModel.totalDistanceKm, unit: units)
        let minAlt = UnitFormatter.formatElevation(viewModel.minAltitude, unit: units)
        let maxAlt = UnitFormatter.formatElevation(viewModel.maxAltitude, unit: units)
        return "Interactive course elevation profile. \(dist). Altitude \(minAlt) to \(maxAlt). Drag to explore."
    }
}
