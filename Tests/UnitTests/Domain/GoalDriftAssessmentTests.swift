import Foundation
import Testing
@testable import UltraTrain

@Suite("Goal drift assessment")
struct GoalDriftAssessmentTests {

    @Test("Non target-time goals are not assessed")
    func nonTargetGoalsNil() {
        #expect(GoalDriftAssessment.assess(goal: .finish, expectedFinish: 9000, optimisticFinish: 8500) == nil)
        #expect(GoalDriftAssessment.assess(goal: .targetRanking(10), expectedFinish: 9000, optimisticFinish: 8500) == nil)
    }

    @Test("Zero or missing inputs are not assessed")
    func invalidInputsNil() {
        #expect(GoalDriftAssessment.assess(goal: .targetTime(0), expectedFinish: 9000, optimisticFinish: 8500) == nil)
        #expect(GoalDriftAssessment.assess(goal: .targetTime(9000), expectedFinish: 0, optimisticFinish: 8500) == nil)
    }

    @Test("Goal matching the prediction reads on track")
    func onTrack() {
        // 2:30:00 goal, predicted 2:31:00 (+0.7%, inside the 2% band).
        let a = GoalDriftAssessment.assess(goal: .targetTime(9000), expectedFinish: 9060, optimisticFinish: 8700)!
        #expect(a.level == .onTrack)
        #expect(!a.isDrifted)
        #expect(!a.suggestsAdjustment)
    }

    @Test("Goal far faster than prediction is very ambitious and prompts adjust")
    func veryAmbitious() {
        // 2:40 goal (9600s), predicted 2:50 (10200s) => +6.25% over goal.
        let a = GoalDriftAssessment.assess(goal: .targetTime(9600), expectedFinish: 10200, optimisticFinish: 9600)!
        #expect(a.level == .veryAmbitious)
        #expect(a.isDrifted)
        #expect(a.suggestsAdjustment)
        #expect(a.gapSeconds == 600)
        // Suggested target is the RACE-DAY projection (optimistic + 15% of
        // the gap to expected), not the raw today's-fitness prediction —
        // 9600 + (10200-9600)*0.15 = 9690, already a multiple of 30.
        #expect(a.suggestedTime == 9690)
    }

    @Test("Goal moderately faster is a stretch, flagged but no forced adjust")
    func ambitiousStretch() {
        // 2:30 goal, predicted 2:34:00 => +2.7% (between 2% and 6%).
        let a = GoalDriftAssessment.assess(goal: .targetTime(9000), expectedFinish: 9240, optimisticFinish: 8800)!
        #expect(a.level == .ambitious)
        #expect(a.isDrifted)
        #expect(!a.suggestsAdjustment)
    }

    @Test("Goal far slower than prediction says aim higher and prompts adjust")
    func wellWithinReach() {
        // 3:00 goal (10800s), predicted 2:48 (10080s) => -6.7% under goal.
        let a = GoalDriftAssessment.assess(goal: .targetTime(10800), expectedFinish: 10080, optimisticFinish: 9600)!
        #expect(a.level == .wellWithinReach)
        #expect(a.isDrifted)
        #expect(a.suggestsAdjustment)
        // 9600 + (10080-9600)*0.15 = 9672 -> nearest 30s is 9660.
        #expect(a.suggestedTime == 9660)
    }

    @Test("Goal moderately slower has room to push, flagged but no forced adjust")
    func comfortable() {
        // 2:40 goal, predicted 2:35:00 => -3.1% under goal.
        let a = GoalDriftAssessment.assess(goal: .targetTime(9600), expectedFinish: 9300, optimisticFinish: 8900)!
        #expect(a.level == .comfortable)
        #expect(a.isDrifted)
        #expect(!a.suggestsAdjustment)
    }

    @Test("Suggested time is the race-day projection, rounded to the nearest 30 seconds")
    func suggestedRounds() {
        // optimistic 9600, expected 10214 => projected 9600 + 614*0.15 =
        // 9692.1, nearest 30s is 9690.
        let a = GoalDriftAssessment.assess(goal: .targetTime(9600), expectedFinish: 10214, optimisticFinish: 9600)!
        #expect(a.suggestedTime == 9690)
    }

    @Test("Missing optimistic time falls back to the expected prediction")
    func missingOptimisticFallsBack() {
        // optimisticFinish: 0 is treated as "not available" — suggestedTime
        // falls back to the plain expected prediction, rounded, matching the
        // pre-projection behavior rather than producing a nonsense value.
        let a = GoalDriftAssessment.assess(goal: .targetTime(9600), expectedFinish: 10200, optimisticFinish: 0)!
        #expect(a.suggestedTime == 10200)
    }
}
