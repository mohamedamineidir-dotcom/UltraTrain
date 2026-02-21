import SwiftUI

struct RaceDetailCard: View {
    @Environment(\.unitPreference) private var units
    let race: Race
    let onEdit: () -> Void
    let onDelete: () -> Void
    var onViewCourse: (() -> Void)?

    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            header
            stats
            if race.hasCourseRoute {
                courseMapThumbnail
            }
            actions
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .alert("Delete Race", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(race.name)?")
        }
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "flag.checkered")
                .foregroundStyle(race.priority.badgeColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(race.name)
                    .font(.headline)
                Text(race.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            Text(race.priority.displayName)
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(race.priority.badgeColor.opacity(0.2))
                .foregroundStyle(race.priority.badgeColor)
                .clipShape(Capsule())
        }
    }

    private var stats: some View {
        HStack(spacing: Theme.Spacing.lg) {
            statItem("Distance", value: UnitFormatter.formatDistance(race.distanceKm, unit: units, decimals: 0))
            statItem("D+", value: UnitFormatter.formatElevation(race.elevationGainM, unit: units))
            statItem("D-", value: UnitFormatter.formatElevation(race.elevationLossM, unit: units))
            statItem("Terrain", value: race.terrainDifficulty.rawValue.capitalized)
        }
    }

    private func statItem(_ label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    private var courseMapThumbnail: some View {
        ZStack(alignment: .bottomTrailing) {
            RaceCourseMapView(
                courseRoute: race.courseRoute,
                checkpoints: race.checkpoints,
                height: 120
            )
            .allowsHitTesting(false)

            if let onViewCourse {
                Button {
                    onViewCourse()
                } label: {
                    Label("View Course", systemImage: "map")
                        .font(.caption.bold())
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding(Theme.Spacing.sm)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button { onEdit() } label: {
                Label("Edit", systemImage: "pencil")
                    .font(.caption.bold())
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button { showDeleteConfirmation = true } label: {
                Label("Delete", systemImage: "trash")
                    .font(.caption.bold())
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(.red)
        }
    }
}
