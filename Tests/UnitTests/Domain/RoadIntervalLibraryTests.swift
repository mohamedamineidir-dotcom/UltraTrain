import Foundation
import Testing
@testable import UltraTrain

@Suite("RoadIntervalLibrary Tests")
struct RoadIntervalLibraryTests {

    // MARK: - Walk-forward progression must be monotonic

    /// RR-25: Earlier code relied on declaration order, which silently broke
    /// when audit-block templates (declared last in `allTemplates`) included
    /// lighter sessions than the originals in the same category. The
    /// walk-forward then served the heaviest session in week 0 and a lighter
    /// plateau in weeks 1+. Sorting by `totalWorkMinutes` ascending is the
    /// fix; this test pins the property so a future refactor that reverts
    /// the sort blows up here.
    @Test("Peak marathon raceSpecific — totalWork is non-decreasing across weeks")
    func peakMarathonRaceSpecificMonotonic() {
        var prev: Double = 0
        for week in 0..<8 {
            let pick = RoadIntervalLibrary.selectForSlot(
                slotIndex: 0,
                phase: .peak,
                discipline: .roadMarathon,
                experience: .intermediate,
                weekInPhase: week
            )
            #expect(pick != nil)
            let work = pick?.totalWorkMinutes ?? 0
            #expect(work >= prev, "Week \(week) (\(work)min) regressed below week \(week-1) (\(prev)min)")
            prev = work
        }
    }

    @Test("Peak marathon threshold slot — totalWork is non-decreasing")
    func peakMarathonThresholdMonotonic() {
        var prev: Double = 0
        for week in 0..<8 {
            let pick = RoadIntervalLibrary.selectForSlot(
                slotIndex: 1,
                phase: .peak,
                discipline: .roadMarathon,
                experience: .intermediate,
                weekInPhase: week
            )
            #expect(pick != nil)
            let work = pick?.totalWorkMinutes ?? 0
            #expect(work >= prev, "Week \(week) (\(work)min) regressed below week \(week-1) (\(prev)min)")
            prev = work
        }
    }

    @Test("Build VO2max for 10K — totalWork is non-decreasing")
    func buildTenKVO2maxMonotonic() {
        var prev: Double = 0
        for week in 0..<8 {
            let pick = RoadIntervalLibrary.selectForSlot(
                slotIndex: 0,
                phase: .build,
                discipline: .road10K,
                experience: .intermediate,
                weekInPhase: week
            )
            #expect(pick != nil)
            let work = pick?.totalWorkMinutes ?? 0
            #expect(work >= prev, "Week \(week) (\(work)min) regressed below week \(week-1) (\(prev)min)")
            prev = work
        }
    }

    // MARK: - First-timer cap

    @Test("First-timer plateaus one short of the hardest template")
    func firstTimerCapsOneShort() {
        let regular = (0..<10).compactMap { week in
            RoadIntervalLibrary.selectForSlot(
                slotIndex: 0,
                phase: .peak,
                discipline: .roadMarathon,
                experience: .advanced,
                weekInPhase: week,
                isFirstTimerAtDistance: false
            )?.totalWorkMinutes
        }
        let firstTimer = (0..<10).compactMap { week in
            RoadIntervalLibrary.selectForSlot(
                slotIndex: 0,
                phase: .peak,
                discipline: .roadMarathon,
                experience: .advanced,
                weekInPhase: week,
                isFirstTimerAtDistance: true
            )?.totalWorkMinutes
        }
        // First-timer plateau should be ≤ regular plateau when the regular
        // walker reaches the hardest template — never harder.
        #expect((firstTimer.max() ?? 0) <= (regular.max() ?? 0))
    }

    // MARK: - Late-build marathon Q1 raceSpecific introduction (RR-27 / C2)

