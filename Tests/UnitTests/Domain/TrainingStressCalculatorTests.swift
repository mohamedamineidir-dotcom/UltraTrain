import Foundation
import Testing
@testable import UltraTrain

@Suite("Training Stress Calculator Tests")
struct TrainingStressCalculatorTests {

    private let maxHeartRate = 200
    private let restingHeartRate = 50

    // MARK: - Helpers

    private func makeTrackWithHR(
        durationMinutes: Int,
        heartRate: Int,
        intervalSeconds: Int = 5
    ) -> [TrackPoint] {
        var points: [TrackPoint] = []
        let start = Date.now
        let count = (durationMinutes * 60) / intervalSeconds
        for i in 0...count {
            points.append(TrackPoint(
                latitude: 45.0,
                longitude: 6.0,
                altitudeM: 1000,
                timestamp: start.addingTimeInterval(TimeInterval(i * intervalSeconds)),
                heartRate: heartRate
            ))
        }
        return points
    }

    private func makeTrackNoHR(
        durationMinutes: Int,
        intervalSeconds: Int = 5
    ) -> [TrackPoint] {
        var points: [TrackPoint] = []
        let start = Date.now
        let count = (durationMinutes * 60) / intervalSeconds
        for i in 0...count {
            points.append(TrackPoint(
                latitude: 45.0,
                longitude: 6.0,
                altitudeM: 1000,
                timestamp: start.addingTimeInterval(TimeInterval(i * intervalSeconds)),
                heartRate: nil
            ))
        }
        return points
    }

