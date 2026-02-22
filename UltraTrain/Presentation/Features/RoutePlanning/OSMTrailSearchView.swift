import SwiftUI
import CoreLocation
import os

struct OSMTrailSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = OSMTrailSearchViewModel()
    @State private var importError: String?
    @State private var locationManager = CLLocationManager()

    let routeRepository: any RouteRepository
    var onImported: (() -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                content
            }
            .navigationTitle("Search Trails")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Import Error", isPresented: .constant(importError != nil)) {
                Button("OK") { importError = nil }
            } message: {
                Text(importError ?? "")
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                TextField("Trail name...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .onSubmit { performSearch() }
            }
            .padding(Theme.Spacing.sm)
            .background(Theme.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))

            Button {
                searchNearby()
            } label: {
                Image(systemName: "location")
                    .frame(width: 36, height: 36)
                    .background(Theme.Colors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
            }
            .accessibilityLabel("Search nearby trails")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView("Searching trails...")
            Spacer()
        } else if let error = viewModel.error {
            Spacer()
            ContentUnavailableView {
                Label("Search Failed", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error)
            } actions: {
                Button("Retry") { performSearch() }
                    .buttonStyle(.borderedProminent)
            }
            Spacer()
        } else if viewModel.results.isEmpty && !viewModel.searchText.isEmpty {
            Spacer()
            ContentUnavailableView.search(text: viewModel.searchText)
            Spacer()
        } else {
            resultsList
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        List(viewModel.results) { trail in
            trailRow(trail)
        }
        .listStyle(.plain)
    }

    private func trailRow(_ trail: OSMTrailResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(trail.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: Theme.Spacing.md) {
                    Label(
                        String(format: "%.1f km", trail.distanceKm),
                        systemImage: "arrow.left.arrow.right"
                    )
                    if let surface = trail.tags["surface"] {
                        Label(surface, systemImage: "square.grid.3x3.topleft.filled")
                    }
                }
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            Spacer()
            Button("Import") {
                importTrail(trail)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    // MARK: - Actions

    private func performSearch() {
        Task { await viewModel.search() }
    }

    private func searchNearby() {
        locationManager.requestWhenInUseAuthorization()
        if let location = locationManager.location {
            Task {
                await viewModel.searchNearby(coordinate: location.coordinate)
            }
        } else {
            viewModel.error = "Unable to determine your location. Please enable Location Services."
        }
    }

    private func importTrail(_ trail: OSMTrailResult) {
        Task {
            do {
                try await viewModel.importTrail(trail, routeRepository: routeRepository)
                onImported?()
                dismiss()
            } catch {
                importError = error.localizedDescription
            }
        }
    }
}
