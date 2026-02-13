import SwiftUI

struct SessionDetailView: View {
    let session: TrainingSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                headerSection
                statsSection
                descriptionSection

                if let notes = session.nutritionNotes {
                    nutritionSection(notes)
                }
            }
            .padding()
        }
        .navigationTitle(session.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        HStack {
            Image(systemName: session.type.icon)
                .font(.largeTitle)
                .foregroundStyle(session.intensity.color)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(session.type.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(session.date.formatted(.dateTime.weekday(.wide).month().day()))
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }

            Spacer()

            Text(session.intensity.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(session.intensity.color)
                .clipShape(Capsule())
        }
    }

    private var statsSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            if session.plannedDistanceKm > 0 {
                StatCard(
                    title: "Distance",
                    value: String(format: "%.1f", session.plannedDistanceKm),
                    unit: "km"
                )
            }
            if session.plannedElevationGainM > 0 {
                StatCard(
                    title: "Elevation",
                    value: String(format: "%.0f", session.plannedElevationGainM),
                    unit: "m D+"
                )
            }
            if session.plannedDuration > 0 {
                StatCard(
                    title: "Duration",
                    value: session.plannedDuration.formattedDuration,
                    unit: ""
                )
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Description")
                .font(.headline)
            Text(session.description)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func nutritionSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("Nutrition", systemImage: "fork.knife")
                .font(.headline)
            Text(notes)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
