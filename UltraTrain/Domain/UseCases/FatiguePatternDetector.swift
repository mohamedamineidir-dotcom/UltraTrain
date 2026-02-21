import Foundation

enum FatiguePatternDetector {

    struct Input: Sendable {
        let recentRuns: [CompletedRun]
        let sleepHistory: [SleepEntry]
        let recoveryScores: [RecoveryScore]
    }

    // MARK: - Public API

    static func detect(input: Input) -> [FatiguePattern] {
        var patterns: [FatiguePattern] = []

        let windowDays = AppConfiguration.AICoach.fatigueDetectionWindowDays

        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -windowDays,
            to: Date.now
        ) ?? Date.distantPast

        let sortedRuns = input.recentRuns
            .filter { $0.date >= cutoffDate }
            .sorted { $0.date < $1.date }

        if let pattern = detectPaceDecline(runs: sortedRuns) {
            patterns.append(pattern)
        }

        if let pattern = detectHeartRateDrift(runs: sortedRuns) {
            patterns.append(pattern)
        }

        if let pattern = detectSleepDecline(sleepHistory: input.sleepHistory) {
            patterns.append(pattern)
        }

        if let pattern = detectRPETrend(runs: sortedRuns) {
            patterns.append(pattern)
        }

        if patterns.count >= AppConfiguration.AICoach.compoundFatigueThreshold {
            let deloadDays = AppConfiguration.AICoach.deloadSuggestionDays + 2
            let compound = FatiguePattern(
                id: UUID(),
                type: .compoundFatigue,
                severity: .significant,
                evidence: patterns.flatMap(\.evidence),
                recommendation: "Multiple fatigue signals detected. Consider \(deloadDays) days of reduced training.",
                suggestedDeloadDays: deloadDays,
                detectedDate: Date.now
            )
            patterns.append(compound)
        }

