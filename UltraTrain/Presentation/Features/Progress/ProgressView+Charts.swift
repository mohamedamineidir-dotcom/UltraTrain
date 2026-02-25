import SwiftUI

// MARK: - Chart & Stat Sections

extension TrainingProgressView {

    // MARK: - Fitness Section

    var fitnessSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if viewModel.fitnessSnapshots.count >= 2 {
                FitnessTrendChartView(snapshots: viewModel.fitnessSnapshots)

                if viewModel.formStatus != .noData {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: viewModel.formIcon)
                            .foregroundStyle(viewModel.formColor)
                            .accessibilityHidden(true)
                        Text("Form: \(viewModel.formLabel)")
                            .font(.subheadline)
                        Spacer()
                        if let snapshot = viewModel.currentFitnessSnapshot {
                            Text(String(format: "%+.0f TSB", snapshot.form))
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(viewModel.formColor)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Current form: \(viewModel.formLabel)\(viewModel.currentFitnessSnapshot.map { String(format: ". Training stress balance: %+.0f", $0.form) } ?? "")")
                }
            } else {
                Text("Complete some runs to see your fitness trend")
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
        }
        .cardStyle()
    }

    // MARK: - Race Readiness

    @ViewBuilder
    var raceReadinessSection: some View {
        if let forecast = viewModel.raceReadiness {
            RaceReadinessCard(forecast: forecast)
                .cardStyle()
        }
    }

    // MARK: - Volume Chart

    var volumeChartSection: some View {
        WeeklyDistanceChartView(weeklyVolumes: viewModel.weeklyVolumes)
            .cardStyle()
    }

    // MARK: - Elevation Chart

    var elevationChartSection: some View {
        WeeklyElevationChartView(weeklyVolumes: viewModel.weeklyVolumes)
            .cardStyle()
    }

    // MARK: - Duration Chart

    @ViewBuilder
    var durationChartSection: some View {
        if viewModel.weeklyVolumes.contains(where: { $0.duration > 0 }) {
            WeeklyDurationChartView(weeklyVolumes: viewModel.weeklyVolumes)
                .cardStyle()
        }
    }

    // MARK: - Cumulative Volume

    @ViewBuilder
    var cumulativeVolumeSection: some View {
        if viewModel.weeklyVolumes.contains(where: { $0.distanceKm > 0 }) {
            CumulativeVolumeChartView(weeklyVolumes: viewModel.weeklyVolumes)
                .cardStyle()
        }
    }

    // MARK: - Monthly Volume

    @ViewBuilder
    var monthlyVolumeSection: some View {
        if viewModel.monthlyVolumes.count >= 2 {
            MonthlyVolumeComparisonChart(monthlyVolumes: viewModel.monthlyVolumes)
                .cardStyle()
        }
    }

    // MARK: - Session Type Breakdown

    @ViewBuilder
    var sessionTypeSection: some View {
        if !viewModel.sessionTypeStats.isEmpty {
            SessionTypeBreakdownChart(stats: viewModel.sessionTypeStats)
                .cardStyle()
        }
    }

    // MARK: - Adherence

    var adherenceSection: some View {
        ProgressAdherenceSection(
            adherencePercent: viewModel.adherencePercent,
            completed: viewModel.planAdherence.completed,
            total: viewModel.planAdherence.total,
            weeklyAdherence: viewModel.weeklyAdherence
        )
    }

    // MARK: - Training Calendar

    @ViewBuilder
    var trainingCalendarSection: some View {
        if !viewModel.calendarHeatmapDays.isEmpty {
            TrainingCalendarHeatmapView(dayIntensities: viewModel.calendarHeatmapDays)
                .cardStyle()
        }
    }

    // MARK: - Summary

    var summarySection: some View {
        ProgressSummarySection(
            totalDistanceKm: viewModel.totalDistanceKm,
            totalElevationGainM: viewModel.totalElevationGainM,
            totalRuns: viewModel.totalRuns,
            averageWeeklyKm: viewModel.averageWeeklyKm
        )
    }

    // MARK: - Pace Trend

    @ViewBuilder
    var paceTrendSection: some View {
        if viewModel.runTrendPoints.count >= 3 {
            PaceTrendChartView(trendPoints: viewModel.runTrendPoints)
                .cardStyle()
        }
    }

    // MARK: - Heart Rate Trend

    @ViewBuilder
    var heartRateTrendSection: some View {
        let pointsWithHR = viewModel.runTrendPoints.filter { $0.averageHeartRate != nil }
        if pointsWithHR.count >= 3 {
            HeartRateTrendChartView(trendPoints: viewModel.runTrendPoints)
                .cardStyle()
        }
    }

    // MARK: - Personal Records

    @ViewBuilder
    var personalRecordsSection: some View {
        if !viewModel.personalRecords.isEmpty {
            PersonalRecordsSection(records: viewModel.personalRecords)
                .cardStyle()
        }
    }
}
