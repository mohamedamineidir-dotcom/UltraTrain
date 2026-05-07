import Foundation
import Testing
@testable import UltraTrain

/// T1+T2: Trail/ultra LR + base sessions must peak 3-4 weeks BEFORE
/// taper start, then plateau. Pre-fix the trail pipeline ramped both
/// monotonically up to the LAST non-taper week, sending the athlete
/// into taper carrying acute fatigue (Pfitzinger Ch. 9 antipattern).
@Suite("LongRunCurveCalculator Peak Placement Tests")
struct LongRunCurvePeakPlacementTests {

    private func taper(weeks: Int = 5) -> TaperProfile {
        // 5-week 100K-style taper.
        TaperProfile(
            totalTaperWeeks: 5,
            volumeTransitionWeeks: 2,
            weeklyVolumeFractions: [0.80, 0.65, 0.50, 0.40, 0.30],
            qualityAllowedPerWeek: [true, true, false, false, false]
        )
    }

    private func lrFor(
        weekIndex: Int,
        totalWeeks: Int = 24,
        taperProfile: TaperProfile? = nil
    ) -> TimeInterval {
        let tp = taperProfile ?? taper(weeks: 5)
        let phase: TrainingPhase
        let taperStart = totalWeeks - tp.totalTaperWeeks
        if weekIndex >= taperStart { phase = .taper }
        else if weekIndex >= totalWeeks * 6 / 10 { phase = .peak }
        else if weekIndex >= totalWeeks * 3 / 10 { phase = .build }
        else { phase = .base }
        return LongRunCurveCalculator.longRunDuration(
            weekIndex: weekIndex,
            totalWeeks: totalWeeks,
            phase: phase,
            experience: .advanced,
            philosophy: .balanced,
            raceGoal: .targetTime(36000),
            preferredRunsPerWeek: 6,
            raceEffectiveKm: 165,    // 100K + 6500m D+ ≈ 165 effective km
            currentWeeklyVolumeKm: 80,
            raceDurationSeconds: 36000,
            taperProfile: tp,
            athleteAge: 35
        )
    }

    // MARK: - Peak placement

    @Test("24-week 100K ultra: LR peaks ≥3 weeks before taper, then plateaus")
    func longPlanLRPlateau() {
        // taperStart = 19, plateauOffset = min(4, 24/5) = 4 → peakWeek = 14
        // Indices 14-18 (5 weeks) should plateau at peak; index 19+ taper.
        let lrPeakWeek = LongRunCurveCalculator.peakBuildWeekIndex(
            totalWeeks: 24, taperProfile: taper(weeks: 5)
        )
        #expect(lrPeakWeek == 14, "Expected peakWeek=14 for 24wk plan with 5-wk taper, got \(lrPeakWeek)")

        let lr14 = lrFor(weekIndex: 14)
        let lr15 = lrFor(weekIndex: 15)
        let lr16 = lrFor(weekIndex: 16)
        let lr18 = lrFor(weekIndex: 18)

        #expect(lr14 > 0)
        #expect(lr14 == lr15, "W15 plateau matches peak (\(lr14/60) vs \(lr15/60))")
        #expect(lr15 == lr16, "W16 plateau matches peak")
        #expect(lr16 == lr18, "W18 (last non-taper) still at peak, not above it")
    }

