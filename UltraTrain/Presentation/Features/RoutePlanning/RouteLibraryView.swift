import SwiftUI

struct RouteLibraryView: View {
    @Environment(\.unitPreference) private var units
    @Bindable var viewModel: RouteLibraryViewModel
    @State private var showGPXImporter = false
    @State private var showRunPicker = false
    @State private var showRouteDrawing = false
    @State private var showTrailSearch = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading routes...")
                } else if viewModel.filteredRoutes.isEmpty {
                    emptyState
                } else {
                    routeList
                }
            }
            .navigationTitle("My Routes")
            .searchable(text: $viewModel.searchText, prompt: "Search routes")
            .toolbar { toolbarContent }
            .task { await viewModel.load() }
            .fileImporter(
                isPresented: $showGPXImporter,
                allowedContentTypes: [.xml],
                allowsMultipleSelection: false
            ) { result in
                handleGPXImport(result)
            }
            .sheet(isPresented: $showRunPicker) {
                RunToRoutePickerSheet(
                    runs: viewModel.recentRunsWithGPS,
                    onSelect: { run in
                        showRunPicker = false
                        Task { await viewModel.createFromRun(run) }
                    }
                )
            }
            .sheet(isPresented: $showRouteDrawing) {
                Task { await viewModel.load() }
            } content: {
                RouteDrawingView(routeRepository: viewModel.routeRepository)
            }
            .sheet(isPresented: $showTrailSearch) {
                OSMTrailSearchView(
                    routeRepository: viewModel.routeRepository,
                    onImported: {
                        Task { await viewModel.load() }
                    }
                )
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }

    // MARK: - Route List

    private var routeList: some View {
        List {
            ForEach(viewModel.filteredRoutes) { route in
                NavigationLink {
                    RouteDetailView(route: route)
                } label: {
                    routeRow(route)
                }
            }
            .onDelete { indexSet in
                let routes = viewModel.filteredRoutes
                for index in indexSet {
                    Task { await viewModel.deleteRoute(id: routes[index].id) }
                }
            }
        }
    }

    private func routeRow(_ route: SavedRoute) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Image(systemName: sourceIcon(route.source))
                    .foregroundStyle(Theme.Colors.primary)
                Text(route.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
            }
            HStack(spacing: Theme.Spacing.md) {
                Label(
                    UnitFormatter.formatDistance(route.distanceKm, unit: units, decimals: 1),
                    systemImage: "arrow.left.arrow.right"
                )
                Label(
                    "+" + UnitFormatter.formatElevation(route.elevationGainM, unit: units),
                    systemImage: "arrow.up.right"
                )
                Spacer()
                Text(route.createdAt, style: .date)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .font(.caption)
            .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Routes", systemImage: "map")
        } description: {
            Text("Import a GPX file or save a route from a completed run.")
        } actions: {
            Button("Import GPX") { showGPXImporter = true }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    showGPXImporter = true
                } label: {
                    Label("Import GPX", systemImage: "doc.badge.plus")
                }
                Button {
                    showRunPicker = true
                } label: {
                    Label("Save from Run", systemImage: "figure.run")
                }
                Button {
                    showRouteDrawing = true
                } label: {
                    Label("Draw Route", systemImage: "pencil.and.outline")
                }
                Button {
                    showTrailSearch = true
                } label: {
                    Label("Search Trails", systemImage: "magnifyingglass")
                }
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    // MARK: - Helpers

    private func sourceIcon(_ source: RouteSource) -> String {
        switch source {
        case .gpxImport: return "doc"
        case .completedRun: return "figure.run"
        case .manual: return "hand.draw"
        }
    }

    private func handleGPXImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            guard let data = try? Data(contentsOf: url) else {
                viewModel.error = "Could not read the selected file."
                return
            }
            Task { await viewModel.importGPX(data: data) }
        case .failure(let error):
            viewModel.error = error.localizedDescription
        }
    }
}

// MARK: - Run-to-Route Picker

struct RunToRoutePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.unitPreference) private var units
    let runs: [CompletedRun]
    let onSelect: (CompletedRun) -> Void

    var body: some View {
        NavigationStack {
            List(runs) { run in
                Button {
                    onSelect(run)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(run.date, style: .date)
                            .font(.subheadline.bold())
                        HStack(spacing: Theme.Spacing.md) {
                            Text(UnitFormatter.formatDistance(run.distanceKm, unit: units, decimals: 1))
                            Text("+" + UnitFormatter.formatElevation(run.elevationGainM, unit: units))
                        }
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
            }
            .navigationTitle("Select a Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