        return patterns
    }

    // MARK: - Pace Decline

    private static func detectPaceDecline(runs: [CompletedRun]) -> FatiguePattern? {
        let moderateRuns = runs.filter { run in
            guard let hr = run.averageHeartRate else { return false }
            return hr >= 130 && hr <= 165
        }

        guard moderateRuns.count >= AppConfiguration.AICoach.trendMinDataPoints else {
            return nil
        }

        let paces = moderateRuns.map(\.averagePaceSecondsPerKm)

        let midpoint = paces.count / 2
        let firstHalfAvg = average(of: Array(paces[0..<midpoint]))
        let secondHalfAvg = average(of: Array(paces[midpoint...]))

        guard firstHalfAvg > 0 else { return nil }

        let changePercent = (secondHalfAvg - firstHalfAvg) / firstHalfAvg

        guard changePercent > AppConfiguration.AICoach.paceDeclineThreshold else {
            return nil
        }

        let severity = severityFromPercent(changePercent)

        return FatiguePattern(
            id: UUID(),
            type: .paceDecline,
            severity: severity,
            evidence: [FatigueEvidence(
                metric: "Average pace at moderate HR",
                baselineValue: firstHalfAvg,
                currentValue: secondHalfAvg,
                changePercent: changePercent * 100,
                period: "Last \(moderateRuns.count) moderate-effort runs"
            )],
            recommendation: "Pace at similar heart rate is declining. Consider reducing training load for \(AppConfiguration.AICoach.deloadSuggestionDays) days.",
            suggestedDeloadDays: AppConfiguration.AICoach.deloadSuggestionDays,
            detectedDate: Date.now
        )
    }

    // MARK: - Heart Rate Drift

    private static func detectHeartRateDrift(runs: [CompletedRun]) -> FatiguePattern? {
        let runsWithHR = runs.filter {
            $0.averageHeartRate != nil && $0.averagePaceSecondsPerKm > 0
        }

        guard runsWithHR.count >= AppConfiguration.AICoach.trendMinDataPoints else {
            return nil
        }

        let avgPace = runsWithHR.map(\.averagePaceSecondsPerKm).reduce(0, +)
            / Double(runsWithHR.count)

        let similarPaceRuns = runsWithHR.filter {
            abs($0.averagePaceSecondsPerKm - avgPace) < 30
        }

        guard similarPaceRuns.count >= AppConfiguration.AICoach.trendMinDataPoints else {
            return nil
        }

        let heartRates = similarPaceRuns.compactMap(\.averageHeartRate).map(Double.init)

        let midpoint = heartRates.count / 2
        let firstHalfAvg = average(of: Array(heartRates[0..<midpoint]))
        let secondHalfAvg = average(of: Array(heartRates[midpoint...]))

        guard firstHalfAvg > 0 else { return nil }

        let changePercent = (secondHalfAvg - firstHalfAvg) / firstHalfAvg

        guard changePercent > AppConfiguration.AICoach.hrDriftThreshold else {
            return nil
        }

        let severity = severityFromPercent(changePercent)

        return FatiguePattern(
            id: UUID(),
            type: .heartRateDrift,
            severity: severity,
            evidence: [FatigueEvidence(
                metric: "Average HR at similar pace",
                baselineValue: firstHalfAvg,
                currentValue: secondHalfAvg,
                changePercent: changePercent * 100,
                period: "Last \(similarPaceRuns.count) similar-pace runs"
            )],
            recommendation: "Heart rate is rising at the same effort level. Your cardiovascular system may need recovery.",
            suggestedDeloadDays: AppConfiguration.AICoach.deloadSuggestionDays,
            detectedDate: Date.now
        )
    }

    // MARK: - Sleep Quality Decline

    private static func detectSleepDecline(
        sleepHistory: [SleepEntry]
    ) -> FatiguePattern? {
        guard sleepHistory.count >= 7 else { return nil }

        let sorted = sleepHistory.sorted { $0.date < $1.date }

        let recentCount = min(3, sorted.count)
        let baselineCount = min(7, sorted.count)

        let recent = sorted.suffix(recentCount)
        let baseline = sorted.suffix(baselineCount)

        let recentAvgQuality = average(
            of: recent.map { sleepQualityScore(for: $0) }
        )
        let baselineAvgQuality = average(
            of: baseline.map { sleepQualityScore(for: $0) }
        )

        guard baselineAvgQuality > 0 else { return nil }

        let changePercent = (baselineAvgQuality - recentAvgQuality) / baselineAvgQuality

        guard changePercent > AppConfiguration.AICoach.sleepDeclineThreshold else {
            return nil
        }

        let severity = sleepSeverity(from: changePercent)

        return FatiguePattern(
            id: UUID(),
            type: .sleepQualityDecline,
            severity: severity,
            evidence: [FatigueEvidence(
                metric: "Sleep quality score (efficiency x hours)",
                baselineValue: baselineAvgQuality,
                currentValue: recentAvgQuality,
                changePercent: changePercent * 100,
                period: "Last 3 nights vs 7-night baseline"
            )],
            recommendation: "Sleep quality has dropped significantly. Prioritize sleep hygiene and an earlier bedtime.",
            suggestedDeloadDays: nil,
            detectedDate: Date.now
        )
    }

    // MARK: - RPE Trend

    private static func detectRPETrend(runs: [CompletedRun]) -> FatiguePattern? {
        let runsWithRPE = runs.filter { $0.rpe != nil }

        guard runsWithRPE.count >= AppConfiguration.AICoach.trendMinDataPoints else {
            return nil
        }

        let rpeValues = runsWithRPE.compactMap(\.rpe).map(Double.init)

        let midpoint = rpeValues.count / 2
        let firstHalfAvg = average(of: Array(rpeValues[0..<midpoint]))
        let secondHalfAvg = average(of: Array(rpeValues[midpoint...]))

        let rpeRise = secondHalfAvg - firstHalfAvg

        guard rpeRise > AppConfiguration.AICoach.rpeRiseThreshold else {
            return nil
        }

        let severity: FatigueSeverity
        if rpeRise > 3.0 {
            severity = .significant
        } else if rpeRise > 2.0 {
            severity = .moderate
        } else {
            severity = .mild
        }

        return FatiguePattern(
            id: UUID(),
            type: .rpeTrend,
            severity: severity,
            evidence: [FatigueEvidence(
                metric: "Rate of Perceived Exertion",
                baselineValue: firstHalfAvg,
                currentValue: secondHalfAvg,
                changePercent: (rpeRise / max(firstHalfAvg, 1)) * 100,
                period: "Last \(runsWithRPE.count) rated runs"
            )],
            recommendation: "Perceived effort is rising. Runs feel harder even though the training load hasn't changed — a classic fatigue signal.",
            suggestedDeloadDays: AppConfiguration.AICoach.deloadSuggestionDays,
            detectedDate: Date.now
        )
    }

    // MARK: - Helpers

    private static func average(of values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func sleepQualityScore(for entry: SleepEntry) -> Double {
        entry.sleepEfficiency * (entry.totalSleepDuration / 3600)
    }

    private static func severityFromPercent(_ percent: Double) -> FatigueSeverity {
        if percent > 0.15 {
            return .significant
        } else if percent > 0.10 {
            return .moderate
        } else {
            return .mild
        }
    }

    private static func sleepSeverity(from changePercent: Double) -> FatigueSeverity {
        if changePercent > 0.30 {
            return .significant
        } else if changePercent > 0.20 {
            return .moderate
        } else {
            return .mild
        }
    }
}
