import SwiftUI
import MapKit

struct RouteComparisonOverlay: View {
    let actualRoute: [TrackPoint]
    let plannedRoute: [TrackPoint]
    let comparison: RouteComparisonCalculator.RouteComparison

    @AppStorage("preferredMapStyle") private var mapStyleRaw = MapStylePreference.standard.rawValue

    private var mapStyle: MapStylePreference {
        MapStylePreference(rawValue: mapStyleRaw) ?? .standard
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Route Comparison")
                .font(.headline)

            mapView
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))

            summaryCard

            legend
        }
        .cardStyle()
    }

    // MARK: - Map

    private var mapView: some View {
        Map {
            plannedPolyline
            deviationHighlights
            actualPolyline
        }
        .mapStyle(MapStyleResolver.resolve(mapStyle))
        .mapControls {
            MapCompass()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Route comparison map showing planned course and actual route. Max deviation \(formatMeters(comparison.maxDeviationMeters)), average deviation \(formatMeters(comparison.averageDeviationMeters))")
    }

    @MapContentBuilder
    private var plannedPolyline: some MapContent {
        let coords = plannedRoute.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        if coords.count >= 2 {
            MapPolyline(coordinates: coords)
                .stroke(Theme.Colors.info, style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
        }
    }

    @MapContentBuilder
    private var actualPolyline: some MapContent {
        let coords = actualRoute.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        if coords.count >= 2 {
            MapPolyline(coordinates: coords)
                .stroke(Theme.Colors.success, lineWidth: 3)
        }
    }

    @MapContentBuilder
    private var deviationHighlights: some MapContent {
        ForEach(
            Array(comparison.deviationSegments.filter(\.isSignificant).enumerated()),
            id: \.offset
        ) { _, segment in
            let sliceEnd = min(segment.endIndex + 1, actualRoute.count)
            let sliceStart = max(0, segment.startIndex)
            if sliceStart < sliceEnd {
                let coords = actualRoute[sliceStart..<sliceEnd].map {
                    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                }
                if coords.count >= 2 {
                    MapPolyline(coordinates: coords)
                        .stroke(deviationColor(for: segment), lineWidth: 5)
                }
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        HStack(spacing: Theme.Spacing.lg) {
            deviationStat(
                label: "Max Deviation",
                meters: comparison.maxDeviationMeters
            )
            deviationStat(
                label: "Avg Deviation",
                meters: comparison.averageDeviationMeters
            )
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
    }

    private func deviationStat(label: String, meters: Double) -> some View {
        VStack(spacing: 2) {
            Text(formatMeters(meters))
                .font(.subheadline.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(formatMeters(meters))")
    }

    private func formatMeters(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: Theme.Spacing.md) {
            legendItem(color: Theme.Colors.info, label: "Planned", dashed: true)
            legendItem(color: Theme.Colors.success, label: "Actual", dashed: false)
            legendItem(color: Theme.Colors.danger, label: "Off-course", dashed: false)
        }
    }

    private func legendItem(color: Color, label: String, dashed: Bool) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            if dashed {
                Rectangle()
                    .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    .frame(width: 16, height: 2)
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 16, height: 3)
                    .clipShape(Capsule())
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Helpers

    private func deviationColor(
        for segment: RouteComparisonCalculator.DeviationSegment
    ) -> Color {
        segment.averageDeviationMeters > 200 ? Theme.Colors.danger : Theme.Colors.warning
    }
}
