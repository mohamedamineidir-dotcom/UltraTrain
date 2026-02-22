import SwiftUI
import MapKit

struct FullScreenMapView: View {
    let segments: [RouteSegment]
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?
    var checkpointLocations: [(checkpoint: Checkpoint, coordinate: CLLocationCoordinate2D)] = []
    var coloringMode: RouteColoringMode = .pace
    var elevationSegments: [ElevationSegment] = []
    var heartRateSegments: [HeartRateSegment] = []
    var distanceMarkers: [(km: Int, coordinate: (Double, Double))] = []
    var segmentDetails: [SegmentDetail] = []
    var splitPaces: [Int: Double] = [:]
    @Binding var selectedSegment: SegmentDetail?
    @Environment(\.dismiss) private var dismiss
    @AppStorage("preferredMapStyle") private var mapStyleRaw = MapStylePreference.standard.rawValue

    private var mapStyle: MapStylePreference {
        MapStylePreference(rawValue: mapStyleRaw) ?? .standard
    }

    private var totalDistanceKm: Int {
        segments.last?.kilometerNumber ?? 0
    }

    private var filteredMarkers: [(km: Int, coordinate: (Double, Double))] {
        let step: Int
        if !splitPaces.isEmpty {
            step = totalDistanceKm > 10 ? 5 : 1
        } else {
            step = totalDistanceKm > 20 ? 5 : 1
        }
        return distanceMarkers.filter { $0.km % step == 0 }
    }

    private var markerAveragePace: Double {
        guard !splitPaces.isEmpty else { return 0 }
        let paces = splitPaces.values.filter { $0 > 0 }
        guard !paces.isEmpty else { return 0 }
        return paces.reduce(0, +) / Double(paces.count)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ZStack(alignment: .topLeading) {
                    MapReader { proxy in
                        Map {
                            routePolylines
                            startFinishMarkers
                            checkpointAnnotations
                            distanceMarkerAnnotations
                            selectedSegmentMarker
                        }
                        .mapStyle(MapStyleResolver.resolve(mapStyle))
                        .mapControls {
                            MapCompass()
                            MapScaleView()
                        }
                        .overlay(alignment: .topTrailing) {
                            MapStyleToggleButton(style: Binding(
                                get: { mapStyle },
                                set: { mapStyleRaw = $0.rawValue }
                            ))
                            .padding(Theme.Spacing.sm)
                        }
                        .onTapGesture { screenPoint in
                            handleTap(at: screenPoint, proxy: proxy)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Full screen route map showing \(segments.count) segments colored by \(coloringMode.rawValue). Tap to view segment details.")
                    }

                    if let detail = selectedSegment {
                        SegmentDetailPopup(detail: detail) {
                            selectedSegment = nil
                        }
                        .padding(Theme.Spacing.sm)
                        .padding(.top, Theme.Spacing.xl)
                    }
                }

                legend
            }
            .navigationTitle("Route Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Route Polylines

    @MapContentBuilder
    private var routePolylines: some MapContent {
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
    private var startFinishMarkers: some MapContent {
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
    private var checkpointAnnotations: some MapContent {
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
    private var distanceMarkerAnnotations: some MapContent {
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
    private var selectedSegmentMarker: some MapContent {
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

    private func handleTap(at screenPoint: CGPoint, proxy: MapProxy) {
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

    private var legend: some View {
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

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(Theme.Colors.label)
        }
    }

    // MARK: - Pace Color

    private var averagePace: Double {
        let paces = segments.map(\.paceSecondsPerKm).filter { $0 > 0 }
        guard !paces.isEmpty else { return 0 }
        return paces.reduce(0, +) / Double(paces.count)
    }

    private func paceColor(for segment: RouteSegment) -> Color {
        guard averagePace > 0 else { return Theme.Colors.primary }
        let ratio = segment.paceSecondsPerKm / averagePace
        if ratio < 0.9 { return Theme.Colors.success }
        if ratio <= 1.1 { return Theme.Colors.warning }
        return Theme.Colors.danger
    }

    // MARK: - Elevation Color

    private func elevationColor(for segment: ElevationSegment) -> Color {
        GradientColorHelper.color(forGradient: segment.averageGradient)
    }

    // MARK: - Heart Rate Color

    private func heartRateColor(for segment: HeartRateSegment) -> Color {
        switch segment.zone {
        case 1: Theme.Colors.zone1
        case 2: Theme.Colors.zone2
        case 3: Theme.Colors.zone3
        case 4: Theme.Colors.zone4
        default: Theme.Colors.zone5
        }
    }
}
