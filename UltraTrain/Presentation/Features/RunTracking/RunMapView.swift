import SwiftUI
import MapKit

struct RunMapView: View {
    let coordinates: [CLLocationCoordinate2D]
    var showsUserLocation: Bool = true
    var startCoordinate: CLLocationCoordinate2D?
    var endCoordinate: CLLocationCoordinate2D?
    var checkpointLocations: [(checkpoint: Checkpoint, coordinate: CLLocationCoordinate2D)] = []
    var height: CGFloat = 200

    @AppStorage("preferredMapStyle") private var mapStyleRaw = MapStylePreference.standard.rawValue
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var isFollowing = true

    private var mapStyle: MapStylePreference {
        MapStylePreference(rawValue: mapStyleRaw) ?? .standard
    }

    var body: some View {
        Map(position: $cameraPosition) {
            if coordinates.count >= 2 {
                MapPolyline(coordinates: coordinates)
                    .stroke(Theme.Colors.primary, lineWidth: 3)
            }

            if let start = startCoordinate {
                Annotation("Start", coordinate: start) {
                    Image(systemName: "play.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.success)
                        .background(Circle().fill(.white).padding(-1))
                }
            }

            if let end = endCoordinate {
                Annotation("Finish", coordinate: end) {
                    Image(systemName: "flag.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.danger)
                        .background(Circle().fill(.white).padding(-1))
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

            if showsUserLocation {
                UserAnnotation()
            }
        }
        .mapStyle(MapStyleResolver.resolve(mapStyle))
        .mapControls {
            MapCompass()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            guard showsUserLocation, let last = coordinates.last else { return }
            let centerLat = context.camera.centerCoordinate.latitude
            let centerLon = context.camera.centerCoordinate.longitude
            let distance = RunStatisticsCalculator.haversineDistance(
                lat1: centerLat, lon1: centerLon,
                lat2: last.latitude, lon2: last.longitude
            )
            if distance > 100 {
                isFollowing = false
            }
        }
        .onChange(of: coordinates.count) {
            guard isFollowing, let last = coordinates.last else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                cameraPosition = .camera(MapCamera(
                    centerCoordinate: last,
                    distance: 800
                ))
            }
        }
        .overlay(alignment: .topTrailing) {
            MapStyleToggleButton(style: Binding(
                get: { mapStyle },
                set: { mapStyleRaw = $0.rawValue }
            ))
            .padding(Theme.Spacing.sm)
        }
        .overlay(alignment: .bottomTrailing) {
            if showsUserLocation && !isFollowing {
                MapRecenterButton {
                    guard let last = coordinates.last else { return }
                    isFollowing = true
                    withAnimation(.easeInOut(duration: 0.3)) {
                        cameraPosition = .camera(MapCamera(
                            centerCoordinate: last,
                            distance: 800
                        ))
                    }
                }
                .padding(Theme.Spacing.sm)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFollowing)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }
}
