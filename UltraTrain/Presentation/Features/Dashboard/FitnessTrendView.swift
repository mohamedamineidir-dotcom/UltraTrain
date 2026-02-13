import SwiftUI
import Charts

struct FitnessTrendView: View {
    let snapshots: [FitnessSnapshot]
    let currentSnapshot: FitnessSnapshot?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                if snapshots.count >= 2 {
                    chartSection
                }
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
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("28-Day Trend")
                .font(.headline)

            Chart {
                ForEach(snapshots) { snapshot in
                    LineMark(
                        x: .value("Date", snapshot.date),
                        y: .value("Load", snapshot.fitness),
                        series: .value("Metric", "Fitness")
                    )
                    .foregroundStyle(.blue)

                    LineMark(
                        x: .value("Date", snapshot.date),
                        y: .value("Load", snapshot.fatigue),
                        series: .value("Metric", "Fatigue")
                    )
                    .foregroundStyle(.red)

                    LineMark(
                        x: .value("Date", snapshot.date),
                        y: .value("Load", snapshot.form),
                        series: .value("Metric", "Form")
                    )
                    .foregroundStyle(.green)
                }
            }
            .chartForegroundStyleScale([
                "Fitness": .blue,
                "Fatigue": .red,
                "Form": .green
            ])
            .chartYAxisLabel("Load")
            .frame(height: 250)

            legendRow
        }
        .cardStyle()
    }

    private var legendRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            legendDot(color: .blue, label: "CTL (Fitness)")
            legendDot(color: .red, label: "ATL (Fatigue)")
            legendDot(color: .green, label: "TSB (Form)")
        }
        .font(.caption)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(Theme.Colors.secondaryLabel)
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
                        value: String(format: "%.1f", snapshot.weeklyVolumeKm),
                        unit: "km"
                    )
                    StatCard(
                        title: "Elevation",
                        value: String(format: "%.0f", snapshot.weeklyElevationGainM),
                        unit: "m D+"
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
