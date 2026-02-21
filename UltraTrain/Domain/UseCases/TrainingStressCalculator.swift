import Foundation

enum TrainingStressCalculator {

    // MARK: - Constants

    private static let zoneFactors: [Int: Double] = [
        1: 1.0, 2: 1.5, 3: 2.0, 4: 3.0, 5: 5.0
    ]
    private static let thresholdZoneFactor: Double = 3.0
    private static let normalizationMinutes: Double = 60.0
    private static let minimumHRMinutes: Double = 5.0

    // MARK: - HR-based TSS

    static func calculateHRTSS(
        gpsTrack: [TrackPoint],
        maxHeartRate: Int,
        restingHeartRate: Int,
        customThresholds: [Int]? = nil
    ) -> Double? {
        guard maxHeartRate > restingHeartRate, maxHeartRate > 0 else { return nil }
        guard gpsTrack.count >= 2 else { return nil }

        var zoneMinutes: [Int: Double] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        var totalMinutes: Double = 0

        for i in 1..<gpsTrack.count {
            guard let hr = gpsTrack[i].heartRate, hr > 0 else { continue }
            let timeDelta = gpsTrack[i].timestamp.timeIntervalSince(gpsTrack[i - 1].timestamp)
            guard timeDelta > 0, timeDelta < 60 else { continue }

            let zone = RunStatisticsCalculator.heartRateZone(
                heartRate: hr,
                maxHeartRate: maxHeartRate,
                customThresholds: customThresholds
            )
            let minutes = timeDelta / 60.0
            zoneMinutes[zone, default: 0] += minutes
            totalMinutes += minutes
        }

        guard totalMinutes >= minimumHRMinutes else { return nil }

        var weightedScore = 0.0
        for (zone, minutes) in zoneMinutes {
            weightedScore += minutes * (zoneFactors[zone] ?? 1.0)
        }

        let tss = (weightedScore / (normalizationMinutes * thresholdZoneFactor)) * 100
        return tss
    }

    // MARK: - RPE-based TSS

    static func calculateRPETSS(durationMinutes: Double, rpe: Int) -> Double {
        guard rpe >= 1, rpe <= 10, durationMinutes > 0 else { return 0 }
        let rpeNormalized = Double(rpe) / 10.0
        let intensityFactor = rpeNormalized * rpeNormalized
        let scaleFactor = 100.0 / (normalizationMinutes * 0.64)
        return durationMinutes * intensityFactor * scaleFactor
    }

    // MARK: - Combined

    static func calculate(
        run: CompletedRun,
        maxHeartRate: Int,
        restingHeartRate: Int,
        customThresholds: [Int]? = nil
    ) -> Double {
        if let hrTSS = calculateHRTSS(
            gpsTrack: run.gpsTrack,
            maxHeartRate: maxHeartRate,
            restingHeartRate: restingHeartRate,
            customThresholds: customThresholds
        ) {
            return hrTSS
        }

        if let rpe = run.rpe {
            return calculateRPETSS(
                durationMinutes: run.duration / 60.0,
                rpe: rpe
            )
        }

        return run.distanceKm + (run.elevationGainM / 100.0)
    }
}
