import SwiftUI

struct RaceDetailCard: View {
    let race: Race
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            header
            stats
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
            statItem("Distance", value: String(format: "%.0f km", race.distanceKm))
            statItem("D+", value: String(format: "%.0f m", race.elevationGainM))
            statItem("D-", value: String(format: "%.0f m", race.elevationLossM))
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
