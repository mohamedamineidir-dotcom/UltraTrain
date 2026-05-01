import Foundation
import Testing
@testable import UltraTrain

@Suite("IntermediateRaceHandler Tests")
struct IntermediateRaceHandlerTests {

    // MARK: - Helpers

    /// Creates a week skeleton with a specific week number and date range.
    /// Each week starts on Monday and ends on Sunday, offset from a fixed base date.
    private func makeSkeleton(
        weekNumber: Int,
        phase: TrainingPhase = .build,
        isRecovery: Bool = false
    ) -> WeekSkeletonBuilder.WeekSkeleton {
        let calendar = Calendar.current
        var baseComponents = DateComponents()
        baseComponents.year = 2026
        baseComponents.month = 6
        baseComponents.day = 1 // Monday
        let baseDate = calendar.date(from: baseComponents)!
        let start = baseDate.addingTimeInterval(TimeInterval((weekNumber - 1) * 7 * 86400))
        let end = start.addingTimeInterval(6 * 86400)
        return WeekSkeletonBuilder.WeekSkeleton(
            weekNumber: weekNumber,
            startDate: start,
            endDate: end,
            phase: phase,
            isRecoveryWeek: isRecovery,
            phaseFocus: phase.defaultFocus
        )
    }

    /// Creates an array of contiguous week skeletons spanning the given range.
    private func makeSkeletons(
        weekRange: ClosedRange<Int>,
        phase: TrainingPhase = .build
    ) -> [WeekSkeletonBuilder.WeekSkeleton] {
        weekRange.map { makeSkeleton(weekNumber: $0, phase: phase) }
    }

    /// Creates a Race with the given priority and date.
    /// The date defaults to Wednesday of the given week number.
    private func makeRace(
        priority: RacePriority,
        weekNumber: Int,
        id: UUID = UUID()
    ) -> Race {
        let calendar = Calendar.current
        var baseComponents = DateComponents()
        baseComponents.year = 2026
        baseComponents.month = 6
        baseComponents.day = 1
        let baseDate = calendar.date(from: baseComponents)!
        // Place race on Wednesday (offset +2 days from Monday start of the week)
        let raceDate = baseDate.addingTimeInterval(
            TimeInterval((weekNumber - 1) * 7 * 86400 + 2 * 86400)
        )
        return Race(
            id: id,
            name: "\(priority.rawValue) Race",
            date: raceDate,
            distanceKm: 50,
            elevationGainM: 3000,
            elevationLossM: 3000,
            priority: priority,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .moderate
        )
    }

    // MARK: - B-Race: Mini-Taper

    @Test("B-race produces mini-taper override on preceding week")
    func bRaceMiniTaper() {
        let skeletons = makeSkeletons(weekRange: 1...6)
        let bRace = makeRace(priority: .bRace, weekNumber: 4)

        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: [bRace]
        )

