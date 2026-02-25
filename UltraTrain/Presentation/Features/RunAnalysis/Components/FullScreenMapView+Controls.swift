import SwiftUI
import MapKit

// MARK: - Map Content Builders, Legend & Color Helpers

extension FullScreenMapView {

    // MARK: - Route Polylines

    @MapContentBuilder
    var routePolylines: some MapContent {
        switch coloringMode {
        case .pace:
            ForEach(segments) { segment in
                if segment.coordinates.count >= 2 {
                    MapPolyline(coordinates: segment.coordinates.map {
                        CLLocationCoordinate2D(latitude: $0.0, longitude: $0.1)
                    })
                    .stroke(paceColor(for: segment), lineWidth: 4)
                }
            }
        case .elevation:
            ForEach(elevationSegments) { segment in
                if segment.coordinates.count >= 2 {
                    MapPolyline(coordinates: segment.coordinates.map {
                        CLLocationCoordinate2D(latitude: $0.0, longitude: $0.1)
                    })
                    .stroke(elevationColor(for: segment), lineWidth: 4)
                }
            }
        case .heartRate:
            ForEach(heartRateSegments) { segment in
                if segment.coordinates.count >= 2 {
                    MapPolyline(coordinates: segment.coordinates.map {
                        CLLocationCoordinate2D(latitude: $0.0, longitude: $0.1)
                    })
                    .stroke(heartRateColor(for: segment), lineWidth: 4)
                }
            }
        }
    }

    // MARK: - Start / Finish

    @MapContentBuilder
    var startFinishMarkers: some MapContent {
        if let start = startCoordinate {
            Annotation("Start", coordinate: start) {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.Colors.success)
                    .background(Circle().fill(.white).padding(-2))
            }
        }

        if let end = endCoordinate {
            Annotation("Finish", coordinate: end) {
                Image(systemName: "flag.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.Colors.danger)
                    .background(Circle().fill(.white).padding(-2))
            }
        }
    }

    // MARK: - Checkpoints

    @MapContentBuilder
    var checkpointAnnotations: some MapContent {
        ForEach(Array(checkpointLocations.enumerated()), id: \.element.checkpoint.id) { _, item in
            Annotation(item.checkpoint.name, coordinate: item.coordinate) {
                CheckpointAnnotationView(
                    name: item.checkpoint.name,
                    distanceKm: item.checkpoint.distanceFromStartKm,
                    hasAidStation: item.checkpoint.hasAidStation
                )
            }
        }
    }

    // MARK: - Distance Markers

    @MapContentBuilder
    var distanceMarkerAnnotations: some MapContent {
        ForEach(filteredMarkers, id: \.km) { marker in
            Annotation("", coordinate: CLLocationCoordinate2D(
                latitude: marker.coordinate.0,
                longitude: marker.coordinate.1
            )) {
                SplitMarkerBadge(
                    km: marker.km,
                    paceSecondsPerKm: splitPaces[marker.km],
                    averagePace: markerAveragePace
                )
            }
        }
    }

    // MARK: - Selected Segment Marker

    @MapContentBuilder
    var selectedSegmentMarker: some MapContent {
        if let detail = selectedSegment {
            Annotation("", coordinate: CLLocationCoordinate2D(
                latitude: detail.coordinate.0,
                longitude: detail.coordinate.1
            )) {
                Circle()
                    .fill(Theme.Colors.primary)
                    .frame(width: 12, height: 12)
                    .background(Circle().fill(.white).frame(width: 16, height: 16))
            }
        }
    }

    // MARK: - Tap Handling

    func handleTap(at screenPoint: CGPoint, proxy: MapProxy) {
        guard let tappedCoord = proxy.convert(screenPoint, from: .local) else {
            selectedSegment = nil
            return
        }

        var closest: SegmentDetail?
        var closestDistance = Double.greatestFiniteMagnitude

        for detail in segmentDetails {
            let dist = RunStatisticsCalculator.haversineDistance(
                lat1: tappedCoord.latitude, lon1: tappedCoord.longitude,
                lat2: detail.coordinate.0, lon2: detail.coordinate.1
            )
            if dist < closestDistance {
                closestDistance = dist
                closest = detail
            }
        }

        if closestDistance < 500 {
            selectedSegment = closest
        } else {
            selectedSegment = nil
        }
    }

    // MARK: - Legend

    var legend: some View {
        Group {
            switch coloringMode {
            case .pace:
                HStack(spacing: Theme.Spacing.lg) {
                    legendDot(color: Theme.Colors.success, label: "Fast")
                    legendDot(color: Theme.Colors.warning, label: "Average")
                    legendDot(color: Theme.Colors.danger, label: "Slow")
                }
            case .elevation:
                HStack(spacing: Theme.Spacing.sm) {
                    legendDot(color: .red, label: "Steep Up")
                    legendDot(color: .orange, label: "Up")
                    legendDot(color: .green, label: "Flat")
                    legendDot(color: .cyan, label: "Down")
                    legendDot(color: .blue, label: "Steep Down")
                }
            case .heartRate:
                HStack(spacing: Theme.Spacing.sm) {
                    legendDot(color: Theme.Colors.zone1, label: "Z1")
                    legendDot(color: Theme.Colors.zone2, label: "Z2")
                    legendDot(color: Theme.Colors.zone3, label: "Z3")
                    legendDot(color: Theme.Colors.zone4, label: "Z4")
                    legendDot(color: Theme.Colors.zone5, label: "Z5")
                }
            }
        }
        .font(.caption)
        .padding(Theme.Spacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
        .padding(.bottom, Theme.Spacing.md)
    }

    func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(Theme.Colors.label)
        }
    }

    // MARK: - Pace Color

    var averagePace: Double {
        let paces = segments.map(\.paceSecondsPerKm).filter { $0 > 0 }
        guard !paces.isEmpty else { return 0 }
        return paces.reduce(0, +) / Double(paces.count)
    }

    func paceColor(for segment: RouteSegment) -> Color {
        guard averagePace > 0 else { return Theme.Colors.primary }
        let ratio = segment.paceSecondsPerKm / averagePace
        if ratio < 0.9 { return Theme.Colors.success }
        if ratio <= 1.1 { return Theme.Colors.warning }
        return Theme.Colors.danger
    }

    // MARK: - Elevation Color

    func elevationColor(for segment: ElevationSegment) -> Color {
        GradientColorHelper.color(forGradient: segment.averageGradient)
    }

    // MARK: - Heart Rate Color

    func heartRateColor(for segment: HeartRateSegment) -> Color {
        switch segment.zone {
        case 1: Theme.Colors.zone1
        case 2: Theme.Colors.zone2
        case 3: Theme.Colors.zone3
        case 4: Theme.Colors.zone4
        default: Theme.Colors.zone5
        }
    }
}
