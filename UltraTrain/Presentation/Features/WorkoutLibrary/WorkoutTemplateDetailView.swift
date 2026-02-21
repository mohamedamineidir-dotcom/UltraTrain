import SwiftUI

struct WorkoutTemplateDetailView: View {
    let template: WorkoutTemplate
    let onAddToPlan: (WorkoutTemplate) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerSection
                descriptionSection
                statsGrid
                addButton
            }
            .padding(Theme.Spacing.md)
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: template.category.iconName)
                .font(.largeTitle)
                .foregroundStyle(template.intensity.color)

            Text(template.category.displayName)
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
    }

    // MARK: - Description

    private var descriptionSection: some View {
        Text(template.descriptionText)
            .font(.body)
            .foregroundStyle(Theme.Colors.label)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: Theme.Spacing.md) {
            statCell(
                title: "Distance",
                value: String(format: "%.1f km", template.targetDistanceKm),
                icon: "ruler"
            )
            statCell(
                title: "Elevation",
                value: String(format: "%.0f m", template.targetElevationGainM),
                icon: "arrow.up.right"
            )
            statCell(
                title: "Duration",
                value: RunStatisticsCalculator.formatDuration(template.estimatedDuration),
                icon: "clock"
            )
            statCell(
                title: "Intensity",
                value: template.intensity.displayName,
                icon: "flame.fill"
            )
            statCell(
                title: "Session Type",
                value: template.sessionType.displayName,
                icon: template.sessionType.icon
            )
            statCell(
                title: "Category",
                value: template.category.displayName,
                icon: template.category.iconName
            )
        }
    }

    private func statCell(title: String, value: String, icon: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.Colors.primary)
            Text(value)
                .font(.subheadline.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .cardStyle()
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            onAddToPlan(template)
        } label: {
            Label("Add to Plan", systemImage: "plus.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.top, Theme.Spacing.sm)
    }
}
