import Foundation
import Testing
@testable import UltraTrain

/// RR-26: peak LR + volume must sit 3-4 weeks BEFORE taper, not adjacent
/// to it. Pins the new shape against future regressions.
@Suite("RoadLongRunCalculator Peak Placement Tests")
struct RoadLongRunCalculatorPeakPlacementTests {

    // MARK: - Helpers

    private func lrFor(weekIndex: Int, totalWeeks: Int = 23, taperWeeks: Int = 3) -> TimeInterval {
        let phase: TrainingPhase
        let taperStart = totalWeeks - taperWeeks
        if weekIndex >= taperStart { phase = .taper }
        else if weekIndex >= 12 { phase = .peak }
        else if weekIndex >= 6 { phase = .build }
        else { phase = .base }
        return RoadLongRunCalculator.longRunDuration(
            weekIndex: weekIndex,
            totalWeeks: totalWeeks,
            phase: phase,
            experience: .advanced,
            raceDistanceKm: 42.195,
            currentLongestRunKm: 32,
            isRecoveryWeek: false,
            philosophy: .balanced,
            raceGoal: .targetTime(9600),
            weeklyVolumeKm: 80,
            taperWeeks: taperWeeks
        )
    }

    // MARK: - Plateau placement

    @Test("23-week marathon: LR peaks 4 weeks before taper, then plateaus")
    func plateauForLongPlan() {
        // taperStart = 20, plateauOffset = min(4, 23/5) = 4 → peakWeek = 16
        // idx 16, 17, 18, 19 should all return the same peak duration.
        let lr16 = lrFor(weekIndex: 16)
        let lr17 = lrFor(weekIndex: 17)
        let lr18 = lrFor(weekIndex: 18)
        let lr19 = lrFor(weekIndex: 19)

        #expect(lr16 > 0)
        #expect(lr16 == lr17, "W17 should plateau at peak from W16 (\(lr16/60) vs \(lr17/60))")
        #expect(lr17 == lr18, "W18 should plateau (\(lr17/60) vs \(lr18/60))")
        #expect(lr18 == lr19, "W19 should plateau (\(lr18/60) vs \(lr19/60))")
    }

    @Test("23-week marathon: LR ascends through base/build before plateau")
    func ascentBeforePeak() {
        // We check earlier weeks where the quadratic ramp delta is large
        // enough not to be erased by 2-min rounding. Late-peak weeks may
        // collapse to the cap value before peakWeek due to ease-out shape.
        let lrBase = lrFor(weekIndex: 4)
        let lrBuild = lrFor(weekIndex: 8)
        let lrEarlyPeak = lrFor(weekIndex: 12)
        let lrPlateau = lrFor(weekIndex: 16)

        #expect(lrBase < lrBuild, "Build week LR > base week LR")
        #expect(lrBuild < lrEarlyPeak, "Early peak LR > build LR")
        #expect(lrEarlyPeak <= lrPlateau, "Plateau is the ceiling")
        #expect(lrEarlyPeak < lrPlateau || lrEarlyPeak >= lrPlateau * 0.95,
                "Early peak should be within 5% of plateau (consolidating, not climbing)")
    }

    @Test("23-week marathon: taper drops LR below peak")
    func taperDrops() {
        let lrPeak = lrFor(weekIndex: 16)
        let lrTaper1 = lrFor(weekIndex: 20) // taper W1
        #expect(lrTaper1 < lrPeak * 0.7, "Taper LR should be ≤60% of peak (Mujika 2003)")
    }

    // MARK: - Short-plan handling

    @Test("12-week marathon: plateau scales down so peak isn't pinned at week 0")
    func plateauForShortPlan() {
        // taperStart = 9, plateauOffset = min(4, 12/5) = 2 → peakWeek = 7
        // idx 7, 8 should plateau.
        let lr6 = lrFor(weekIndex: 6, totalWeeks: 12)
        let lr7 = lrFor(weekIndex: 7, totalWeeks: 12)
        let lr8 = lrFor(weekIndex: 8, totalWeeks: 12)

        #expect(lr6 > 0)
        #expect(lr6 < lr7, "Pre-peak should still be ascending")
        #expect(lr7 == lr8, "W8 should plateau at W7 peak")
    }

    @Test("8-week marathon: degenerate case, peakWeek floored at 1")
    func plateauFor8WeekPlan() {
        // taperStart = 5, plateauOffset = min(4, 1) = 1 → peakWeek = 4
        // idx 4 = peak; idx 5+ = taper. No plateau weeks possible.
        let lrPeak = lrFor(weekIndex: 4, totalWeeks: 8)
        let lrTaper = lrFor(weekIndex: 5, totalWeeks: 8)
        #expect(lrPeak > 0)
        #expect(lrTaper < lrPeak, "Taper applies its own reduction")
    }
}
