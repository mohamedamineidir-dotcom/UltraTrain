import Foundation
import Testing
@testable import UltraTrain

@Suite("WeekSkeletonBuilder Tests")
struct WeekSkeletonBuilderTests {

    // MARK: - Helpers

    private func makePhases(_ specs: [(TrainingPhase, Int)]) -> [PhaseDistributor.PhaseAllocation] {
        specs.map { PhaseDistributor.PhaseAllocation(phase: $0.0, weekCount: $0.1) }
    }

    private var raceDate: Date {
        // A fixed Monday-based date for predictable results
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 29 // Saturday
        return Calendar.current.date(from: components)!
    }

    // MARK: - Week Count

    @Test("total skeleton count matches sum of phase weeks")
    func skeletonCountMatchesPhaseTotal() {
        let phases = makePhases([(.base, 4), (.build, 6), (.peak, 2), (.taper, 2)])
        let skeletons = WeekSkeletonBuilder.build(raceDate: raceDate, phases: phases)

        #expect(skeletons.count == 14)
    }

    @Test("single phase produces correct count")
    func singlePhase() {
        let phases = makePhases([(.base, 3)])
        let skeletons = WeekSkeletonBuilder.build(raceDate: raceDate, phases: phases)

        #expect(skeletons.count == 3)
        #expect(skeletons.allSatisfy { $0.phase == .base })
    }

    // MARK: - Phase Assignment

    @Test("phases assigned in correct order")
    func phasesInCorrectOrder() {
        let phases = makePhases([(.base, 2), (.build, 2), (.taper, 1)])
        let skeletons = WeekSkeletonBuilder.build(raceDate: raceDate, phases: phases)

        #expect(skeletons[0].phase == .base)
        #expect(skeletons[1].phase == .base)
        #expect(skeletons[2].phase == .build)
        #expect(skeletons[3].phase == .build)
        #expect(skeletons[4].phase == .taper)
    }

    // MARK: - Week Numbers

    @Test("week numbers are sequential starting at 1")
    func weekNumbersSequential() {
        let phases = makePhases([(.base, 3), (.build, 2)])
        let skeletons = WeekSkeletonBuilder.build(raceDate: raceDate, phases: phases)

        for (index, skeleton) in skeletons.enumerated() {
            #expect(skeleton.weekNumber == index + 1)
        }
    }

    // MARK: - Recovery Weeks

    @Test("recovery weeks inserted every N-th week")
    func recoveryWeeksInserted() {
        let phases = makePhases([(.base, 9)]) // 9 weeks with cycle of 3
        let skeletons = WeekSkeletonBuilder.build(raceDate: raceDate, phases: phases, recoveryCycle: 3)

        // Weeks 3, 6 should be recovery (every 3rd), but not the last phase week
        let recoveryWeeks = skeletons.filter { $0.isRecoveryWeek }
        #expect(recoveryWeeks.count >= 2)
        #expect(skeletons[2].isRecoveryWeek == true)  // Week 3
        #expect(skeletons[5].isRecoveryWeek == true)  // Week 6
    }

    @Test("taper weeks are never marked as recovery")
    func taperNeverRecovery() {
        let phases = makePhases([(.base, 3), (.taper, 3)])
        let skeletons = WeekSkeletonBuilder.build(raceDate: raceDate, phases: phases, recoveryCycle: 2)

        let taperSkeletons = skeletons.filter { $0.phase == .taper }
        #expect(taperSkeletons.allSatisfy { !$0.isRecoveryWeek })
    }

    @Test("last week of a phase is not marked as recovery")
    func lastPhaseWeekNotRecovery() {
        let phases = makePhases([(.base, 3)]) // With cycle 3, week 3 is the last → not recovery
        let skeletons = WeekSkeletonBuilder.build(raceDate: raceDate, phases: phases, recoveryCycle: 3)

        #expect(skeletons.last?.isRecoveryWeek == false)
    }

    // MARK: - Dates

    @Test("each week spans 7 days")
    func weekSpansSevenDays() {
        let phases = makePhases([(.base, 4)])
        let skeletons = WeekSkeletonBuilder.build(raceDate: raceDate, phases: phases)

        for skeleton in skeletons {
            let days = Calendar.current.dateComponents([.day], from: skeleton.startDate, to: skeleton.endDate).day!
            #expect(days == 6) // startDate to endDate = 6 days (Mon to Sun)
        }
    }

    @Test("weeks are contiguous (no gaps)")
    func weeksContiguous() {
        let phases = makePhases([(.base, 3), (.build, 3)])
        let skeletons = WeekSkeletonBuilder.build(raceDate: raceDate, phases: phases)

        for i in 1..<skeletons.count {
            let prevEnd = skeletons[i - 1].endDate
            let nextStart = skeletons[i].startDate
            let gap = Calendar.current.dateComponents([.day], from: prevEnd, to: nextStart).day!
            #expect(gap == 1) // End Sunday → Start Monday = 1 day gap
        }
    }

    // MARK: - Edge Cases

    @Test("single week plan works")
    func singleWeekPlan() {
        let phases = makePhases([(.taper, 1)])
        let skeletons = WeekSkeletonBuilder.build(raceDate: raceDate, phases: phases)

        #expect(skeletons.count == 1)
        #expect(skeletons[0].weekNumber == 1)
        #expect(skeletons[0].phase == .taper)
        #expect(skeletons[0].isRecoveryWeek == false)
    }
}
