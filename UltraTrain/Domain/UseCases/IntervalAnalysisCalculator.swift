import Foundation

enum IntervalAnalysisCalculator {

    struct IntervalAnalysis: Equatable, Sendable {
        let workSplits: [IntervalSplit]
        let recoverySplits: [IntervalSplit]
        let fastestWorkSplit: IntervalSplit?
        let slowestWorkSplit: IntervalSplit?
        let averageWorkPace: Double
        let paceConsistencyPercent: Double
        let averageWorkHeartRate: Int?
        let averageRecoveryHeartRate: Int?
        let heartRateRecoveryDelta: Int?
        let totalWorkTime: TimeInterval
        let totalRecoveryTime: TimeInterval
        let workToRestRatio: Double
    }

    static func analyze(splits: [IntervalSplit]) -> IntervalAnalysis {
        let workSplits = splits.filter { $0.phaseType == .work }
        let recoverySplits = splits.filter { $0.phaseType == .recovery }

        let fastestWork = workSplits.min { $0.averagePaceSecondsPerKm < $1.averagePaceSecondsPerKm }
        let slowestWork = workSplits.max { $0.averagePaceSecondsPerKm < $1.averagePaceSecondsPerKm }

        let avgWorkPace = calculateAveragePace(workSplits)
        let consistency = calculatePaceConsistency(workSplits)

        let avgWorkHR = calculateAverageHeartRate(workSplits)
        let avgRecoveryHR = calculateAverageHeartRate(recoverySplits)

        let hrDelta: Int?
        if let workHR = avgWorkHR, let recoveryHR = avgRecoveryHR {
            hrDelta = workHR - recoveryHR
        } else {
            hrDelta = nil
        }

        let totalWork = workSplits.reduce(0.0) { $0 + $1.duration }
        let totalRecovery = recoverySplits.reduce(0.0) { $0 + $1.duration }
        let ratio = totalRecovery > 0 ? totalWork / totalRecovery : 0

        return IntervalAnalysis(
            workSplits: workSplits,
            recoverySplits: recoverySplits,
            fastestWorkSplit: fastestWork,
            slowestWorkSplit: slowestWork,
            averageWorkPace: avgWorkPace,
            paceConsistencyPercent: consistency,
            averageWorkHeartRate: avgWorkHR,
            averageRecoveryHeartRate: avgRecoveryHR,
            heartRateRecoveryDelta: hrDelta,
            totalWorkTime: totalWork,
            totalRecoveryTime: totalRecovery,
            workToRestRatio: ratio
        )
    }

    // MARK: - Private

    private static func calculateAveragePace(_ splits: [IntervalSplit]) -> Double {
        guard !splits.isEmpty else { return 0 }
        let total = splits.reduce(0.0) { $0 + $1.averagePaceSecondsPerKm }
        return total / Double(splits.count)
    }

    private static func calculatePaceConsistency(_ splits: [IntervalSplit]) -> Double {
        guard splits.count >= 2 else { return 100 }
        let paces = splits.map(\.averagePaceSecondsPerKm)
        let mean = paces.reduce(0.0, +) / Double(paces.count)
        guard mean > 0 else { return 100 }

        let variance = paces.reduce(0.0) { $0 + pow($1 - mean, 2) } / Double(paces.count)
        let stddev = sqrt(variance)
        let coefficientOfVariation = stddev / mean

        return max(0, min(100, (1.0 - coefficientOfVariation) * 100))
    }

    private static func calculateAverageHeartRate(_ splits: [IntervalSplit]) -> Int? {
        let heartRates = splits.compactMap(\.averageHeartRate)
        guard !heartRates.isEmpty else { return nil }
        return heartRates.reduce(0, +) / heartRates.count
    }
}
