import SwiftUI
import Charts
import MapKit

struct InteractiveElevationMapView: View {
    @Environment(\.unitPreference) private var units

    let elevationProfile: [ElevationProfilePoint]
    let trackPoints: [TrackPoint]
    var checkpointDistances: [(name: String, distanceKm: Double)] = []

    @State private var selectedDistanceKm: Double?
    @State private var selectedAltitudeM: Double?
    @State private var highlightCoordinate: CLLocationCoordinate2D?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Interactive Profile")
                .font(.headline)

            elevationChart
                .frame(height: 160)

            mapSection
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Interactive map showing the run route. Drag on the elevation chart above to highlight a position on the map.")
        }
        .cardStyle()
    }

    // MARK: - Elevation Chart

    private var elevationChart: some View {
        Chart {
            ForEach(elevationProfile) { point in
                AreaMark(
                    x: .value("Distance", UnitFormatter.distanceValue(point.distanceKm, unit: units)),
                    y: .value("Altitude", UnitFormatter.elevationValue(point.altitudeM, unit: units))
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            Theme.Colors.primary.opacity(0.3),
                            Theme.Colors.primary.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Distance", UnitFormatter.distanceValue(point.distanceKm, unit: units)),
                    y: .value("Altitude", UnitFormatter.elevationValue(point.altitudeM, unit: units))
                )
                .foregroundStyle(Theme.Colors.primary)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            ForEach(Array(checkpointDistances.enumerated()), id: \.offset) { _, cp in
                RuleMark(x: .value("CP", UnitFormatter.distanceValue(cp.distanceKm, unit: units)))
                    .foregroundStyle(Theme.Colors.secondaryLabel.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 2]))
            }

            if let dist = selectedDistanceKm {
                RuleMark(x: .value("Selected", UnitFormatter.distanceValue(dist, unit: units)))
                    .foregroundStyle(Theme.Colors.danger)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .annotation(position: .top, spacing: 4) {
                        if let alt = selectedAltitudeM {
                            ChartAnnotationCard(
                                title: UnitFormatter.formatDistance(dist, unit: units),
                                value: UnitFormatter.formatElevation(alt, unit: units)
                            )
                        }
                    }
            }
        }
        .chartXAxisLabel("Distance (\(UnitFormatter.distanceLabel(units)))")
        .chartYAxis(.hidden)
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
                                selectedDistanceKm = nil
                                selectedAltitudeM = nil
                                highlightCoordinate = nil
                            }
                    )
            }
        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        Map {
            MapPolyline(coordinates: trackPoints.map {
                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            })
            .stroke(Theme.Colors.primary, lineWidth: 3)

            if let coord = highlightCoordinate {
                Annotation("", coordinate: coord) {
                    Circle()
                        .fill(Theme.Colors.danger)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        )
                }
            }
        }
        .mapControls {
            MapCompass()
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

        let distanceKm = UnitFormatter.distanceToKm(displayDistance, unit: units)
        let clampedDistance = max(0, min(distanceKm, elevationProfile.last?.distanceKm ?? 0))
        selectedDistanceKm = clampedDistance

        if let closest = elevationProfile.min(by: {
            abs($0.distanceKm - clampedDistance) < abs($1.distanceKm - clampedDistance)
        }) {
            selectedAltitudeM = closest.altitudeM
        }

        if let point = ElevationCalculator.nearestTrackPoint(at: clampedDistance, in: trackPoints) {
            highlightCoordinate = CLLocationCoordinate2D(
                latitude: point.latitude,
                longitude: point.longitude
            )
        }
    }
}
