import Foundation
import Testing
@testable import UltraTrain

@Suite("FitnessTestRecalibrator")
struct FitnessTestRecalibratorTests {

    // MARK: - Helpers

    private func makeAthlete(vmaKmh: Double? = 14.0, fiveKTimeSec: TimeInterval? = nil) -> Athlete {
        var a = Athlete(
            id: UUID(), firstName: "Test", lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70, heightCm: 175,
            restingHeartRate: 50, maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 50, longestRunKm: 25,
            preferredUnit: .metric,
            trainingPhilosophy: .balanced,
            preferredRunsPerWeek: 5
        )
        a.vmaKmh = vmaKmh
        if let t = fiveKTimeSec {
            a.personalBests = [PersonalBest(id: UUID(), distance: .fiveK, timeSeconds: t, date: Date.now)]
        }
        return a
    }

    private func makeRace(distanceKm: Double = 42.195) -> Race {
        Race(
            id: UUID(), name: "Test", date: .now.addingTimeInterval(86400 * 7 * 8),
            distanceKm: distanceKm, elevationGainM: 0, elevationLossM: 0,
            priority: .aRace, goalType: .targetTime(3 * 3600 + 30 * 60),
            checkpoints: [], terrainDifficulty: .easy, raceType: .road
        )
    }

    // MARK: - VMA computation

    @Test("VMA test 1500m / 6 min → VMA 15 km/h")
    func vmaComputation1500m() {
        let v = FitnessTestRecalibrator.computeMeasuredVMA(
            variant: .vmaFlat6Min,
            result: TestResultInput(distanceMeters: 1500)
        )
        #expect(v == 15.0)
    }

    @Test("VMA test 1400m → 14 km/h")
    func vmaComputation1400m() {
        let v = FitnessTestRecalibrator.computeMeasuredVMA(
            variant: .vmaFlat6Min,
            result: TestResultInput(distanceMeters: 1400)
        )
        #expect(v == 14.0)
    }

    @Test("5K TT 20:00 → ~15.46 km/h VMA equivalent")
    func fiveKTTtoVMA() {
        // 5K in 1200s → 15 km/h average → VMA = 15 / 0.97 ≈ 15.46
        let v = FitnessTestRecalibrator.computeMeasuredVMA(
            variant: .fiveKTT,
            result: TestResultInput(timeSeconds: 1200)
        )
        guard let v else { Issue.record("Expected non-nil VMA"); return }
        #expect(abs(v - 15.46) < 0.05, "Got \(v)")
    }

    @Test("Uphill / treadmill variants return nil VMA")
    func uphillVariantsNoVMA() {
        for variant: FitnessTestVariant in [
            .uphillSustained30Min, .uphillRepeats4x8,
            .uphillRepeats6x4, .treadmillIncline30Min
        ] {
            let v = FitnessTestRecalibrator.computeMeasuredVMA(
                variant: variant,
                result: TestResultInput(timeSeconds: 1800, averageHeartRate: 170)
            )
            #expect(v == nil, "\(variant) should not produce a VMA")
        }
    }

    // MARK: - Recommendation thresholds

    @Test("Delta < 5%: noChange")
    func smallDeltaNoChange() {
        let athlete = makeAthlete(vmaKmh: 14.0)
        let race = makeRace()
        // 14.5 km/h → ~3.6% delta
        let result = FitnessTestRecalibrator.recalibrate(
            testVariant: .vmaFlat6Min,
            result: TestResultInput(distanceMeters: 1450),
            athlete: athlete, targetRace: race,
            weeksUntilRace: 8, currentRacePhase: .build
        )
        if case .noChange = result.recommendation { } else {
            Issue.record("Expected noChange, got \(result.recommendation)")
        }
        #expect(result.updatedPaceProfile == nil)
    }

    @Test("Delta 5-7%: training paces only")
    func midDeltaTrainingOnly() {
        let athlete = makeAthlete(vmaKmh: 14.0)
        let race = makeRace()
        // 14.85 km/h → ~6% delta
        let result = FitnessTestRecalibrator.recalibrate(
            testVariant: .vmaFlat6Min,
            result: TestResultInput(distanceMeters: 1485),
            athlete: athlete, targetRace: race,
            weeksUntilRace: 8, currentRacePhase: .build
        )
        #expect(result.recommendation == .recalibrateTrainingPacesOnly)
        #expect(result.updatedPaceProfile != nil)
    }

    @Test("Delta ≥ 7% in build phase + ≥4 weeks remaining: recalibrate all")
    func largeDeltaBuildRecalibrateAll() {
        let athlete = makeAthlete(vmaKmh: 14.0)
        let race = makeRace()
        // 15.1 km/h → ~7.9% delta
        let result = FitnessTestRecalibrator.recalibrate(
            testVariant: .vmaFlat6Min,
            result: TestResultInput(distanceMeters: 1510),
            athlete: athlete, targetRace: race,
            weeksUntilRace: 8, currentRacePhase: .build
        )
        #expect(result.recommendation == .recalibrateAll)
        #expect(result.updatedPaceProfile != nil)
    }

