import Foundation

enum AdvancedRunMetricsCalculator {

    static func calculate(
        run: CompletedRun,
        athleteWeightKg: Double?,
        maxHeartRate: Int?
    ) -> AdvancedRunMetrics {
        let variability = paceVariabilityIndex(splits: run.splits)
        let efficiency = climbingEfficiency(run: run)
        let calories = estimatedCalories(
            duration: run.duration,
            weightKg: athleteWeightKg,
            averagePace: run.averagePaceSecondsPerKm
        )
        let trainingEffect = trainingEffectScore(
            gpsTrack: run.gpsTrack,
            duration: run.duration,
            maxHeartRate: maxHeartRate
        )
        let adjustedPace = gradientAdjustedPace(run: run)

        return AdvancedRunMetrics(
            paceVariabilityIndex: variability,
            climbingEfficiency: efficiency,
            estimatedCalories: calories,
            trainingEffectScore: trainingEffect,
            averageGradientAdjustedPace: adjustedPace
        )
    }

    // MARK: - Pace Variability

    static func paceVariabilityIndex(splits: [Split]) -> Double {
        guard splits.count >= 2 else { return 0 }
        let paces = splits.map(\.duration)
        let mean = paces.reduce(0, +) / Double(paces.count)
        guard mean > 0 else { return 0 }
        let variance = paces.reduce(0.0) { $0 + ($1 - mean) * ($1 - mean) } / Double(paces.count)
        return sqrt(variance) / mean
    }

    // MARK: - Climbing Efficiency

    static func climbingEfficiency(run: CompletedRun) -> Double? {
        let uphillSplits = run.splits.filter { $0.elevationChangeM > 10 }
        guard uphillSplits.count >= 2 else { return nil }

        let flatSplits = run.splits.filter { abs($0.elevationChangeM) <= 10 }
        guard !flatSplits.isEmpty else { return nil }

        let avgFlatPace = flatSplits.map(\.duration).reduce(0, +) / Double(flatSplits.count)
        guard avgFlatPace > 0 else { return nil }

        var totalActualTime: Double = 0
        var totalExpectedTime: Double = 0

        for split in uphillSplits {
            let elevationFactor = 1.0 + (split.elevationChangeM / 100.0)
            let expectedPace = avgFlatPace * elevationFactor
            totalActualTime += split.duration
            totalExpectedTime += expectedPace
        }

        guard totalExpectedTime > 0 else { return nil }
        return totalActualTime / totalExpectedTime
    }

    // MARK: - Calorie Burn

    static func estimatedCalories(
        duration: TimeInterval,
        weightKg: Double?,
        averagePace: Double
    ) -> Double {
        let weight = weightKg ?? 70.0
        let met: Double
        switch averagePace {
        case ..<300: met = 12.0     // < 5:00/km — fast running
        case 300..<360: met = 10.0  // 5:00-6:00/km
        case 360..<420: met = 9.0   // 6:00-7:00/km
        case 420..<480: met = 8.0   // 7:00-8:00/km
        default: met = 7.0          // > 8:00/km — slow jogging/walking
        }
        let durationHours = duration / 3600.0
        return met * weight * durationHours
    }

    // MARK: - Training Effect

    static func trainingEffectScore(
        gpsTrack: [TrackPoint],
        duration: TimeInterval,
        maxHeartRate: Int?
    ) -> Double {
        guard let maxHR = maxHeartRate, maxHR > 0 else {
            return durationBasedEffect(duration)
        }

        let heartRates = gpsTrack.compactMap(\.heartRate)
        guard heartRates.count >= 10 else {
            return durationBasedEffect(duration)
        }

        var zoneMinutes: [Int: Double] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        for i in 1..<gpsTrack.count {
            guard let hr = gpsTrack[i].heartRate else { continue }
            let timeDelta = gpsTrack[i].timestamp.timeIntervalSince(gpsTrack[i - 1].timestamp)
            guard timeDelta > 0, timeDelta < 60 else { continue }
            let zone = RunStatisticsCalculator.heartRateZone(heartRate: hr, maxHeartRate: maxHR)
            zoneMinutes[zone, default: 0] += timeDelta / 60.0
        }

        let zoneWeights: [Int: Double] = [1: 1.0, 2: 2.0, 3: 3.0, 4: 4.0, 5: 5.0]
        var weightedScore = 0.0
        var totalMinutes = 0.0

        for (zone, minutes) in zoneMinutes {
            weightedScore += minutes * (zoneWeights[zone] ?? 1.0)
            totalMinutes += minutes
        }

        guard totalMinutes > 0 else { return 1.0 }

        let avgZoneWeight = weightedScore / totalMinutes
        let durationFactor = min(1.0, totalMinutes / 60.0)
        let rawScore = avgZoneWeight * durationFactor

        return max(1.0, min(5.0, rawScore))
    }

    // MARK: - Gradient-Adjusted Pace

    static func gradientAdjustedPace(run: CompletedRun) -> Double {
        let effectiveKm = run.distanceKm + (run.elevationGainM / 100.0)
        guard effectiveKm > 0 else { return run.averagePaceSecondsPerKm }
        return run.duration / effectiveKm
    }

    // MARK: - Private

    private static func durationBasedEffect(_ duration: TimeInterval) -> Double {
        let minutes = duration / 60.0
        switch minutes {
        case ..<20: return 1.0
        case 20..<40: return 2.0
        case 40..<60: return 3.0
        case 60..<90: return 3.5
        default: return min(5.0, 3.5 + (minutes - 90) / 60.0)
        }
    }
}