    private func makeRun(
        distanceKm: Double = 10,
        elevationGainM: Double = 200,
        duration: TimeInterval = 3600,
        gpsTrack: [TrackPoint] = [],
        rpe: Int? = nil,
        trainingStressScore: Double? = nil
    ) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: .now,
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            elevationLossM: 180,
            duration: duration,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: gpsTrack,
            splits: [],
            linkedSessionId: nil,
            notes: nil,
            pausedDuration: 0,
            rpe: rpe,
            trainingStressScore: trainingStressScore
        )
    }

    // MARK: - hrTSS Tests

    @Test("No HR data returns nil")
    func testHRTSS_noHRData_returnsNil() {
        let track = makeTrackNoHR(durationMinutes: 60)
        let result = TrainingStressCalculator.calculateHRTSS(
            gpsTrack: track,
            maxHeartRate: maxHeartRate,
            restingHeartRate: restingHeartRate
        )
        #expect(result == nil)
    }

    @Test("Less than 5 minutes of HR data returns nil")
    func testHRTSS_lessThan5MinHR_returnsNil() {
        let track = makeTrackWithHR(durationMinutes: 3, heartRate: 170)
        let result = TrainingStressCalculator.calculateHRTSS(
            gpsTrack: track,
            maxHeartRate: maxHeartRate,
            restingHeartRate: restingHeartRate
        )
        #expect(result == nil)
    }

    @Test("60 min at zone 4 (85% maxHR) gives approximately 100 TSS")
    func testHRTSS_60MinAllZ4_approximately100() {
        // 85% of 200 = 170 → zone 4 (80-90%), factor 3.0
        // weightedScore = 60 * 3.0 = 180
        // tss = 180 / (60 * 3.0) * 100 = 100
        let track = makeTrackWithHR(durationMinutes: 60, heartRate: 170)
        let result = TrainingStressCalculator.calculateHRTSS(
            gpsTrack: track,
            maxHeartRate: maxHeartRate,
            restingHeartRate: restingHeartRate
        )
        #expect(result != nil)
        #expect(abs(result! - 100.0) < 5.0)
    }

    @Test("60 min at zone 1 (55% maxHR) gives much less than 100 TSS")
    func testHRTSS_60MinAllZ1_muchLessThan100() {
        // 55% of 200 = 110 → zone 1 (<60%), factor 1.0
        // weightedScore = 60 * 1.0 = 60
        // tss = 60 / (60 * 3.0) * 100 = 33.3
        let track = makeTrackWithHR(durationMinutes: 60, heartRate: 110)
        let result = TrainingStressCalculator.calculateHRTSS(
            gpsTrack: track,
            maxHeartRate: maxHeartRate,
            restingHeartRate: restingHeartRate
        )
        #expect(result != nil)
        #expect(abs(result! - 33.3) < 5.0)
    }

    @Test("60 min at zone 5 (95% maxHR) gives more than 100 TSS")
    func testHRTSS_60MinAllZ5_moreThan100() {
        // 95% of 200 = 190 → zone 5 (>=90%), factor 5.0
        // weightedScore = 60 * 5.0 = 300
        // tss = 300 / (60 * 3.0) * 100 = 166.7
        let track = makeTrackWithHR(durationMinutes: 60, heartRate: 190)
        let result = TrainingStressCalculator.calculateHRTSS(
            gpsTrack: track,
            maxHeartRate: maxHeartRate,
            restingHeartRate: restingHeartRate
        )
        #expect(result != nil)
        #expect(abs(result! - 166.7) < 5.0)
    }

    @Test("TSS scales with duration — 30 min at Z4 is approximately half of 60 min at Z4")
    func testHRTSS_scalesWithDuration() {
        let track60 = makeTrackWithHR(durationMinutes: 60, heartRate: 170)
        let track30 = makeTrackWithHR(durationMinutes: 30, heartRate: 170)

        let tss60 = TrainingStressCalculator.calculateHRTSS(
            gpsTrack: track60,
            maxHeartRate: maxHeartRate,
            restingHeartRate: restingHeartRate
        )
        let tss30 = TrainingStressCalculator.calculateHRTSS(
            gpsTrack: track30,
            maxHeartRate: maxHeartRate,
            restingHeartRate: restingHeartRate
        )

        #expect(tss60 != nil)
        #expect(tss30 != nil)
        let ratio = tss30! / tss60!
        #expect(abs(ratio - 0.5) < 0.1)
    }

    @Test("Custom thresholds change zone classification")
    func testHRTSS_usesCustomThresholds() {
        // With custom thresholds [100, 130, 160, 180]:
        // HR 170 → zone 4 (between 160 and 180), factor 3.0
        // With default zones: HR 170 = 85% of 200 → zone 4 (80-90%), factor 3.0
        // Now use thresholds that would shift HR 170 to zone 3:
        // [100, 130, 175, 190] → HR 170 <= 175 → zone 3, factor 2.0
        let track = makeTrackWithHR(durationMinutes: 60, heartRate: 170)

        let tssDefault = TrainingStressCalculator.calculateHRTSS(
            gpsTrack: track,
            maxHeartRate: maxHeartRate,
            restingHeartRate: restingHeartRate,
            customThresholds: nil
        )

        let tssCustom = TrainingStressCalculator.calculateHRTSS(
            gpsTrack: track,
            maxHeartRate: maxHeartRate,
            restingHeartRate: restingHeartRate,
            customThresholds: [100, 130, 175, 190]
        )

        #expect(tssDefault != nil)
        #expect(tssCustom != nil)
        // Custom thresholds put HR 170 in zone 3 (factor 2.0) instead of zone 4 (factor 3.0)
        #expect(tssCustom! < tssDefault!)
    }

    // MARK: - rpeTSS Tests

    @Test("Invalid RPE returns zero")
    func testRPETSS_invalidRPE_returnsZero() {
        let resultZero = TrainingStressCalculator.calculateRPETSS(durationMinutes: 60, rpe: 0)
        let resultEleven = TrainingStressCalculator.calculateRPETSS(durationMinutes: 60, rpe: 11)
        #expect(resultZero == 0)
        #expect(resultEleven == 0)
    }

    @Test("60 min at RPE 8 gives approximately 100 TSS")
    func testRPETSS_60MinRPE8_approximately100() {
        // rpeNormalized = 8/10 = 0.8, intensityFactor = 0.64
        // scaleFactor = 100 / (60 * 0.64) = 2.604...
        // tss = 60 * 0.64 * 2.604 = ~100
        let result = TrainingStressCalculator.calculateRPETSS(durationMinutes: 60, rpe: 8)
        #expect(abs(result - 100.0) < 1.0)
    }

    @Test("RPE scales quadratically — RPE 4 gives less than half of RPE 8")
    func testRPETSS_scalesQuadratically() {
        let tssRPE8 = TrainingStressCalculator.calculateRPETSS(durationMinutes: 60, rpe: 8)
        let tssRPE4 = TrainingStressCalculator.calculateRPETSS(durationMinutes: 60, rpe: 4)
        // RPE 4: (0.4)^2 = 0.16, RPE 8: (0.8)^2 = 0.64 → ratio = 0.25 (a quarter, not half)
        #expect(tssRPE4 < tssRPE8 * 0.5)
    }

    // MARK: - Combined Tests

    @Test("Combined prefers HR-based TSS when HR data is available")
    func testCombined_prefersHRTSS() {
        let track = makeTrackWithHR(durationMinutes: 60, heartRate: 170)
        let run = makeRun(
            duration: 3600,
            gpsTrack: track,
            rpe: 5
        )

        let hrTSS = TrainingStressCalculator.calculateHRTSS(
            gpsTrack: track,
            maxHeartRate: maxHeartRate,
            restingHeartRate: restingHeartRate
        )!

        let combined = TrainingStressCalculator.calculate(
            run: run,
            maxHeartRate: maxHeartRate,
            restingHeartRate: restingHeartRate
        )

        #expect(abs(combined - hrTSS) < 0.001)
    }

    @Test("Combined falls back to RPE-based TSS when no HR data")
    func testCombined_fallsBackToRPETSS() {
        let track = makeTrackNoHR(durationMinutes: 60)
        let run = makeRun(
            duration: 3600,
            gpsTrack: track,
            rpe: 7
        )

        let rpeTSS = TrainingStressCalculator.calculateRPETSS(durationMinutes: 60, rpe: 7)

        let combined = TrainingStressCalculator.calculate(
            run: run,
            maxHeartRate: maxHeartRate,
            restingHeartRate: restingHeartRate
        )

        #expect(abs(combined - rpeTSS) < 0.001)
    }

    @Test("Combined falls back to effort distance when no HR and no RPE")
    func testCombined_fallsBackToEffortDistance() {
        let run = makeRun(
            distanceKm: 15,
            elevationGainM: 500,
            duration: 3600,
            gpsTrack: [],
            rpe: nil
        )

        let combined = TrainingStressCalculator.calculate(
            run: run,
            maxHeartRate: maxHeartRate,
            restingHeartRate: restingHeartRate
        )

        // distanceKm + elevationGainM / 100 = 15 + 5 = 20
        #expect(abs(combined - 20.0) < 0.001)
    }
}
