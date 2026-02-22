import SwiftUI
import MapKit

struct RaceCourse3DPreviewView: View {
    let courseRoute: [TrackPoint]
    var checkpoints: [Checkpoint] = []

    @Environment(\.dismiss) private var dismiss

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var cameraPitch: Double = 60
    @State private var cameraDistance: Double = 5000
    @State private var cameraHeading: Double = 0
    @State private var isFlying: Bool = false
    @State private var flyProgress: Int = 0
    @State private var showControls: Bool = true
    @State private var flyTask: Task<Void, Never>?

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
        ZStack {
            mapContent
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showControls.toggle()
                    }
                }

            controlsOverlay
        }
        .navigationTitle("3D Preview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onAppear { updateCamera() }
        .onChange(of: cameraPitch) { updateCamera() }
        .onChange(of: cameraDistance) { updateCamera() }
        .onChange(of: cameraHeading) { updateCamera() }
        .onDisappear { stopFlyAlong() }
    }

    // MARK: - Map

    private var mapContent: some View {
        Map(position: $cameraPosition) {
            routePolyline
            startFinishMarkers
            checkpointAnnotations
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
        }
    }

    // MARK: - Route Polyline

    @MapContentBuilder
    private var routePolyline: some MapContent {
        if coordinates.count >= 2 {
            MapPolyline(coordinates: coordinates)
                .stroke(Theme.Colors.primary, lineWidth: 4)
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

    // MARK: - Controls Overlay

    @ViewBuilder
    private var controlsOverlay: some View {
        if showControls {
            VStack {
                Spacer()
                Course3DCameraControls(
                    pitch: $cameraPitch,
                    heading: $cameraHeading,
                    distance: $cameraDistance,
                    isFlying: isFlying,
                    onFlyToggle: toggleFlyAlong
                )
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.md)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Camera Helpers

extension RaceCourse3DPreviewView {

    private func updateCamera() {
        let center: CLLocationCoordinate2D
        if courseRoute.isEmpty {
            center = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        } else {
            let midIndex = courseRoute.count / 2
            let mid = courseRoute[midIndex]
            center = CLLocationCoordinate2D(latitude: mid.latitude, longitude: mid.longitude)
        }
        cameraPosition = .camera(MapCamera(
            centerCoordinate: center,
            distance: cameraDistance,
            heading: cameraHeading,
            pitch: cameraPitch
        ))
    }

    private func resolveCoordinate(for checkpoint: Checkpoint) -> CLLocationCoordinate2D? {
        guard let nearest = ElevationCalculator.nearestTrackPoint(
            at: checkpoint.distanceFromStartKm,
            in: courseRoute
        ) else { return nil }
        return CLLocationCoordinate2D(latitude: nearest.latitude, longitude: nearest.longitude)
    }
}

// MARK: - Fly Along

extension RaceCourse3DPreviewView {

    private func toggleFlyAlong() {
        if isFlying {
            stopFlyAlong()
        } else {
            startFlyAlong()
        }
    }

    private func startFlyAlong() {
        guard courseRoute.count >= 2 else { return }
        isFlying = true
        flyProgress = 0

        let sampledPoints = sampleCoursePoints(targetCount: 100)

        flyTask = Task { @MainActor in
            for i in 0..<sampledPoints.count {
                guard !Task.isCancelled, isFlying else { break }

                flyProgress = i
                let point = sampledPoints[i]
                let center = CLLocationCoordinate2D(
                    latitude: point.latitude,
                    longitude: point.longitude
                )

                let heading: Double
                if i < sampledPoints.count - 1 {
                    heading = bearing(from: point, to: sampledPoints[i + 1])
                } else {
                    heading = cameraHeading
                }

                withAnimation(.easeInOut(duration: 0.18)) {
                    cameraPosition = .camera(MapCamera(
                        centerCoordinate: center,
                        distance: 2000,
                        heading: heading,
                        pitch: 65
                    ))
                }

                try? await Task.sleep(for: .milliseconds(200))
            }

            isFlying = false
        }
    }

    private func stopFlyAlong() {
        flyTask?.cancel()
        flyTask = nil
        isFlying = false
        updateCamera()
    }

    private func sampleCoursePoints(targetCount: Int) -> [TrackPoint] {
        guard courseRoute.count > targetCount else { return courseRoute }
        let step = max(1, courseRoute.count / targetCount)
        var sampled: [TrackPoint] = []
        for i in stride(from: 0, to: courseRoute.count, by: step) {
            sampled.append(courseRoute[i])
        }
        if let last = courseRoute.last, sampled.last != last {
            sampled.append(last)
        }
        return sampled
    }

    private func bearing(from: TrackPoint, to: TrackPoint) -> Double {
        let dLon = (to.longitude - from.longitude) * .pi / 180
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        return atan2(y, x) * 180 / .pi
    }
}
