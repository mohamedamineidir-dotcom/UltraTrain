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

    @Test("Advanced 26-week plan has short base and long build+peak")
    func advancedCampusCoachAlignment() {
        let result = PhaseDistributor.distribute(totalWeeks: 26, experience: .advanced)
        let base = result.first { $0.phase == .base }!.weekCount
        let build = result.first { $0.phase == .build }!.weekCount
        let peak = result.first { $0.phase == .peak }!.weekCount
        let taper = result.first { $0.phase == .taper }!.weekCount

        #expect(base <= 7, "Base should be short for advanced, got \(base)")
        #expect(build + peak >= 12, "Build+peak should be long for advanced, got \(build + peak)")
        #expect(taper >= 4, "Taper should be >= 4 weeks for advanced, got \(taper)")
    }

    @Test("Elite 26-week plan has minimal base")
    func eliteMinimalBase() {
        let result = PhaseDistributor.distribute(totalWeeks: 26, experience: .elite)
        let base = result.first { $0.phase == .base }!.weekCount
        #expect(base <= 5, "Elite base should be minimal, got \(base)")
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

    // MARK: - PhaseFocus Tests

    @Test("Each allocation has correct PhaseFocus")
    func allocationsHaveCorrectFocus() {
        let result = PhaseDistributor.distribute(totalWeeks: 20, experience: .intermediate)
        let expectedFocuses: [TrainingPhase: PhaseFocus] = [
            .base: .threshold30,
            .build: .vo2max,
            .peak: .threshold60,
            .taper: .sharpening
        ]
        for allocation in result {
            #expect(
                allocation.phaseFocus == expectedFocuses[allocation.phase],
                "\(allocation.phase) should have focus \(expectedFocuses[allocation.phase]!), got \(allocation.phaseFocus)"
            )
        }
    }

    @Test("Advanced 26-week produces Campus Coach distribution: 4+4+12+6")
    func advancedCampusCoach26Weeks() {
        let result = PhaseDistributor.distribute(totalWeeks: 26, experience: .advanced)
        let base = result.first { $0.phase == .base }!.weekCount
        let build = result.first { $0.phase == .build }!.weekCount
        let peak = result.first { $0.phase == .peak }!.weekCount
        let taper = result.first { $0.phase == .taper }!.weekCount

        // Campus Coach: ~15% base, ~15% build, ~46% peak, ~24% taper
        #expect(base == 4, "Base (Seuil30) should be 4, got \(base)")
        #expect(build == 4, "Build (VO2max) should be 4, got \(build)")
        #expect(peak == 12, "Peak (Seuil60) should be 12, got \(peak)")
        #expect(taper == 6, "Taper (Affutage) should be 6, got \(taper)")
    }

    @Test("Short plan still has correct PhaseFocus")
    func shortPlanFocus() {
        let result = PhaseDistributor.distribute(totalWeeks: 3, experience: .intermediate)
        #expect(result[0].phaseFocus == .threshold30)
        #expect(result[1].phaseFocus == .sharpening)
    }

    @Test("All experience levels produce valid 8-week allocation")
    func eightWeekAllExperiences() {
        for experience in ExperienceLevel.allCases {
            let result = PhaseDistributor.distribute(totalWeeks: 8, experience: experience)
            let sum = result.reduce(0) { $0 + $1.weekCount }
            #expect(sum == 8, "\(experience) 8-week plan should total 8 weeks, got \(sum)")
            // All allocations should have a phaseFocus
            for allocation in result {
                #expect(PhaseFocus.allCases.contains(allocation.phaseFocus))
            }
        }
    }
}
