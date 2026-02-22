import SwiftUI

struct RoutePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.unitPreference) private var units
    let routes: [SavedRoute]
    let onSelect: (SavedRoute) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if routes.isEmpty {
                    ContentUnavailableView(
                        "No Routes",
                        systemImage: "map",
                        description: Text("Save a route first from the Routes library.")
                    )
                } else {
                    routeList
                }
            }
            .navigationTitle("Select a Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var routeList: some View {
        List(routes) { route in
            Button {
                onSelect(route)
                dismiss()
            } label: {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(route.name)
                        .font(.subheadline.bold())
                    HStack(spacing: Theme.Spacing.md) {
                        Label(
                            UnitFormatter.formatDistance(route.distanceKm, unit: units, decimals: 1),
                            systemImage: "arrow.left.arrow.right"
                        )
                        Label(
                            "+" + UnitFormatter.formatElevation(route.elevationGainM, unit: units),
                            systemImage: "arrow.up.right"
                        )
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            }
        }
    }
}
