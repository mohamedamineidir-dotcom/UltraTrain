import Foundation

/// Converts a fitness-test result into a new VMA-equivalent value and
/// decides whether the resulting delta justifies recalibrating the
/// remaining training plan.
///
/// Decision logic:
/// - delta < 5%: log the result, no plan change. Within normal day-to-day
///   variability + measurement noise. Avoids churning the plan for noise.
/// - 5% ≤ delta < 7%: recalibrate **training paces only** (easy / threshold
///   / interval / VMA-paced sessions). Race-day target stays as-is. Hudson's
///   rule: training paces follow fitness in real time; race targets need
///   confirmation.
/// - 7% ≤ delta ≤ 15%: recalibrate training paces AND suggest a race-target
///   adjustment, but only when we're still in build phase (≥4 weeks before
///   race) — not in peak / taper. Late-prep target changes are risky.
/// - delta > 15%: flag for athlete review. Likely a measurement issue
///   (track length wrong, GPS error, hot day, illness) — don't auto-update.
///
/// Trail uphill / treadmill variants don't currently auto-recalibrate
/// (`producesPaceRecalibration == false`) because the trail pipeline
/// uses effort cues (RPE / "race effort") rather than HR-zone or
/// pace-anchored prescriptions. The result is recorded for the athlete's
/// own reference + future feature work.
enum FitnessTestRecalibrator {

    static let trainingPaceDeltaThreshold = 0.05   // 5%
    static let raceTargetDeltaThreshold = 0.07     // 7%
    static let suspiciousDeltaThreshold = 0.15     // 15% — flag, don't auto-update

    enum Recommendation: Equatable, Sendable {
        case noChange(reason: String)
        case recalibrateTrainingPacesOnly
        case recalibrateAll
        case suspicious  // delta too large to trust automatically
    }

    struct Result: Equatable, Sendable {
        let measuredVmaKmh: Double?      // nil for non-pace-recalibrating variants
        let baselineVmaKmh: Double?
        let deltaPercent: Double          // signed: + = improved, - = regressed
        let recommendation: Recommendation
        let updatedPaceProfile: RoadPaceProfile?  // nil unless recalibrated
    }

    /// Converts a test result into a recommendation + (when applicable)
    /// an updated RoadPaceProfile.
    static func recalibrate(
        testVariant: FitnessTestVariant,
        result: TestResultInput,
        athlete: Athlete,
        targetRace: Race,
        weeksUntilRace: Int,
        currentRacePhase: TrainingPhase
    ) -> Result {
        // Trail uphill / treadmill variants: surface result, no
        // auto-recalibration.
        guard testVariant.producesPaceRecalibration else {
            return Result(
                measuredVmaKmh: nil,
                baselineVmaKmh: athlete.vmaKmh,
                deltaPercent: 0,
                recommendation: .noChange(reason: "Threshold-zone tests record HR + effort calibration; the plan's effort-based prescriptions don't auto-update from this signal."),
                updatedPaceProfile: nil
            )
        }

        // Compute measured VMA from the test result.
        guard let measuredVma = computeMeasuredVMA(variant: testVariant, result: result) else {
            return Result(
                measuredVmaKmh: nil,
                baselineVmaKmh: athlete.vmaKmh,
                deltaPercent: 0,
                recommendation: .noChange(reason: "Result missing required data — recalibration skipped."),
                updatedPaceProfile: nil
            )
        }

        // Baseline VMA: prefer the athlete's stored vmaKmh (most recent
        // calibration); fall back to deriving from their best 5K PR
        // when vmaKmh is nil.
        let baselineVma = baselineVMA(athlete: athlete)
        guard let baseline = baselineVma, baseline > 0 else {
            // No baseline to compare against — accept the new VMA and
            // recalibrate training paces.
            let updatedAthlete = athlete.with(vmaKmh: measuredVma)
            let profile = newPaceProfile(athlete: updatedAthlete, targetRace: targetRace)
            return Result(
                measuredVmaKmh: measuredVma,
                baselineVmaKmh: nil,
                deltaPercent: 0,
                recommendation: .recalibrateTrainingPacesOnly,
                updatedPaceProfile: profile
            )
        }

        let delta = (measuredVma - baseline) / baseline
        let absDelta = abs(delta)

        // Suspiciously large delta — surface but don't auto-update.
        if absDelta > suspiciousDeltaThreshold {
            return Result(
                measuredVmaKmh: measuredVma,
                baselineVmaKmh: baseline,
                deltaPercent: delta,
                recommendation: .suspicious,
                updatedPaceProfile: nil
            )
        }

        // Below the noise floor — no change.
        if absDelta < trainingPaceDeltaThreshold {
            return Result(
                measuredVmaKmh: measuredVma,
                baselineVmaKmh: baseline,
                deltaPercent: delta,
                recommendation: .noChange(reason: "Result is within normal day-to-day variability of your existing fitness anchor (delta \(String(format: "%.1f", delta * 100))%)."),
                updatedPaceProfile: nil
            )
        }

        // Above noise — recompute pace profile with the new VMA.
        let updatedAthlete = athlete.with(vmaKmh: measuredVma)
        let updatedProfile = newPaceProfile(athlete: updatedAthlete, targetRace: targetRace)

        // Should we ALSO suggest race-target adjustment?
        // Yes if: |delta| ≥ 7% AND we're still in build phase AND
        // ≥ 4 weeks remain. Late-prep target changes are risky.
        let inBuildOrEarlier: Bool = {
            switch currentRacePhase {
            case .base, .build: return true
            case .peak, .taper, .race, .recovery: return false
            }
        }()
        let timeToActOnTarget = weeksUntilRace >= 4
        if absDelta >= raceTargetDeltaThreshold && inBuildOrEarlier && timeToActOnTarget {
            return Result(
                measuredVmaKmh: measuredVma,
                baselineVmaKmh: baseline,
                deltaPercent: delta,
                recommendation: .recalibrateAll,
                updatedPaceProfile: updatedProfile
            )
        }

        return Result(
            measuredVmaKmh: measuredVma,
            baselineVmaKmh: baseline,
            deltaPercent: delta,
            recommendation: .recalibrateTrainingPacesOnly,
            updatedPaceProfile: updatedProfile
        )
    }

