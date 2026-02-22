import SwiftUI

struct RaceRoutePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.unitPreference) private var units
    let routes: [SavedRoute]
    let onSelect: (SavedRoute) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if routes.isEmpty {
                    ContentUnavailableView {
                        Label("No Routes", systemImage: "map")
                    } description: {
                        Text("Import a GPX file in the Route Library first.")
                    }
                } else {
                    List(routes) { route in
                        Button {
                            onSelect(route)
                            dismiss()
                        } label: {
                            routeRow(route)
                        }
                    }
                }
            }
            .navigationTitle("Pick a Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
                if !route.checkpoints.isEmpty {
                    Label(
                        "\(route.checkpoints.count) cp",
                        systemImage: "mappin"
                    )
                }
            }
            .font(.caption)
            .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private func sourceIcon(_ source: RouteSource) -> String {
        switch source {
        case .gpxImport: return "doc"
        case .completedRun: return "figure.run"
        case .manual: return "hand.draw"
        }
    }
}