        let taperOverride = overrides.first { $0.behavior == .miniTaper }
        #expect(taperOverride != nil, "B-race should produce a mini-taper override")
        #expect(taperOverride?.weekNumber == 3, "Mini-taper should be on the week before the race")
        #expect(taperOverride?.raceId == bRace.id)
    }

    @Test("B-race produces race week override")
    func bRaceWeekOverride() {
        let skeletons = makeSkeletons(weekRange: 1...6)
        let bRace = makeRace(priority: .bRace, weekNumber: 4)

        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: [bRace]
        )

        let raceWeek = overrides.first { $0.behavior == .raceWeek(priority: .bRace) }
        #expect(raceWeek != nil, "B-race should produce a race week override")
        #expect(raceWeek?.weekNumber == 4)
        #expect(raceWeek?.raceId == bRace.id)
    }

    // MARK: - B-Race: Post-Race Recovery

    @Test("B-race produces post-race recovery override on following week")
    func bRacePostRaceRecovery() {
        let skeletons = makeSkeletons(weekRange: 1...6)
        let bRace = makeRace(priority: .bRace, weekNumber: 4)

        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: [bRace]
        )

        let recovery = overrides.first { $0.behavior == .postRaceRecovery }
        #expect(recovery != nil, "B-race should produce a post-race recovery override")
        #expect(recovery?.weekNumber == 5, "Recovery should be on the week after the race")
        #expect(recovery?.raceId == bRace.id)
    }

    @Test("B-race produces taper, race week, and distance-scaled recovery weeks")
    func bRaceProducesExpectedOverrides() {
        // makeRace defaults to 50km — per RR-23, that triggers 3 post-race
        // recovery weeks. So the override sequence is:
        //   week 4: miniTaper
        //   week 5: raceWeek
        //   weeks 6, 7, 8: postRaceRecovery × 3
        let skeletons = makeSkeletons(weekRange: 1...8)
        let bRace = makeRace(priority: .bRace, weekNumber: 5)

        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: [bRace]
        )

        #expect(overrides.count == 5, "B-race at 50km produces taper + race + 3 recoveries")
        #expect(overrides[0].behavior == .miniTaper)
        #expect(overrides[0].weekNumber == 4)
        #expect(overrides[1].behavior == .raceWeek(priority: .bRace))
        #expect(overrides[1].weekNumber == 5)
        #expect(overrides[2].behavior == .postRaceRecovery)
        #expect(overrides[2].weekNumber == 6)
        #expect(overrides[2].weekInRecovery == 1)
        #expect(overrides[3].behavior == .postRaceRecovery)
        #expect(overrides[3].weekNumber == 7)
        #expect(overrides[3].weekInRecovery == 2)
        #expect(overrides[4].behavior == .postRaceRecovery)
        #expect(overrides[4].weekNumber == 8)
        #expect(overrides[4].weekInRecovery == 3)
    }

    // MARK: - C-Race: Lighter Treatment

    @Test("C-race produces only a race week override, no taper or recovery")
    func cRaceOnlyRaceWeek() {
        let skeletons = makeSkeletons(weekRange: 1...6)
        let cRace = makeRace(priority: .cRace, weekNumber: 3)

        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: [cRace]
        )

        #expect(overrides.count == 1, "C-race should produce exactly 1 override")
        #expect(overrides[0].behavior == .raceWeek(priority: .cRace))
        #expect(overrides[0].weekNumber == 3)
    }

    @Test("C-race does not produce mini-taper")
    func cRaceNoMiniTaper() {
        let skeletons = makeSkeletons(weekRange: 1...6)
        let cRace = makeRace(priority: .cRace, weekNumber: 4)

        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: [cRace]
        )

        let taperOverrides = overrides.filter { $0.behavior == .miniTaper }
        #expect(taperOverrides.isEmpty, "C-race should not produce a mini-taper")
    }

    @Test("C-race does not produce post-race recovery")
    func cRaceNoRecovery() {
        let skeletons = makeSkeletons(weekRange: 1...6)
        let cRace = makeRace(priority: .cRace, weekNumber: 4)

        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: [cRace]
        )

        let recoveryOverrides = overrides.filter { $0.behavior == .postRaceRecovery }
        #expect(recoveryOverrides.isEmpty, "C-race should not produce a post-race recovery")
    }

    // MARK: - A-Race Filtering

    @Test("A-race intermediate gets enhanced taper + recovery (two-A-race seasons)")
    func aRaceIntermediateOverrides() {
        // Two-A-race season change: an A-race scheduled before the
        // target A-race gets full peak treatment — 2-week taper and
        // 2-3 weeks of post-race recovery — instead of being silently
        // dropped. Allows spring + fall marathons, UTMB + CCC, etc.
        let skeletons = makeSkeletons(weekRange: 1...10)
        // 50 km race → 3 weeks recovery
        let aRace = makeRace(priority: .aRace, weekNumber: 5)

        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: [aRace]
        )

        let taperOverrides = overrides.filter { $0.behavior == .miniTaper }
        let raceWeekOverrides = overrides.filter { $0.behavior.isRaceWeek }
        let recoveryOverrides = overrides.filter { $0.behavior == .postRaceRecovery }

        #expect(taperOverrides.count == 2,
                "A-race intermediate should produce 2 weeks of taper, got \(taperOverrides.count)")
        #expect(raceWeekOverrides.count == 1,
                "A-race intermediate should produce exactly 1 race week override")
        #expect(recoveryOverrides.count == 3,
                "A-race intermediate at 50 km should produce 3 weeks of recovery, got \(recoveryOverrides.count)")
    }

    // MARK: - Edge Cases

    @Test("no intermediate races produces empty overrides")
    func noIntermediateRaces() {
        let skeletons = makeSkeletons(weekRange: 1...10)

        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: []
        )

        #expect(overrides.isEmpty)
    }

    @Test("B-race in first week has no taper (no preceding week available)")
    func bRaceFirstWeekNoTaper() {
        let skeletons = makeSkeletons(weekRange: 1...6)
        let bRace = makeRace(priority: .bRace, weekNumber: 1)

        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: [bRace]
        )

        let taperOverrides = overrides.filter { $0.behavior == .miniTaper }
        #expect(taperOverrides.isEmpty, "B-race in first week should not produce taper since there is no preceding week")

        // Should still have race week and recovery
        let raceWeek = overrides.first { $0.behavior == .raceWeek(priority: .bRace) }
        let recovery = overrides.first { $0.behavior == .postRaceRecovery }
        #expect(raceWeek != nil)
        #expect(recovery != nil)
    }

    @Test("B-race in last week has no recovery (no following week available)")
    func bRaceLastWeekNoRecovery() {
        let skeletons = makeSkeletons(weekRange: 1...6)
        let bRace = makeRace(priority: .bRace, weekNumber: 6)

        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: [bRace]
        )

        let recoveryOverrides = overrides.filter { $0.behavior == .postRaceRecovery }
        #expect(recoveryOverrides.isEmpty, "B-race in last week should not produce recovery since there is no following week")

        // Should still have taper and race week
        let taper = overrides.first { $0.behavior == .miniTaper }
        let raceWeek = overrides.first { $0.behavior == .raceWeek(priority: .bRace) }
        #expect(taper != nil)
        #expect(raceWeek != nil)
    }

    @Test("race outside skeleton date range produces no overrides")
    func raceOutsideDateRange() {
        let skeletons = makeSkeletons(weekRange: 1...4)
        // Place race in week 10, which is far outside the skeleton range
        let bRace = makeRace(priority: .bRace, weekNumber: 10)

        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: [bRace]
        )

        #expect(overrides.isEmpty, "Race outside skeleton range should produce no overrides")
    }

    // MARK: - Multiple Races

    @Test("multiple intermediate races produce correct combined overrides")
    func multipleIntermediateRaces() {
        let skeletons = makeSkeletons(weekRange: 1...12)
        let bRace = makeRace(priority: .bRace, weekNumber: 4)
        let cRace = makeRace(priority: .cRace, weekNumber: 8)

        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: [bRace, cRace]
        )

        // B-race at 50km: taper (week 3) + race (week 4) + 3 recoveries (RR-23)
        // C-race at 50km: race (week 8) only — C-races get no taper/recovery
        #expect(overrides.count == 6, "5 for B-race + 1 for C-race")

        let bRaceOverrides = overrides.filter { $0.raceId == bRace.id }
        let cRaceOverrides = overrides.filter { $0.raceId == cRace.id }
        #expect(bRaceOverrides.count == 5)
        #expect(cRaceOverrides.count == 1)
    }

    @Test("races are sorted by date regardless of input order")
    func racesSortedByDate() {
        let skeletons = makeSkeletons(weekRange: 1...12)
        let laterRace = makeRace(priority: .bRace, weekNumber: 8)
        let earlierRace = makeRace(priority: .bRace, weekNumber: 4)

        // Pass later race first
        let overrides = IntermediateRaceHandler.overrides(
            skeletons: skeletons,
            intermediateRaces: [laterRace, earlierRace]
        )

        // Earlier race overrides should come first in the output
        let earlierOverrides = overrides.filter { $0.raceId == earlierRace.id }
        let laterOverrides = overrides.filter { $0.raceId == laterRace.id }

        // Each B-race at 50km → 1 taper + 1 race week + 3 recoveries (RR-23)
        #expect(earlierOverrides.count == 5)
        #expect(laterOverrides.count == 5)

        // Verify ordering: earlier race overrides appear before later race overrides
        let firstEarlierIndex = overrides.firstIndex { $0.raceId == earlierRace.id }!
        let firstLaterIndex = overrides.firstIndex { $0.raceId == laterRace.id }!
        #expect(firstEarlierIndex < firstLaterIndex, "Earlier race overrides should come first")
    }

    // MARK: - Behavior Properties

    @Test("isRaceWeek returns true only for raceWeek behavior")
    func isRaceWeekProperty() {
        #expect(IntermediateRaceHandler.Behavior.raceWeek(priority: .bRace).isRaceWeek == true)
        #expect(IntermediateRaceHandler.Behavior.raceWeek(priority: .cRace).isRaceWeek == true)
        #expect(IntermediateRaceHandler.Behavior.miniTaper.isRaceWeek == false)
        #expect(IntermediateRaceHandler.Behavior.postRaceRecovery.isRaceWeek == false)
    }
}