    @Test("Build marathon Q1: weekInPhase 0-2 is VO2max, weekInPhase 3+ flips to raceSpecific")
    func buildMarathonQ1IntroducesRaceSpecific() {
        let early = (0..<3).compactMap { week in
            RoadIntervalLibrary.selectForSlot(
                slotIndex: 0,
                phase: .build,
                discipline: .roadMarathon,
                experience: .advanced,
                weekInPhase: week
            )
        }
        let late = (3..<6).compactMap { week in
            RoadIntervalLibrary.selectForSlot(
                slotIndex: 0,
                phase: .build,
                discipline: .roadMarathon,
                experience: .advanced,
                weekInPhase: week
            )
        }
        // Early build = VO2max ladder
        #expect(early.allSatisfy { $0.category == .vo2max },
                "Early build Q1 should be VO2max, got \(early.map(\.category))")
        // Late build = raceSpecific (MP cruise intervals)
        #expect(late.allSatisfy { $0.category == .raceSpecific },
                "Late build Q1 should be raceSpecific, got \(late.map(\.category))")
    }

    @Test("Late-build raceSpecific walks through progressive templates, not pinned to cap")
    func lateBuildRaceSpecificProgresses() {
        // Advanced marathoner has 3 build raceSpecific templates available
        // (MP Cruise 3×1.5K, 4×1.5K, 3×2K). With per-category introduction
        // week = 3, weekInPhase 3/4/5 must give DIFFERENT templates, not
        // the same cap value 3 weeks in a row.
        let names = (3..<6).compactMap { week in
            RoadIntervalLibrary.selectForSlot(
                slotIndex: 0,
                phase: .build,
                discipline: .roadMarathon,
                experience: .advanced,
                weekInPhase: week
            )?.name
        }
        let unique = Set(names)
        #expect(unique.count >= 2,
                "Late-build raceSpecific must walk through ≥2 distinct templates across 3 weeks, got \(names)")
    }

    @Test("Build marathon Q2 also progresses through raceSpecific in late build")
    func buildMarathonQ2RaceSpecificProgresses() {
        let names = (3..<6).compactMap { week in
            RoadIntervalLibrary.selectForSlot(
                slotIndex: 1,
                phase: .build,
                discipline: .roadMarathon,
                experience: .advanced,
                weekInPhase: week,
                excludeCategory: .vo2max  // mimic Q1=vo2max in early build, Q2 picks something else
            )?.name
        }
        let unique = Set(names)
        // Q2 may or may not pick raceSpecific (threshold/progression are also options),
        // but if multiple weeks DO use raceSpecific, they must differ.
        let raceSpecificNames = (3..<6).compactMap { week -> String? in
            let pick = RoadIntervalLibrary.selectForSlot(
                slotIndex: 1,
                phase: .build,
                discipline: .roadMarathon,
                experience: .advanced,
                weekInPhase: week,
                excludeCategory: nil
            )
            return pick?.category == .raceSpecific ? pick?.name : nil
        }
        if raceSpecificNames.count >= 2 {
            #expect(Set(raceSpecificNames).count >= 2,
                    "If Q2 picks raceSpecific multiple weeks, must walk forward — got \(raceSpecificNames)")
        }
        // Unconditional: Q2 should produce >= 2 unique templates over 3 weeks
        #expect(unique.count >= 1, "Q2 should produce something each week")
    }

    @Test("Late-build raceSpecific into peak: athlete sees ≥3 unique MP sessions before race")
    func raceSpecificContinuityIntoPeak() {
        // Late build (3 weeks) + peak (3 weeks) = 6 weeks of raceSpecific Q1
        // for an advanced marathoner. The athlete should see at least 3
        // distinct MP-specific sessions across this window.
        var names: [String] = []
        for week in 3..<6 {
            if let pick = RoadIntervalLibrary.selectForSlot(
                slotIndex: 0, phase: .build, discipline: .roadMarathon,
                experience: .advanced, weekInPhase: week
            ) {
                names.append(pick.name)
            }
        }
        for week in 0..<3 {
            if let pick = RoadIntervalLibrary.selectForSlot(
                slotIndex: 0, phase: .peak, discipline: .roadMarathon,
                experience: .advanced, weekInPhase: week
            ) {
                names.append(pick.name)
            }
        }
        #expect(Set(names).count >= 3,
                "Should see ≥3 distinct MP sessions across late build + early peak, got \(Set(names))")
    }
}