    @Test("Delta ≥ 7% but in peak phase: training paces only (race target locked)")
    func largeDeltaPeakOnlyTraining() {
        let athlete = makeAthlete(vmaKmh: 14.0)
        let race = makeRace()
        let result = FitnessTestRecalibrator.recalibrate(
            testVariant: .vmaFlat6Min,
            result: TestResultInput(distanceMeters: 1510),
            athlete: athlete, targetRace: race,
            weeksUntilRace: 3, currentRacePhase: .peak
        )
        #expect(result.recommendation == .recalibrateTrainingPacesOnly)
    }

    @Test("Delta > 15%: suspicious — flag, don't auto-update")
    func suspiciousDelta() {
        let athlete = makeAthlete(vmaKmh: 14.0)
        let race = makeRace()
        // 16.5 km/h → ~17.9% delta
        let result = FitnessTestRecalibrator.recalibrate(
            testVariant: .vmaFlat6Min,
            result: TestResultInput(distanceMeters: 1650),
            athlete: athlete, targetRace: race,
            weeksUntilRace: 8, currentRacePhase: .build
        )
        #expect(result.recommendation == .suspicious)
        #expect(result.updatedPaceProfile == nil)
    }

    @Test("Sign of delta: regression also recalibrates")
    func regressionDelta() {
        let athlete = makeAthlete(vmaKmh: 14.0)
        let race = makeRace()
        // 13.0 km/h → -7.1% delta
        let result = FitnessTestRecalibrator.recalibrate(
            testVariant: .vmaFlat6Min,
            result: TestResultInput(distanceMeters: 1300),
            athlete: athlete, targetRace: race,
            weeksUntilRace: 8, currentRacePhase: .build
        )
        #expect(result.deltaPercent < 0)
        #expect(result.recommendation == .recalibrateAll
            || result.recommendation == .recalibrateTrainingPacesOnly)
    }

    @Test("Trail uphill variant: no auto-recalibration")
    func uphillNoAutoRecalibrate() {
        let athlete = makeAthlete(vmaKmh: 14.0)
        let race = makeRace()
        let result = FitnessTestRecalibrator.recalibrate(
            testVariant: .uphillSustained30Min,
            result: TestResultInput(timeSeconds: 1800, averageHeartRate: 168),
            athlete: athlete, targetRace: race,
            weeksUntilRace: 8, currentRacePhase: .build
        )
        if case .noChange = result.recommendation { } else {
            Issue.record("Uphill test should not auto-recalibrate")
        }
        #expect(result.updatedPaceProfile == nil)
    }

    @Test("5K TT result actually shifts derived 5K pace (not just vmaKmh)")
    func fiveKTTUpdatesDerivedPaces() {
        // Athlete with HM PR but no 5K PR. RoadPaceCalculator estimates
        // 5K via Riegel from HM. Test result must DOMINATE that and
        // produce different paces — otherwise the recalibration is
        // a no-op for athletes with stale PRs.
        var athlete = Athlete(
            id: UUID(), firstName: "Test", lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70, heightCm: 175,
            restingHeartRate: 50, maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 50, longestRunKm: 25,
            preferredUnit: .metric,
            trainingPhilosophy: .balanced,
            preferredRunsPerWeek: 5
        )
        // HM PR 1:48:00. Riegel-estimated 5K ≈ 23:39 → ~4:44/km
        athlete.personalBests = [PersonalBest(
            id: UUID(), distance: .halfMarathon,
            timeSeconds: 6480, date: .now.addingTimeInterval(-90 * 86400)
        )]
        athlete.vmaKmh = 14.0  // baseline anchor
        let race = makeRace()

        let originalProfile = RoadPaceCalculator.paceProfile(
            goalTime: 3 * 3600 + 30 * 60,
            raceDistanceKm: 42.195,
            personalBests: athlete.personalBests,
            vmaKmh: athlete.vmaKmh,
            experience: .intermediate
        )

        // Test: 5K TT in 20:00 → measured VMA 15.46 (~10% above 14.0).
        let result = FitnessTestRecalibrator.recalibrate(
            testVariant: .fiveKTT,
            result: TestResultInput(timeSeconds: 1200),
            athlete: athlete, targetRace: race,
            weeksUntilRace: 8, currentRacePhase: .build
        )
        guard let newProfile = result.updatedPaceProfile else {
            Issue.record("Expected an updated pace profile"); return
        }
        // The new profile's threshold pace should be FASTER (smaller
        // s/km) than the original. Threshold is the most stable
        // calibration target — interval pace can be noisy.
        let originalT = originalProfile.thresholdPacePerKm
        let newT = newProfile.thresholdPacePerKm
        #expect(newT < originalT,
            "New T pace (\(newT)) should be faster than original (\(originalT))")
    }

    @Test("No baseline VMA: accepts measured value, recalibrates training paces")
    func noBaselineVMA() {
        let athlete = makeAthlete(vmaKmh: nil)  // no VMA, no PRs
        let race = makeRace()
        let result = FitnessTestRecalibrator.recalibrate(
            testVariant: .vmaFlat6Min,
            result: TestResultInput(distanceMeters: 1500),
            athlete: athlete, targetRace: race,
            weeksUntilRace: 8, currentRacePhase: .build
        )
        #expect(result.measuredVmaKmh == 15.0)
        #expect(result.recommendation == .recalibrateTrainingPacesOnly)
    }
}
