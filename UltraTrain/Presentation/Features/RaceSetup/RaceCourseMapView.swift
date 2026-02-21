import SwiftUI
import MapKit

struct RaceCourseMapView: View {
    @Environment(\.unitPreference) private var units

    let courseRoute: [TrackPoint]
    var checkpoints: [Checkpoint] = []
    var height: CGFloat = 250

    @AppStorage("preferredMapStyle") private var mapStyleRaw = MapStylePreference.standard.rawValue

    private var mapStyle: MapStylePreference {
        MapStylePreference(rawValue: mapStyleRaw) ?? .standard
    }

    private var coordinates: [CLLocationCoordinate2D] {
        courseRoute.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
    }

    private var startCoordinate: CLLocationCoordinate2D? {
        coordinates.first
    }

    private var endCoordinate: CLLocationCoordinate2D? {
        coordinates.last
    }

    var body: some View {
        Map {
            routePolyline
            startFinishMarkers
            checkpointAnnotations
        }
        .mapStyle(MapStyleResolver.resolve(mapStyle))
        .mapControls {
            MapCompass()
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Route Polyline

    @MapContentBuilder
    private var routePolyline: some MapContent {
        if coordinates.count >= 2 {
            MapPolyline(coordinates: coordinates)
                .stroke(Theme.Colors.primary, lineWidth: 3)
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
        ForEach(checkpoints) { cp in
            if let coord = resolveCoordinate(for: cp) {
                Annotation(cp.name, coordinate: coord) {
                    CheckpointAnnotationView(
                        name: cp.name,
                        distanceKm: cp.distanceFromStartKm,
                        hasAidStation: cp.hasAidStation
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    private func resolveCoordinate(for checkpoint: Checkpoint) -> CLLocationCoordinate2D? {
        guard let nearest = ElevationCalculator.nearestTrackPoint(
            at: checkpoint.distanceFromStartKm,
            in: courseRoute
        ) else { return nil }
        return CLLocationCoordinate2D(latitude: nearest.latitude, longitude: nearest.longitude)
    }

    private var accessibilitySummary: String {
        let totalDist = RunStatisticsCalculator.totalDistanceKm(courseRoute)
        let distStr = UnitFormatter.formatDistance(totalDist, unit: units)
        return "Race course map. \(distStr) with \(checkpoints.count) checkpoints."
    }
}
