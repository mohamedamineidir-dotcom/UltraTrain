import Foundation
import Testing
@testable import UltraTrain

@Suite("Adaptive training-fitness anchor")
struct AdaptiveFitnessCalculatorTests {

    // 10K PR 40:00 -> ~1151s 5K-equivalent baseline (5K pace ~3:50/km,
    // expected easy ~5:13/km).
    private func makeAthlete(
        experience: ExperienceLevel = .advanced,
        runsPerWeek: Int = 1,
        adaptive: TimeInterval? = nil
    ) -> Athlete {
        var a = Athlete(
            id: UUID(), firstName: "T", lastName: "R",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 65, heightCm: 175, restingHeartRate: 48, maxHeartRate: 190,
            experienceLevel: experience, weeklyVolumeKm: 60, longestRunKm: 25,
            preferredUnit: .metric
        )
        a.personalBests = [PersonalBest(id: UUID(), distance: .tenK, timeSeconds: 2400, date: .now)]
        a.preferredRunsPerWeek = runsPerWeek
        a.adaptiveFitness5KSeconds = adaptive
        return a
    }

    private func easySession(
        distanceKm: Double = 8, durationSeconds: TimeInterval, rpe: Int, daysAgo: Double
    ) -> TrainingSession {
        var s = TrainingSession(
            id: UUID(), date: Date.now.addingTimeInterval(-daysAgo * 86400),
            type: .recovery, plannedDistanceKm: distanceKm, plannedElevationGainM: 0,
            plannedDuration: durationSeconds, intensity: .easy, description: "Easy",
            isCompleted: true, isSkipped: false, linkedRunId: nil
        )
        s.actualDistanceKm = distanceKm
        s.actualDurationSeconds = durationSeconds
        s.actualElevationGainM = 0
        s.perceivedExertion = rpe
        return s
    }

    private func feedback(
        meanPace: Double, rpe: Int, daysAgo: Double, completed: Int = 6, prescribed: Int = 6
    ) -> IntervalPerformanceFeedback {
        IntervalPerformanceFeedback(
            id: UUID(), sessionId: UUID(), sessionType: .intervals,
            targetPacePerKmAtTime: meanPace + 5, prescribedRepCount: prescribed,
            actualPacesPerKm: Array(repeating: meanPace, count: prescribed),
            completedAllReps: completed >= prescribed, completedRepCount: completed,
            perceivedEffort: rpe, notes: nil,
            createdAt: Date.now.addingTimeInterval(-daysAgo * 86400)
        )
    }

    // MARK: - Easy-run signal

    @Test("Easy runs held faster at a genuinely easy RPE improve the anchor")
    func easyRunsFasterAtLowRPEImprove() {
        // 8 km easy at 5:00/km (300 s/km), well inside an easy effort: RPE 3.
        let sessions = (0..<3).map {
            easySession(durationSeconds: 8 * 300, rpe: 3, daysAgo: Double($0 * 2 + 1))
        }
        let result = AdaptiveFitnessCalculator.compute(
            athlete: makeAthlete(), completedSessions: sessions, intervalFeedback: []
        )
        #expect(result != nil)
        #expect(result! < 1151)            // faster than the PR baseline
    }

    @Test("Same fast easy runs at a HIGH RPE are ignored (ran too hard)")
    func easyRunsFasterButHighRPEIgnored() {
        let sessions = (0..<3).map {
            easySession(durationSeconds: 8 * 300, rpe: 7, daysAgo: Double($0 * 2 + 1))
        }
        let result = AdaptiveFitnessCalculator.compute(
            athlete: makeAthlete(), completedSessions: sessions, intervalFeedback: []
        )
        #expect(result == nil)
    }

    @Test("A single fast effort is not enough (needs corroboration)")
    func singleEffortInsufficient() {
        let result = AdaptiveFitnessCalculator.compute(
            athlete: makeAthlete(),
            completedSessions: [easySession(durationSeconds: 8 * 300, rpe: 3, daysAgo: 1)],
            intervalFeedback: []
        )
        #expect(result == nil)
    }

    // MARK: - Quality signal

    @Test("Quality reps faster than target at a controlled RPE improve the anchor")
    func qualityFeedbackImproves() {
        // Reps at 3:30/km (210 s/km) -> ~17:30 5K-equivalent, beating the
        // 40:00-10K baseline, at a controlled RPE 6, all reps completed.
        let fbs = (0..<3).map { feedback(meanPace: 210, rpe: 6, daysAgo: Double($0 * 3 + 1)) }
        let result = AdaptiveFitnessCalculator.compute(
            athlete: makeAthlete(), completedSessions: [], intervalFeedback: fbs
        )
        #expect(result != nil)
        #expect(result! < 1151)
    }

    @Test("Quality reps at a maxed-out RPE are not treated as headroom")
    func qualityFeedbackHighRPEIgnored() {
        let fbs = (0..<3).map { feedback(meanPace: 210, rpe: 9, daysAgo: Double($0 * 3 + 1)) }
        let result = AdaptiveFitnessCalculator.compute(
            athlete: makeAthlete(), completedSessions: [], intervalFeedback: fbs
        )
        #expect(result == nil)
    }

    // MARK: - Bounds

    @Test("No evidence leaves the anchor unset")
    func noEvidenceNil() {
        let result = AdaptiveFitnessCalculator.compute(
            athlete: makeAthlete(), completedSessions: [], intervalFeedback: []
        )
        #expect(result == nil)
    }

    @Test("A single update moves only a small, capped step")
    func gradualStep() {
        // Very fast efforts; the move per update is still capped (~0.4%).
        let sessions = (0..<4).map {
            easySession(durationSeconds: 8 * 280, rpe: 3, daysAgo: Double($0 * 2 + 1))
        }
        let result = AdaptiveFitnessCalculator.compute(
            athlete: makeAthlete(), completedSessions: sessions, intervalFeedback: []
        )
        #expect(result != nil)
        // From the ~1151 baseline, one update steps at most ~0.4% (~4.6s).
        #expect(result! > 1151 - 1151 * 0.004 - 0.5)
        #expect(result! < 1151)
    }

    // MARK: - Pace profile floor

    @Test("Adaptive anchor floors the derived profile faster")
    func paceProfileFloor() {
        let prs = [PersonalBest(id: UUID(), distance: .tenK, timeSeconds: 2400, date: .now)]
        let base = RoadPaceCalculator.paceProfile(
            goalTime: nil, raceDistanceKm: 10, personalBests: prs,
            vmaKmh: nil, experience: .advanced
        )
        let adapted = RoadPaceCalculator.paceProfile(
            goalTime: nil, raceDistanceKm: 10, personalBests: prs,
            vmaKmh: nil, experience: .advanced, adaptiveFitness5KSeconds: 1100
        )
        #expect(adapted.easyPacePerKm.lowerBound < base.easyPacePerKm.lowerBound)
        #expect(adapted.thresholdPacePerKm < base.thresholdPacePerKm)
    }
}
