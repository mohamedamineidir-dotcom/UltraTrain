import Foundation
import Testing
@testable import UltraTrain

@Suite("Phase Distributor Tests")
struct PhaseDistributorTests {

    @Test("Total week count matches input")
    func totalWeeksMatch() {
        for totalWeeks in [8, 12, 16, 20, 24] {
            for experience in ExperienceLevel.allCases {
                let result = PhaseDistributor.distribute(totalWeeks: totalWeeks, experience: experience)
                let sum = result.reduce(0) { $0 + $1.weekCount }
                #expect(sum == totalWeeks, "Expected \(totalWeeks) weeks for \(experience), got \(sum)")
            }
        }
    }

    @Test("Phase order is base, build, peak, taper")
    func phaseOrder() {
        let result = PhaseDistributor.distribute(totalWeeks: 16, experience: .intermediate)
        #expect(result.count == 4)
        #expect(result[0].phase == .base)
        #expect(result[1].phase == .build)
        #expect(result[2].phase == .peak)
        #expect(result[3].phase == .taper)
    }

    @Test("Each phase has at least 1 week")
    func minimumOneWeekPerPhase() {
        let result = PhaseDistributor.distribute(totalWeeks: 4, experience: .elite)
        for allocation in result {
            #expect(allocation.weekCount >= 1, "\(allocation.phase) has 0 weeks")
        }
    }

    @Test("Beginner has more base weeks than elite")
    func beginnerMoreBase() {
        let beginner = PhaseDistributor.distribute(totalWeeks: 20, experience: .beginner)
        let elite = PhaseDistributor.distribute(totalWeeks: 20, experience: .elite)

        let beginnerBase = beginner.first { $0.phase == .base }!.weekCount
        let eliteBase = elite.first { $0.phase == .base }!.weekCount
        #expect(beginnerBase > eliteBase)
    }

    @Test("Short plan (less than 4 weeks) returns base + taper")
    func shortPlan() {
        let result = PhaseDistributor.distribute(totalWeeks: 3, experience: .intermediate)
        #expect(result.count == 2)
        #expect(result[0].phase == .base)
        #expect(result[1].phase == .taper)
        let sum = result.reduce(0) { $0 + $1.weekCount }
        #expect(sum == 3)
    }

    @Test("Very short plan of 1 week")
    func singleWeek() {
        let result = PhaseDistributor.distribute(totalWeeks: 1, experience: .beginner)
        let sum = result.reduce(0) { $0 + $1.weekCount }
        #expect(sum >= 1)
    }
}
