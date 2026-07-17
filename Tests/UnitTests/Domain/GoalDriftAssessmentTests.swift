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

    @Test("Goal far faster than the RACE-DAY projection is very ambitious and prompts adjust")
    func veryAmbitious() {
        // Level is judged against the race-day projection, not today's raw
        // expected finish — goal 2:30 (9000s), optimistic 8500, expected
        // 11000. No raceDate passed => defaults to "now" => 0 weeks to race
        // => short-window blend of 0.60 (little time to adapt):
        // projected = 8500 + (11000-8500)*0.60 = 10000.
        // gap = 10000 - 9000 = 1000 => +11.1% over goal => veryAmbitious.
        let a = GoalDriftAssessment.assess(goal: .targetTime(9000), expectedFinish: 11000, optimisticFinish: 8500)!
        #expect(a.level == .veryAmbitious)
        #expect(a.isDrifted)
        #expect(a.suggestsAdjustment)
        #expect(a.gapSeconds == 1000)
        #expect(a.projectedRaceDayTime == 10000)
        #expect(a.suggestedTime == 9990)
    }

    @Test("A goal that looks ambitious against today's fitness but not against race-day projection reads on track")
    func notAmbitiousAgainstRaceDayProjection() {
        // Real-world regression: Oman by UTMB Jabal Classic 103K, ~21 weeks
        // out. optimistic 12h33 (45180s), expected (today) 13h52 (49920s),
        // goal 13h00 (46800s). Naively comparing the goal against today's
        // expected (49920) makes it look like a huge stretch (+6.7%,
        // "veryAmbitious") — but the race-day projection is ~12h46 (46010s,
        // faster than the goal), which is what the goal must actually be
        // judged against. This must NOT be flagged as ambitious.
        let raceDate = Date().addingTimeInterval(21 * 7 * 86400)
        let a = GoalDriftAssessment.assess(
            goal: .targetTime(46800), expectedFinish: 49920, optimisticFinish: 45180, raceDate: raceDate
        )!
        #expect(a.level == .onTrack, "13h00 is realistic against the ~12h46 race-day projection, not ambitious")
        #expect(!a.isDrifted)
        #expect(!a.suggestsAdjustment)
    }

    @Test("Suggested time scales with weeks to race — a longer training window projects more improvement")
    func suggestedTimeScalesWithTrainingWindow() {
        // Same optimistic/expected, compared across a near-term vs a
        // realistic 20-week race date. A longer window should close more
        // of the gap to optimistic (a FASTER, lower suggested time) than a
        // near-term one, which barely has room to adapt.
        let nearRaceDate = Date().addingTimeInterval(2 * 7 * 86400)
        let farRaceDate = Date().addingTimeInterval(20 * 7 * 86400)
        let near = GoalDriftAssessment.assess(
            goal: .targetTime(9600), expectedFinish: 10200, optimisticFinish: 9600, raceDate: nearRaceDate
        )!
        let far = GoalDriftAssessment.assess(
            goal: .targetTime(9600), expectedFinish: 10200, optimisticFinish: 9600, raceDate: farRaceDate
        )!
        #expect(far.suggestedTime < near.suggestedTime)
    }

    @Test("Goal moderately faster than the race-day projection is a stretch, flagged but no forced adjust")
    func ambitiousStretch() {
        // goal 2:30 (9000s), optimistic 8500, expected 9700, 0-week blend
        // 0.60 => projected = 8500 + (9700-8500)*0.60 = 9220.
        // gap = 9220 - 9000 = 220 => +2.4% (between 2% and 6%).
        let a = GoalDriftAssessment.assess(goal: .targetTime(9000), expectedFinish: 9700, optimisticFinish: 8500)!
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
        // 0-week short-window blend 0.60: 9600 + (10080-9600)*0.60 = 9888 -> nearest 30s is 9900.
        #expect(a.suggestedTime == 9900)
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
        // optimistic 9600, expected 10214, default (0-week) short-window
        // blend 0.60 => projected 9600 + 614*0.60 = 9968.4, nearest 30s is 9960.
        let a = GoalDriftAssessment.assess(goal: .targetTime(9600), expectedFinish: 10214, optimisticFinish: 9600)!
        #expect(a.suggestedTime == 9960)
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
