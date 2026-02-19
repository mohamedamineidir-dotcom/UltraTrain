import Foundation

enum NutritionAnalysisCalculator {

    static func analyze(run: CompletedRun) -> NutritionAnalysis? {
        guard !run.nutritionIntakeLog.isEmpty else { return nil }

        let events = buildTimelineEvents(run: run)
        let impact = calculatePerformanceImpact(run: run)
        let adherence = calculateAdherence(log: run.nutritionIntakeLog)
        let calories = estimateTotalCalories(log: run.nutritionIntakeLog)

        return NutritionAnalysis(
            timelineEvents: events,
            performanceImpact: impact,
            adherencePercent: adherence,
            totalCaloriesConsumed: calories
        )
    }

    // MARK: - Timeline Events

    static func buildTimelineEvents(run: CompletedRun) -> [NutritionTimelineEvent] {
        run.nutritionIntakeLog.map { entry in
            let pace = interpolatePace(
                atElapsedTime: entry.elapsedTimeSeconds,
                splits: run.splits,
                totalDuration: run.duration
            )
            return NutritionTimelineEvent(
                id: UUID(),
                elapsedTimeSeconds: entry.elapsedTimeSeconds,
                type: entry.reminderType,
                status: entry.status,
                paceAtTime: pace
            )
        }
    }

    // MARK: - Performance Impact

    static func calculatePerformanceImpact(
        run: CompletedRun
    ) -> NutritionPerformanceImpact? {
        let takenEntries = run.nutritionIntakeLog
            .filter { $0.status == .taken }
            .sorted { $0.elapsedTimeSeconds < $1.elapsedTimeSeconds }

        guard let firstIntake = takenEntries.first,
              let lastIntake = takenEntries.last,
              run.splits.count >= 3 else { return nil }

        let beforePace = averagePaceInWindow(
            splits: run.splits,
            startSeconds: 0,
            endSeconds: firstIntake.elapsedTimeSeconds
        )
        let afterPace = averagePaceInWindow(
            splits: run.splits,
            startSeconds: lastIntake.elapsedTimeSeconds,
            endSeconds: run.duration
        )

        guard let before = beforePace, let after = afterPace, before > 0 else {
            return nil
        }

        let changePercent = (after - before) / before * 100

        return NutritionPerformanceImpact(
            averagePaceBeforeFirstIntake: before,
            averagePaceAfterLastIntake: after,
            paceChangePercent: changePercent
        )
    }

    // MARK: - Adherence

    static func calculateAdherence(log: [NutritionIntakeEntry]) -> Double {
        let taken = log.filter { $0.status == .taken }.count
        let skipped = log.filter { $0.status == .skipped }.count
        let total = taken + skipped
        guard total > 0 else { return 100 }
        return Double(taken) / Double(total) * 100
    }

    // MARK: - Calorie Estimate

    static func estimateTotalCalories(log: [NutritionIntakeEntry]) -> Double {
        var calories: Double = 0
        for entry in log where entry.status == .taken {
            switch entry.reminderType {
            case .fuel: calories += 25
            case .hydration: calories += 0
            case .electrolyte: calories += 5
            }
        }
        return calories
    }

    // MARK: - Private Helpers

    private static func interpolatePace(
        atElapsedTime time: TimeInterval,
        splits: [Split],
        totalDuration: TimeInterval
    ) -> Double? {
        guard !splits.isEmpty, totalDuration > 0 else { return nil }

        var cumulativeTime: TimeInterval = 0
        for split in splits {
            let splitEnd = cumulativeTime + split.duration
            if time <= splitEnd {
                return split.duration
            }
            cumulativeTime = splitEnd
        }

        return splits.last?.duration
    }

    private static func averagePaceInWindow(
        splits: [Split],
        startSeconds: TimeInterval,
        endSeconds: TimeInterval
    ) -> Double? {
        guard endSeconds > startSeconds, !splits.isEmpty else { return nil }

        var cumulativeTime: TimeInterval = 0
        var matchingSplits: [Split] = []

        for split in splits {
            let splitStart = cumulativeTime
            let splitEnd = cumulativeTime + split.duration
            if splitEnd > startSeconds && splitStart < endSeconds {
                matchingSplits.append(split)
            }
            cumulativeTime = splitEnd
        }

        guard !matchingSplits.isEmpty else { return nil }
        let totalPace = matchingSplits.map(\.duration).reduce(0, +)
        return totalPace / Double(matchingSplits.count)
    }
}
