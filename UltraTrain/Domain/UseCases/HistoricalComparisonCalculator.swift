import Foundation

enum HistoricalComparisonCalculator {

    static func compare(
        run: CompletedRun,
        recentRuns: [CompletedRun],
        unit: UnitPreference = .metric
    ) -> HistoricalComparison {
        let splitPRs = findSplitPRs(run: run, recentRuns: recentRuns)
        let trend = calculatePaceTrend(run: run, recentRuns: recentRuns)
        let badges = calculateBadges(run: run, recentRuns: recentRuns, unit: unit)

        return HistoricalComparison(
            splitPRs: splitPRs,
            paceTrend: trend,
            badges: badges
        )
    }

    // MARK: - Split PRs

    static func findSplitPRs(
        run: CompletedRun,
        recentRuns: [CompletedRun]
    ) -> [SplitPR] {
        guard !run.splits.isEmpty, !recentRuns.isEmpty else { return [] }

        var prs: [SplitPR] = []

        for split in run.splits {
            let matchingSplits = recentRuns.flatMap(\.splits)
                .filter { $0.kilometerNumber == split.kilometerNumber }

            guard !matchingSplits.isEmpty else { continue }

            let previousBest = matchingSplits.map(\.duration).min() ?? .infinity
            if split.duration < previousBest {
                prs.append(SplitPR(
                    id: UUID(),
                    kilometerNumber: split.kilometerNumber,
                    currentPace: split.duration,
                    previousBestPace: previousBest
                ))
            }
        }

        return prs
    }

    // MARK: - Pace Trend

    static func calculatePaceTrend(
        run: CompletedRun,
        recentRuns: [CompletedRun]
    ) -> PaceTrend {
        let comparableRuns = Array(recentRuns.sorted { $0.date > $1.date }.prefix(5))
        guard !comparableRuns.isEmpty else { return .stable }

        let recentAvgPace = comparableRuns.map(\.averagePaceSecondsPerKm).reduce(0, +)
            / Double(comparableRuns.count)
        guard recentAvgPace > 0 else { return .stable }

        let changePercent = (run.averagePaceSecondsPerKm - recentAvgPace) / recentAvgPace * 100

        if changePercent < -3 { return .improving }
        if changePercent > 3 { return .declining }
        return .stable
    }

    // MARK: - Badges

    static func calculateBadges(
        run: CompletedRun,
        recentRuns: [CompletedRun],
        unit: UnitPreference = .metric
    ) -> [ImprovementBadge] {
        var badges: [ImprovementBadge] = []

        let allDistances = recentRuns.map(\.distanceKm)
        if let maxDistance = allDistances.max(), run.distanceKm > maxDistance {
            badges.append(ImprovementBadge(
                id: UUID(),
                title: "Longest Run",
                description: "\(UnitFormatter.formatDistance(run.distanceKm, unit: unit)) — your longest run yet",
                icon: "road.lanes"
            ))
        }

        let allElevation = recentRuns.map(\.elevationGainM)
        if let maxElevation = allElevation.max(), run.elevationGainM > maxElevation {
            badges.append(ImprovementBadge(
                id: UUID(),
                title: "Most Elevation",
                description: "+\(UnitFormatter.formatElevation(run.elevationGainM, unit: unit)) — your most climbing ever",
                icon: "mountain.2.fill"
            ))
        }

        let allPaces = recentRuns.map(\.averagePaceSecondsPerKm)
        if let bestPace = allPaces.min(), run.averagePaceSecondsPerKm < bestPace {
            badges.append(ImprovementBadge(
                id: UUID(),
                title: "Fastest Pace",
                description: "\(RunStatisticsCalculator.formatPace(run.averagePaceSecondsPerKm, unit: unit)) \(UnitFormatter.paceLabel(unit)) — a new personal best",
                icon: "bolt.fill"
            ))
        }

        let variability = AdvancedRunMetricsCalculator.paceVariabilityIndex(splits: run.splits)
        if variability > 0, variability < 0.05 {
            badges.append(ImprovementBadge(
                id: UUID(),
                title: "Consistency King",
                description: "Pace variability under 5% — rock-solid pacing",
                icon: "metronome.fill"
            ))
        }

        if let efficiency = AdvancedRunMetricsCalculator.climbingEfficiency(run: run),
           efficiency < 0.85 {
            badges.append(ImprovementBadge(
                id: UUID(),
                title: "Climbing Machine",
                description: "Climbing efficiency \(Int(efficiency * 100))% — faster than expected on uphills",
                icon: "figure.hiking"
            ))
        }

        return badges
    }
}
