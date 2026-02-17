import SwiftUI
import MapKit

struct RouteMapView: View {
    let segments: [RouteSegment]
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?
    var checkpointLocations: [(checkpoint: Checkpoint, coordinate: CLLocationCoordinate2D)] = []
    var coloringMode: RouteColoringMode = .pace
    var elevationSegments: [ElevationSegment] = []
    var height: CGFloat = 250

    @AppStorage("preferredMapStyle") private var mapStyleRaw = MapStylePreference.standard.rawValue

    private var mapStyle: MapStylePreference {
        MapStylePreference(rawValue: mapStyleRaw) ?? .standard
    }

    var body: some View {
        Map {
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
            }

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
        .mapStyle(MapStyleResolver.resolve(mapStyle))
        .mapControls {
            MapCompass()
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
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
        let gradient = segment.averageGradient
        if gradient > 15 { return .red }
        if gradient > 5 { return .orange }
        if gradient > -5 { return .green }
        if gradient > -15 { return .cyan }
        return .blue
    }
}
