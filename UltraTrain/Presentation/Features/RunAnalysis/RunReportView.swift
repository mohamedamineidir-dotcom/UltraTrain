import SwiftUI

struct RunReportView: View {
    @Environment(\.unitPreference) private var units

    let run: CompletedRun
    let metrics: AdvancedRunMetrics?
    let comparison: HistoricalComparison?
    let nutritionAnalysis: NutritionAnalysis?

    var body: some View {
        VStack(spacing: 16) {
            headerSection
            Divider()
            statsSection
            if let metrics {
                Divider()
                advancedMetricsSection(metrics)
            }
            if !run.splits.isEmpty {
                Divider()
                splitsSection
            }
            if let analysis = nutritionAnalysis {
                Divider()
                nutritionSection(analysis)
            }
            if let comparison, !comparison.badges.isEmpty {
                Divider()
                badgesSection(comparison)
            }
            Spacer()
            footerSection
        }
        .padding(24)
        .frame(width: 612, height: 792)
        .background(Color.white)
        .foregroundStyle(.black)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("UltraTrain Run Report")
                .font(.title2.bold())
            Text(run.date.formatted(date: .long, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 24) {
            reportStat("Distance", UnitFormatter.formatDistance(run.distanceKm, unit: units, decimals: 2))
            reportStat("Duration", RunStatisticsCalculator.formatDuration(run.duration))
            reportStat("Avg Pace", RunStatisticsCalculator.formatPace(run.averagePaceSecondsPerKm, unit: units) + " " + UnitFormatter.paceLabel(units))
            reportStat("Elevation", "+\(UnitFormatter.formatElevation(run.elevationGainM, unit: units)) / -\(UnitFormatter.formatElevation(run.elevationLossM, unit: units))")
            if let hr = run.averageHeartRate {
                reportStat("Avg HR", "\(hr) bpm")
            }
        }
    }

    private func reportStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Advanced Metrics

    private func advancedMetricsSection(_ metrics: AdvancedRunMetrics) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Advanced Metrics")
                .font(.headline)
            HStack(spacing: 24) {
                reportStat("Pace Variability", String(format: "%.1f%%", metrics.paceVariabilityIndex * 100))
                reportStat("GAP", RunStatisticsCalculator.formatPace(metrics.averageGradientAdjustedPace, unit: units) + " " + UnitFormatter.paceLabel(units))
                reportStat("Calories", String(format: "%.0f kcal", metrics.estimatedCalories))
                reportStat("Training Effect", String(format: "%.1f / 5", metrics.trainingEffectScore))
                if let eff = metrics.climbingEfficiency {
                    reportStat("Climb Eff.", String(format: "%.0f%%", eff * 100))
                }
            }
        }
    }

    // MARK: - Splits

    private var splitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Splits")
                .font(.headline)
            let displaySplits = Array(run.splits.prefix(20))
            ForEach(displaySplits) { split in
                HStack {
                    Text("\(UnitFormatter.distanceLabel(units).uppercased()) \(split.kilometerNumber)")
                        .font(.caption.bold())
                        .frame(width: 50, alignment: .leading)
                    Text(RunStatisticsCalculator.formatPace(split.duration, unit: units))
                        .font(.caption.monospacedDigit())
                    if split.elevationChangeM != 0 {
                        Text(String(format: "%+.0f %@", UnitFormatter.elevationValue(split.elevationChangeM, unit: units), UnitFormatter.elevationShortLabel(units)))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if let hr = split.averageHeartRate {
                        Text("\(hr) bpm")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            if run.splits.count > 20 {
                Text("... and \(run.splits.count - 20) more splits")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Nutrition

    private func nutritionSection(_ analysis: NutritionAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nutrition")
                .font(.headline)
            HStack(spacing: 24) {
                reportStat("Adherence", String(format: "%.0f%%", analysis.adherencePercent))
                reportStat("Calories", String(format: "%.0f kcal", analysis.totalCaloriesConsumed))
                reportStat("Intakes", "\(analysis.timelineEvents.count)")
            }
        }
    }

    // MARK: - Badges

    private func badgesSection(_ comparison: HistoricalComparison) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Achievements")
                .font(.headline)
            ForEach(comparison.badges) { badge in
                HStack(spacing: 8) {
                    Image(systemName: badge.icon)
                        .font(.caption)
                    Text(badge.title)
                        .font(.caption.bold())
                    Text(badge.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        Text("Generated by UltraTrain")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
}
