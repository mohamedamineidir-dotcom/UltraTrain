import SwiftUI
import Charts

struct FitnessTrendView: View {
    @Environment(\.unitPreference) private var units
    let snapshots: [FitnessSnapshot]
    let currentSnapshot: FitnessSnapshot?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                if snapshots.count >= 2 {
                    chartSection
                }
                formStatusBanner
                currentStatsSection
                weeklyVolumeSection
            }
            .padding()
        }
        .navigationTitle("Fitness Trend")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Chart

    private var chartSection: some View {
        FitnessTrendChartView(snapshots: snapshots)
            .cardStyle()
    }

    // MARK: - Form Status Banner

    @ViewBuilder
    private var formStatusBanner: some View {
        if let snapshot = currentSnapshot {
            let status = formStatus(for: snapshot.form)
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: status.icon)
                    .foregroundStyle(status.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(status.label)
                        .font(.subheadline.bold())
                    Text(status.explanation)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }

                Spacer()

                Text(String(format: "%+.0f", snapshot.form))
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(status.color)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(status.color.opacity(0.1))
            )
        }
    }

    // MARK: - Current Stats

    private var currentStatsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Current")
                .font(.headline)

            if let snapshot = currentSnapshot {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: Theme.Spacing.md
                ) {
                    StatCard(title: "Fitness", value: String(format: "%.0f", snapshot.fitness), unit: "CTL")
                    StatCard(title: "Fatigue", value: String(format: "%.0f", snapshot.fatigue), unit: "ATL")
                    StatCard(title: "Form", value: String(format: "%.0f", snapshot.form), unit: "TSB")
                }

                acrRow(snapshot: snapshot)
            } else {
                Text("No fitness data available")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
    }

    private func acrRow(snapshot: FitnessSnapshot) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: acrIcon(for: snapshot.acuteToChronicRatio))
                .foregroundStyle(acrColor(for: snapshot.acuteToChronicRatio))
            Text("Acute:Chronic Ratio: \(snapshot.acuteToChronicRatio, specifier: "%.2f")")
                .font(.subheadline)
            Spacer()
            Text(acrLabel(for: snapshot.acuteToChronicRatio))
                .font(.caption.bold())
                .foregroundStyle(acrColor(for: snapshot.acuteToChronicRatio))
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(acrColor(for: snapshot.acuteToChronicRatio).opacity(0.1))
        )
    }

    // MARK: - Weekly Volume

    private var weeklyVolumeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("This Week")
                .font(.headline)

            if let snapshot = currentSnapshot {
                HStack(spacing: Theme.Spacing.md) {
                    StatCard(
                        title: "Volume",
                        value: String(format: "%.1f", UnitFormatter.distanceValue(snapshot.weeklyVolumeKm, unit: units)),
                        unit: UnitFormatter.distanceLabel(units)
                    )
                    StatCard(
                        title: "Elevation",
                        value: String(format: "%.0f", UnitFormatter.elevationValue(snapshot.weeklyElevationGainM, unit: units)),
                        unit: UnitFormatter.elevationLabel(units)
                    )
                    StatCard(
                        title: "Duration",
                        value: RunStatisticsCalculator.formatDuration(snapshot.weeklyDuration),
                        unit: ""
                    )
                }
            }
        }
    }

    // MARK: - Form Status Helpers

    private func formStatus(for tsb: Double) -> (label: String, icon: String, color: Color, explanation: String) {
        if tsb > 15 {
            return (
                "Race Ready",
                "checkmark.seal.fill",
                Theme.Colors.success,
                "Fitness is high and fatigue is low. Great time for a race or hard effort."
            )
        } else if tsb > 0 {
            return (
                "Fresh",
                "arrow.up.circle.fill",
                Theme.Colors.success,
                "You're recovering well. Good form for quality sessions."
            )
        } else if tsb > -15 {
            return (
                "Building",
                "minus.circle.fill",
                Theme.Colors.warning,
                "Normal training fatigue. Stay consistent."
            )
        } else {
            return (
                "Fatigued",
                "arrow.down.circle.fill",
                Theme.Colors.danger,
                "Heavy fatigue accumulation. Consider extra recovery."
            )
        }
    }

    // MARK: - ACR Helpers

    private func acrIcon(for acr: Double) -> String {
        if acr > 1.5 { return "exclamationmark.triangle.fill" }
        if acr < 0.8 { return "arrow.down.circle.fill" }
        return "checkmark.circle.fill"
    }

    private func acrColor(for acr: Double) -> Color {
        if acr > 1.5 { return Theme.Colors.danger }
        if acr < 0.8 { return Theme.Colors.warning }
        return Theme.Colors.success
    }

    private func acrLabel(for acr: Double) -> String {
        if acr > 1.5 { return "Injury Risk" }
        if acr < 0.8 { return "Detraining" }
        return "Optimal"
    }
}