    // MARK: - VMA conversions

    /// Computes a VMA-km/h equivalent from the test result, depending
    /// on variant.
    /// - VMA flat 6-min: VMA = distance_m / 100 (Léger-Boucher).
    /// - 5K TT: VMA km/h ≈ avg5KSpeed_kmh / 0.97 (5K is run at ~97%
    ///   VMA, Daniels). avg5KSpeed = 5 km / time_h.
    static func computeMeasuredVMA(
        variant: FitnessTestVariant,
        result: TestResultInput
    ) -> Double? {
        switch variant {
        case .vmaFlat6Min:
            guard let meters = result.distanceMeters, meters > 0 else { return nil }
            return meters / 100.0
        case .fiveKTT:
            guard let timeSec = result.timeSeconds, timeSec > 0 else { return nil }
            let avgSpeedKmh = 5.0 / (timeSec / 3600.0)
            return avgSpeedKmh / 0.97
        case .uphillSustained30Min,
             .uphillRepeats4x8,
             .uphillRepeats6x4,
             .treadmillIncline30Min:
            return nil
        }
    }

    /// Derives a baseline VMA from the athlete's existing data: prefer
    /// stored vmaKmh, fall back to inverse of the 5K-pace estimate
    /// from RoadPaceCalculator.
    private static func baselineVMA(athlete: Athlete) -> Double? {
        if let v = athlete.vmaKmh, v > 0 { return v }
        // Derive from 5K PR if available.
        let fiveK = athlete.personalBests.first {
            $0.distance == .fiveK && $0.timeSeconds > 0
        }
        if let fiveK {
            let avg5KSpeedKmh = 5.0 / (fiveK.timeSeconds / 3600.0)
            return avg5KSpeedKmh / 0.97
        }
        return nil
    }

    private static func newPaceProfile(
        athlete: Athlete,
        targetRace: Race
    ) -> RoadPaceProfile? {
        // Mirror what TrainingPlanGenerator does for road plans.
        let goalTime: TimeInterval?
        switch targetRace.goalType {
        case .targetTime(let t): goalTime = t
        case .targetRanking:
            goalTime = targetRace.estimatedDuration(experience: athlete.experienceLevel) * 0.93
        case .finish: goalTime = nil
        }
        return RoadPaceCalculator.paceProfile(
            goalTime: goalTime,
            raceDistanceKm: targetRace.distanceKm,
            personalBests: athlete.personalBests,
            vmaKmh: athlete.vmaKmh,
            experience: athlete.experienceLevel
        )
    }
}

// MARK: - Test result input

struct TestResultInput: Equatable, Sendable {
    var distanceMeters: Double?     // for VMA flat
    var timeSeconds: TimeInterval?  // for 5K TT, uphill TT
    var averageHeartRate: Int?      // for uphill / treadmill — informational
    var perceivedEffortRPE: Int?    // 1-10 — informational
    var notes: String?

    init(
        distanceMeters: Double? = nil,
        timeSeconds: TimeInterval? = nil,
        averageHeartRate: Int? = nil,
        perceivedEffortRPE: Int? = nil,
        notes: String? = nil
    ) {
        self.distanceMeters = distanceMeters
        self.timeSeconds = timeSeconds
        self.averageHeartRate = averageHeartRate
        self.perceivedEffortRPE = perceivedEffortRPE
        self.notes = notes
    }
}

// MARK: - Athlete copy-with helper

private extension Athlete {
    func with(vmaKmh newValue: Double) -> Athlete {
        var copy = self
        copy.vmaKmh = newValue
        return copy
    }
}
