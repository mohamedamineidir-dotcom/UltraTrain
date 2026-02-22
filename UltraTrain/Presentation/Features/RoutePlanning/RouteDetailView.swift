import SwiftUI
import MapKit

struct RouteDetailView: View {
    @Environment(\.unitPreference) private var units
    let route: SavedRoute
    @State private var show3DPreview = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                mapSection
                statsSection
                elevationSection
                checkpointsSection
                if let notes = route.notes, !notes.isEmpty {
                    notesSection(notes)
                }
            }
            .padding(.vertical, Theme.Spacing.md)
        }
        .navigationTitle(route.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $show3DPreview) {
            RaceCourse3DPreviewView(courseRoute: route.courseRoute)
        }
    }

    // MARK: - Map

    private var mapSection: some View {
        Group {
            if route.hasCourseRoute {
                RaceCourseMapView(
                    courseRoute: route.courseRoute,
                    checkpoints: route.checkpoints
                )
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Details")
                .font(.headline)

            HStack(spacing: Theme.Spacing.lg) {
                statItem(
                    label: "Distance",
                    value: UnitFormatter.formatDistance(route.distanceKm, unit: units, decimals: 1),
                    icon: "arrow.left.arrow.right"
                )
                statItem(
                    label: "D+",
                    value: "+" + UnitFormatter.formatElevation(route.elevationGainM, unit: units),
                    icon: "arrow.up.right"
                )
                statItem(
                    label: "D-",
                    value: "-" + UnitFormatter.formatElevation(route.elevationLossM, unit: units),
                    icon: "arrow.down.right"
                )
            }

            HStack(spacing: Theme.Spacing.lg) {
                statItem(
                    label: "Source",
                    value: route.source.displayName,
                    icon: sourceIcon
                )
                statItem(
                    label: "Created",
                    value: route.createdAt.formatted(.dateTime.month().day().year()),
                    icon: "calendar"
                )
            }

            if route.hasCourseRoute {
                Button {
                    show3DPreview = true
                } label: {
                    Label("3D Preview", systemImage: "view.3d")
                }
                .buttonStyle(.bordered)
                .padding(.top, Theme.Spacing.xs)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func statItem(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
            Text(value)
                .font(.subheadline.bold())
        }
    }

    private var sourceIcon: String {
        switch route.source {
        case .gpxImport: return "doc"
        case .completedRun: return "figure.run"
        case .manual: return "hand.draw"
        }
    }

    // MARK: - Elevation

    private var elevationSection: some View {
        Group {
            if route.hasCourseRoute {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Elevation Profile")
                        .font(.headline)
                    CourseRouteElevationChart(courseRoute: route.courseRoute)
                        .frame(height: 180)
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }

    // MARK: - Checkpoints

    private var checkpointsSection: some View {
        Group {
            if !route.checkpoints.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Checkpoints (\(route.checkpoints.count))")
                        .font(.headline)
                    ForEach(route.checkpoints) { checkpoint in
                        HStack {
                            Image(systemName: checkpoint.hasAidStation ? "cross.circle.fill" : "mappin.circle.fill")
                                .foregroundStyle(checkpoint.hasAidStation ? .red : Theme.Colors.primary)
                            Text(checkpoint.name)
                                .font(.subheadline)
                            Spacer()
                            Text(UnitFormatter.formatDistance(checkpoint.distanceFromStartKm, unit: units, decimals: 1))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Theme.Colors.secondaryLabel)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }

    // MARK: - Notes

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Notes")
                .font(.headline)
            Text(notes)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
}

// MARK: - Route Source Extension

private extension RouteSource {
    var displayName: String {
        switch self {
        case .gpxImport: return "GPX Import"
        case .completedRun: return "From Run"
        case .manual: return "Manual"
        }
    }
}
