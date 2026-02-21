import Foundation

enum RecoveryScoreCalculator {

    // MARK: - Calculate

    static func calculate(
        lastNightSleep: SleepEntry?,
        sleepHistory: [SleepEntry],
        currentRestingHR: Int?,
        baselineRestingHR: Int?,
        fitnessSnapshot: FitnessSnapshot?,
        hrvScore: Int? = nil
    ) -> RecoveryScore {
        let hasSleepData = lastNightSleep != nil

        let sleepQuality = calculateSleepQualityScore(lastNightSleep)
        let sleepConsistency = calculateSleepConsistencyScore(sleepHistory)
        let hrScore = calculateRestingHRScore(current: currentRestingHR, baseline: baselineRestingHR)
        let loadBalance = calculateTrainingLoadBalanceScore(fitnessSnapshot)

        let overall: Int
        if let hrvScore, hasSleepData {
            // When HRV available with sleep data: sleep 30%, consistency 10%, resting HR 20%, load 20%, HRV 20%
            overall = Int(
                Double(sleepQuality) * 0.30
                + Double(sleepConsistency) * 0.10
                + Double(hrScore) * 0.20
                + Double(loadBalance) * 0.20
                + Double(hrvScore) * 0.20
            )
        } else if hasSleepData {
            overall = Int(
                Double(sleepQuality) * AppConfiguration.Recovery.sleepQualityWeight
                + Double(sleepConsistency) * AppConfiguration.Recovery.sleepConsistencyWeight
                + Double(hrScore) * AppConfiguration.Recovery.restingHRWeight
                + Double(loadBalance) * AppConfiguration.Recovery.trainingLoadWeight
            )
        } else {
            overall = Int(Double(hrScore) * 0.5 + Double(loadBalance) * 0.5)
        }

        let clampedScore = max(0, min(100, overall))
        let status = statusFor(score: clampedScore)
        let recommendation = generateRecommendation(
            score: clampedScore,
            sleepQuality: sleepQuality,
            hrScore: hrScore,
            loadBalance: loadBalance,
            hasSleepData: hasSleepData
        )

        return RecoveryScore(
            id: UUID(),
            date: Date.now,
            overallScore: clampedScore,
            sleepQualityScore: sleepQuality,
            sleepConsistencyScore: sleepConsistency,
            restingHRScore: hrScore,
            trainingLoadBalanceScore: loadBalance,
            recommendation: recommendation,
            status: status,
            hrvScore: hrvScore ?? 0
        )
    }

    // MARK: - Sleep Quality (0-100)

    private static func calculateSleepQualityScore(_ sleep: SleepEntry?) -> Int {
        guard let sleep else { return 50 }

        let hours = sleep.totalSleepDuration / 3600
        let targetLow = AppConfiguration.Recovery.targetSleepHoursLow
        let targetHigh = AppConfiguration.Recovery.targetSleepHoursHigh

        // Duration score (0-60 points)
        let durationScore: Double
        if hours >= targetLow && hours <= targetHigh {
            durationScore = 60
        } else if hours < targetLow {
            durationScore = max(0, 60 * (hours / targetLow))
        } else {
            durationScore = max(30, 60 - (hours - targetHigh) * 10)
        }

        // Deep sleep score (0-20 points) — target 15-25% of total
        let deepPercent = sleep.totalSleepDuration > 0
            ? sleep.deepSleepDuration / sleep.totalSleepDuration
            : 0
        let deepScore: Double
        if deepPercent >= 0.15 && deepPercent <= 0.25 {
            deepScore = 20
        } else if deepPercent > 0 {
            deepScore = max(0, 20 * min(deepPercent / 0.15, 1.0))
        } else {
            deepScore = 10
        }

        // Efficiency score (0-20 points)
        let efficiencyScore = 20 * min(sleep.sleepEfficiency, 1.0)

        return min(100, Int(durationScore + deepScore + efficiencyScore))
    }

    // MARK: - Sleep Consistency (0-100)

    private static func calculateSleepConsistencyScore(_ history: [SleepEntry]) -> Int {
        guard history.count >= 2 else { return 50 }

        let bedtimeHours = history.map { bedtimeHour($0.bedtime) }
        let wakeHours = history.map { wakeHour($0.wakeTime) }

        let bedtimeStdDev = standardDeviation(bedtimeHours)
        let wakeStdDev = standardDeviation(wakeHours)
        let avgStdDev = (bedtimeStdDev + wakeStdDev) / 2

        // Lower stddev = more consistent = higher score
        // 0 stddev = 100, 2+ hours stddev = 0
        let consistencyScore = max(0, min(100, Int(100 * (1 - avgStdDev / 2.0))))

        let avgHours = history.map { $0.totalSleepDuration / 3600 }.reduce(0, +)
            / Double(history.count)
        let debtPenalty = avgHours < AppConfiguration.Recovery.targetSleepHoursLow
            ? Int((AppConfiguration.Recovery.targetSleepHoursLow - avgHours) * 15)
            : 0

        return max(0, consistencyScore - debtPenalty)
    }

    // MARK: - Resting HR (0-100)

    private static func calculateRestingHRScore(current: Int?, baseline: Int?) -> Int {
        guard let current else { return 50 }
        guard let baseline, baseline > 0 else { return 50 }

        let diff = current - baseline
        if diff <= 0 { return 100 }
        // Each BPM above baseline reduces by 10 points
        return max(0, 100 - diff * 10)
    }

    // MARK: - Training Load Balance (0-100)

    private static func calculateTrainingLoadBalanceScore(_ snapshot: FitnessSnapshot?) -> Int {
        guard let snapshot else { return 50 }

        let form = snapshot.form
        // form > 10 = fresh = 100, form -30 = 0
        if form >= 10 { return 100 }
        if form <= -30 { return 0 }
        return Int(100 * (form + 30) / 40)
    }

    // MARK: - Status

    private static func statusFor(score: Int) -> RecoveryStatus {
        switch score {
        case 80...100: .excellent
        case 60..<80: .good
        case 40..<60: .moderate
        case 20..<40: .poor
        default: .critical
        }
    }

    // MARK: - Recommendation

    private static func generateRecommendation(
        score: Int,
        sleepQuality: Int,
        hrScore: Int,
        loadBalance: Int,
        hasSleepData: Bool
    ) -> String {
        if !hasSleepData {
            return "Enable sleep tracking for a more accurate recovery score."
        }
        if score >= 80 {
            return "Well recovered. Great day for a quality session."
        }
        if score < AppConfiguration.Recovery.lowRecoveryThreshold {
            return "Recovery is low. Consider reducing intensity and prioritizing rest."
        }

        let lowestComponent = min(sleepQuality, hrScore, loadBalance)
        if lowestComponent == sleepQuality {
            return "Sleep quality was low. Prioritize an earlier bedtime tonight."
        }
        if lowestComponent == hrScore {
            return "Resting heart rate is elevated. Your body may need extra recovery."
        }
        return "Training load is high. Consider an easy day to let your body adapt."
    }

    // MARK: - Math Helpers

    private static func bedtimeHour(_ date: Date) -> Double {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        var hour = Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60
        if hour < 12 { hour += 24 }
        return hour
    }

    private static func wakeHour(_ date: Date) -> Double {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60
    }

    private static func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(values.count)
        return variance.squareRoot()
    }
}
