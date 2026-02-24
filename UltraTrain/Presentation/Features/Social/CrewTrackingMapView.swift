import SwiftUI
import MapKit

struct CrewTrackingMapView: View {
    let participants: [CrewParticipant]
    var courseRoute: [TrackPoint] = []
    var checkpoints: [Checkpoint] = []
    var height: CGFloat = 250

    @AppStorage("preferredMapStyle") private var mapStyleRaw = MapStylePreference.standard.rawValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var hasUserPanned = false

    private var mapStyle: MapStylePreference {
        MapStylePreference(rawValue: mapStyleRaw) ?? .standard
    }

    var body: some View {
        Map(position: $cameraPosition) {
            coursePolyline
            checkpointAnnotations
            participantAnnotations
        }
        .mapStyle(MapStyleResolver.resolve(mapStyle))
        .mapControls {
            MapCompass()
        }
        .onMapCameraChange(frequency: .onEnd) { _ in
            hasUserPanned = true
        }
        .onChange(of: participants) {
            guard !hasUserPanned else { return }
            fitToParticipants()
        }
        .onAppear {
            fitToParticipants()
        }
        .overlay(alignment: .topTrailing) {
            MapStyleToggleButton(style: Binding(
                get: { mapStyle },
                set: { mapStyleRaw = $0.rawValue }
            ))
            .padding(Theme.Spacing.sm)
        }
        .overlay(alignment: .bottomTrailing) {
            if hasUserPanned {
                MapRecenterButton {
                    hasUserPanned = false
                    fitToParticipants()
                }
                .padding(Theme.Spacing.sm)
                .transition(.opacity)
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.2), value: hasUserPanned)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Crew tracking map with \(participants.count) participants")
    }

    // MARK: - Map Content

    @MapContentBuilder
    private var coursePolyline: some MapContent {
        if courseRoute.count >= 2 {
            let coords = courseRoute.map {
                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            }
            MapPolyline(coordinates: coords)
                .stroke(Theme.Colors.primary.opacity(0.5), lineWidth: 3)
        }
    }

    @MapContentBuilder
    private var checkpointAnnotations: some MapContent {
        ForEach(checkpoints) { cp in
            if let lat = cp.latitude, let lon = cp.longitude {
                Annotation(cp.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                    CheckpointAnnotationView(
                        name: cp.name,
                        distanceKm: cp.distanceFromStartKm,
                        hasAidStation: cp.hasAidStation
                    )
                }
            }
        }
    }

    @MapContentBuilder
    private var participantAnnotations: some MapContent {
        ForEach(validParticipants, id: \.id) { participant in
            Annotation(
                participant.displayName,
                coordinate: CLLocationCoordinate2D(
                    latitude: participant.latitude,
                    longitude: participant.longitude
                )
            ) {
                ParticipantAnnotationView(
                    name: participant.displayName,
                    paceSecondsPerKm: participant.currentPaceSecondsPerKm,
                    lastUpdated: participant.lastUpdated
                )
            }
        }
    }

    // MARK: - Helpers

    private var validParticipants: [CrewParticipant] {
        participants.filter { $0.latitude != 0 || $0.longitude != 0 }
    }

    private var participantCoordinates: [CLLocationCoordinate2D] {
        validParticipants.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
    }

    private func fitToParticipants() {
        let coords = participantCoordinates
        guard !coords.isEmpty else { return }

        if coords.count == 1, let first = coords.first {
            let newPosition = MapCameraPosition.camera(MapCamera(
                centerCoordinate: first,
                distance: 2000
            ))
            applyCamera(newPosition)
            return
        }

        var minLat = coords[0].latitude
        var maxLat = coords[0].latitude
        var minLon = coords[0].longitude
        var maxLon = coords[0].longitude

        for coord in coords {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.005),
            longitudeDelta: max((maxLon - minLon) * 1.4, 0.005)
        )
        let region = MKCoordinateRegion(center: center, span: span)
        applyCamera(.region(region))
    }

    private func applyCamera(_ position: MapCameraPosition) {
        if reduceMotion {
            cameraPosition = position
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                cameraPosition = position
            }
        }
    }
}
