@preconcurrency import MapKit
import SwiftUI
import os

struct RaceLocationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var coordinator = LocationSearchCoordinator()

    let onSelect: (Double, Double, String) -> Void

    var body: some View {
        NavigationStack {
            List {
                searchField

                if coordinator.isSearching {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if coordinator.searchText.isEmpty {
                    Text("Type a city or venue name to search")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else if coordinator.completions.isEmpty {
                    ContentUnavailableView.search(text: coordinator.searchText)
                        .listRowBackground(Color.clear)
                } else {
                    completionRows
                }
            }
            .listStyle(.plain)
            .navigationTitle("Race Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Search Error", isPresented: .init(
                get: { coordinator.error != nil },
                set: { if !$0 { coordinator.error = nil } }
            )) {
                Button("OK") { coordinator.error = nil }
            } message: {
                Text(coordinator.error ?? "")
            }
        }
    }

    // MARK: - Subviews

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.Colors.secondaryLabel)
                .accessibilityHidden(true)
            TextField("Search city or venue...", text: $coordinator.searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .accessibilityLabel("Location search")
        }
    }

    @ViewBuilder
    private var completionRows: some View {
        ForEach(coordinator.completions, id: \.self) { completion in
            Button {
                selectCompletion(completion)
            } label: {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(completion.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.Colors.label)
                    if !completion.subtitle.isEmpty {
                        Text(completion.subtitle)
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.secondaryLabel)
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
        }
    }

    // MARK: - Actions

    private func selectCompletion(_ completion: MKLocalSearchCompletion) {
        Task {
            do {
                let (lat, lon, name) = try await coordinator.resolveCoordinate(for: completion)
                onSelect(lat, lon, name)
                dismiss()
            } catch {
                coordinator.error = "Could not get coordinates. Please try another result."
            }
        }
    }
}

// MARK: - Search Coordinator

@Observable
@MainActor
private final class LocationSearchCoordinator: NSObject, MKLocalSearchCompleterDelegate {

    var searchText: String = "" {
        didSet { completer.queryFragment = searchText }
    }
    var completions: [MKLocalSearchCompletion] = []
    var isSearching = false
    var error: String?

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor [results] in
            self.completions = results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        let message = error.localizedDescription
        Task { @MainActor in
            self.error = message
            Logger.app.error("Location search failed: \(message)")
        }
    }

    func resolveCoordinate(
        for completion: MKLocalSearchCompletion
    ) async throws -> (Double, Double, String) {
        isSearching = true
        defer { isSearching = false }

        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        let response = try await search.start()

        guard let item = response.mapItems.first,
              let location = item.placemark.location else {
            throw DomainError.validationFailed(field: "location", reason: "No coordinates found for selected location")
        }

        guard InputValidator.isValidCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        ) else {
            throw DomainError.validationFailed(field: "location", reason: "Invalid coordinates for selected location")
        }

        let name = item.name ?? completion.title
        return (location.coordinate.latitude, location.coordinate.longitude, name)
    }
}