    @Test("24-week ultra: LR ramps through base/build before plateau")
    func ascentBeforePeak() {
        let lrEarlyBase = lrFor(weekIndex: 2)
        let lrLateBuild = lrFor(weekIndex: 10)
        let lrPlateau = lrFor(weekIndex: 14)

        #expect(lrEarlyBase < lrLateBuild, "Build LR > base LR")
        #expect(lrLateBuild < lrPlateau || lrLateBuild >= lrPlateau * 0.95,
                "Late build either rising toward peak or already within 5% of it")
        #expect(lrPlateau >= lrLateBuild, "Plateau is the ceiling")
    }

    @Test("Peak LR is NOT pinned at the last non-taper week")
    func peakIsNotAdjacentToTaper() {
        // The bug we're fixing: pre-fix, the LR reached its absolute max at
        // weekIndex == buildWeekCount - 1 (= 18 here). Post-fix, multiple
        // weeks before that should ALSO be at peak.
        let lrLastBuild = lrFor(weekIndex: 18)
        let lrThreeBefore = lrFor(weekIndex: 15)
        #expect(lrLastBuild == lrThreeBefore,
                "Pre-fix: lrLastBuild > lrThreeBefore (monotonic). Post-fix: equal (plateau).")
    }

    // MARK: - Short-plan handling

    @Test("12-week 50K plan: plateau scales down so peak isn't pinned at week 0")
    func shortPlanPeakWeek() {
        let tp = TaperProfile(
            totalTaperWeeks: 2,
            volumeTransitionWeeks: 1,
            weeklyVolumeFractions: [0.65, 0.37],
            qualityAllowedPerWeek: [true, false]
        )
        // taperStart = 10, plateauOffset = min(4, 12/5) = 2 → peakWeek = 7
        let pw = LongRunCurveCalculator.peakBuildWeekIndex(totalWeeks: 12, taperProfile: tp)
        #expect(pw == 7, "Expected peakWeek=7 for 12wk plan with 2-wk taper, got \(pw)")
    }

    // MARK: - Base session plateau (T2)

    @Test("Base session durations also plateau before taper, not climb to last week")
    func baseSessionPlateau() {
        let tp = taper(weeks: 5)
        let weeks = (12...18).map { idx -> LongRunCurveCalculator.WeekDurations in
            LongRunCurveCalculator.durations(
                weekIndex: idx,
                totalWeeks: 24,
                phase: .peak,
                isRecoveryWeek: false,
                experience: .advanced,
                philosophy: .balanced,
                raceGoal: .targetTime(36000),
                raceDurationSeconds: 36000,
                raceEffectiveKm: 165,
                preferredRunsPerWeek: 6,
                currentWeeklyVolumeKm: 80,
                taperProfile: tp,
                athleteAge: 35
            )
        }
        // From W14 (peakWeek) onwards the underlying `baseSessionProgress`
        // is constant at 1.0. B2B weeks have their own intervalSeconds=0
        // override and recalibrate VG/easy from a supportingBudget, so we
        // check only NON-B2B plateau weeks for invariance — these share
        // a code path that depends purely on baseSessionProgress.
        let plateau = Array(weeks.suffix(from: 2)) // idx 14, 15, 16, 17, 18
        let nonB2B = plateau.filter { !$0.isB2B }
        guard nonB2B.count >= 2 else {
            Issue.record("Test setup needs ≥2 non-B2B weeks in the plateau")
            return
        }
        let easy1Set = Set(nonB2B.map { Int($0.easyRun1Seconds) })
        let easy2Set = Set(nonB2B.map { Int($0.easyRun2Seconds) })
        let intervalSet = Set(nonB2B.map { Int($0.intervalSeconds) })
        let vgSet = Set(nonB2B.map { Int($0.vgSeconds) })
        #expect(easy1Set.count == 1, "non-B2B easy1 flat, got \(easy1Set)")
        #expect(easy2Set.count == 1, "non-B2B easy2 flat, got \(easy2Set)")
        #expect(intervalSet.count == 1, "non-B2B interval flat, got \(intervalSet)")
        #expect(vgSet.count == 1, "non-B2B vg flat, got \(vgSet)")
    }

    @Test("Pre-fix would have shown LR ascending into taper boundary; post-fix it doesn't")
    func regressionGuard() {
        // For idx 11 (mid-build) vs idx 18 (last non-taper), pre-fix LR
        // would be strictly increasing (monotonic). Post-fix, idx 18 == peak
        // (set at idx 14). Regression test: if someone reverts the plateau,
        // this test breaks.
        let lrMid = lrFor(weekIndex: 11)
        let lrLast = lrFor(weekIndex: 18)
        let lrPeak = lrFor(weekIndex: 14)
        #expect(lrLast == lrPeak, "Last non-taper week is at peak, not above it")
        #expect(lrMid <= lrPeak, "Mid-build never exceeds peak")
    }
}
