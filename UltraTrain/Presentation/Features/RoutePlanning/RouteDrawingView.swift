import SwiftUI
import MapKit

struct RouteDrawingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RouteDrawingViewModel()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapStylePreference: MapStylePreference = .standard
    @State private var showSaveAlert = false
    @State private var saveError: String?

    @AppStorage("preferredMapStyle") private var mapStyleRaw = MapStylePreference.standard.rawValue

    let routeRepository: any RouteRepository

    var body: some View {
        NavigationStack {
            ZStack {
                mapContent
                overlayControls
                if viewModel.isResolving {
                    resolvingOverlay
                }
            }
            .navigationTitle("Draw Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert("Name Your Route", isPresented: $showSaveAlert) {
                TextField("Route name", text: $viewModel.routeName)
                Button("Save") { performSave() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter a name for your new route.")
            }
            .alert("Error", isPresented: .constant(saveError != nil)) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    // MARK: - Map

    private var mapContent: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                routePolyline
                waypointAnnotations
                checkpointAnnotations
            }
            .mapStyle(MapStyleResolver.resolve(mapStylePreference))
            .mapControls { MapCompass() }
            .onTapGesture { screenPoint in
                guard let coordinate = proxy.convert(screenPoint, from: .local) else { return }
                handleTap(coordinate)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    @MapContentBuilder
    private var routePolyline: some MapContent {
        let coords = viewModel.allRouteCoordinates
        if coords.count >= 2 {
            MapPolyline(coordinates: coords)
                .stroke(Theme.Colors.primary, lineWidth: 4)
        }
    }

    @MapContentBuilder
    private var waypointAnnotations: some MapContent {
        ForEach(Array(viewModel.waypoints.enumerated()), id: \.offset) { index, coord in
            Annotation("", coordinate: coord) {
                WaypointAnnotationView(
                    index: index,
                    totalCount: viewModel.waypoints.count
                )
            }
        }
    }

    @MapContentBuilder
    private var checkpointAnnotations: some MapContent {
        ForEach(viewModel.checkpoints) { checkpoint in
            if let lat = checkpoint.latitude, let lon = checkpoint.longitude {
                Annotation(checkpoint.name, coordinate: CLLocationCoordinate2D(
                    latitude: lat, longitude: lon
                )) {
                    CheckpointAnnotationView(
                        name: checkpoint.name,
                        distanceKm: checkpoint.distanceFromStartKm,
                        hasAidStation: checkpoint.hasAidStation
                    )
                }
            }
        }
    }

    // MARK: - Overlays

    private var overlayControls: some View {
        VStack {
            Spacer()
            statsBar
        }
    }

    private var statsBar: some View {
        HStack(spacing: Theme.Spacing.lg) {
            Label(String(format: "%.1f km", viewModel.totalDistanceKm), systemImage: "arrow.left.arrow.right")
            Label("\(viewModel.waypoints.count) pts", systemImage: "mappin")
            Label("\(viewModel.checkpoints.count) CP", systemImage: "flag")
            Spacer()
            MapStyleToggleButton(style: $mapStylePreference)
        }
        .font(.caption)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(.ultraThinMaterial)
    }

    private var resolvingOverlay: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            ProgressView("Resolving path...")
                .padding(Theme.Spacing.lg)
                .background(.ultraThickMaterial)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItemGroup(placement: .primaryAction) {
            modeToggle
            Button {
                viewModel.undoLastWaypoint()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(viewModel.waypoints.isEmpty)

            Button {
                viewModel.clearAll()
            } label: {
                Image(systemName: "trash")
            }
            .disabled(viewModel.waypoints.isEmpty)

            Button {
                showSaveAlert = true
            } label: {
                Image(systemName: "square.and.arrow.down")
            }
            .disabled(!viewModel.canSave)
        }
    }

    private var modeToggle: some View {
        Menu {
            Button {
                viewModel.drawingMode = .waypoints
            } label: {
                Label("Waypoints", systemImage: "pencil.and.outline")
            }
            Button {
                viewModel.drawingMode = .checkpoints
            } label: {
                Label("Checkpoints", systemImage: "flag")
            }
        } label: {
            Image(systemName: viewModel.drawingMode == .waypoints
                ? "pencil.and.outline" : "flag")
        }
    }

    // MARK: - Actions

    private func handleTap(_ coordinate: CLLocationCoordinate2D) {
        switch viewModel.drawingMode {
        case .waypoints:
            viewModel.addWaypoint(coordinate)
        case .checkpoints:
            viewModel.placeCheckpoint(at: coordinate)
        }
    }

    private func performSave() {
        Task {
            do {
                try await viewModel.saveRoute(routeRepository: routeRepository)
                dismiss()
            } catch {
                saveError = error.localizedDescription
            }
        }
    }
}
