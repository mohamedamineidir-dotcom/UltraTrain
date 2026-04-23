import Testing
import Foundation
@testable import UltraTrain

@Suite("RefineRoadPaceFromFeedbackUseCase Tests")
struct RefineRoadPaceFromFeedbackUseCaseTests {

    // MARK: - Fixtures

    /// Baseline pace profile: 4:00/km intervals, 4:20/km threshold, 4:50/km
    /// race pace. Represents a ~20-min 5K athlete (advanced). Data-derived.
    private func makeBaseProfile(
        interval: Double = 240,
        threshold: Double = 260,
        ambitious: GoalRealism = .realistic,
        isDataDerived: Bool = true
    ) -> RoadPaceProfile {
        RoadPaceProfile(
            easyPacePerKm: 300...330,
            marathonPacePerKm: 270,
            thresholdPacePerKm: threshold,
            intervalPacePerKm: interval,
            repetitionPacePerKm: 223,
            racePacePerKm: 290,
            goalRealismLevel: ambitious,
            isDataDerived: isDataDerived,
            recommendedGoalTime: nil
        )
    }

    /// Generates N intervals feedbacks with a given per-rep deviation,
    /// RPE, and completion rate, spread evenly across the last 14 days.
    private func makeFeedback(
        type: SessionType = .intervals,
        count: Int = 4,
        targetPace: Double = 240,
        perRepDeviationSeconds: Double,
        perceivedEffort: Int = 7,
        completedAllReps: Bool = true,
        now: Date = Date()
    ) -> [IntervalPerformanceFeedback] {
        (0..<count).map { idx in
            let daysAgo = Double(idx + 1) * 3
            let created = now.addingTimeInterval(-daysAgo * 24 * 3600)
            let actualPace = targetPace + perRepDeviationSeconds
            return IntervalPerformanceFeedback(
                id: UUID(),
                sessionId: UUID(),
                sessionType: type,
                targetPacePerKmAtTime: targetPace,
                prescribedRepCount: 6,
                actualPacesPerKm: [actualPace, actualPace, actualPace, actualPace, actualPace, actualPace],
                completedAllReps: completedAllReps,
                completedRepCount: completedAllReps ? 6 : 0,
                perceivedEffort: perceivedEffort,
                notes: nil,
                createdAt: created
            )
        }
    }

    // MARK: - Evidence threshold

    @Test("No adjustment with fewer than 3 feedbacks")
    func insufficientEvidence() {
        let base = makeBaseProfile()
        let fbs = makeFeedback(count: 2, perRepDeviationSeconds: 10, perceivedEffort: 9)
        let now = Date()
        let raceDate = now.addingTimeInterval(60 * 24 * 3600) // 60d out = build

        let (profile, summary) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: base, feedback: fbs, now: now,
            raceDate: raceDate, discipline: .roadHalf, experience: .advanced
        )

        #expect(summary == nil)
        #expect(profile.intervalPacePerKm == base.intervalPacePerKm)
    }

    @Test("Feedback older than 21 days is ignored")
    func staleFeedbackIgnored() {
        let base = makeBaseProfile()
        let now = Date()
        let old = now.addingTimeInterval(-30 * 24 * 3600)
        let fbs = (0..<5).map { _ in
            IntervalPerformanceFeedback(
                id: UUID(), sessionId: UUID(), sessionType: .intervals,
                targetPacePerKmAtTime: 240, prescribedRepCount: 6,
                actualPacesPerKm: [248, 250, 252],
                completedAllReps: true, perceivedEffort: 9,
                notes: nil, createdAt: old
            )
        }
        let raceDate = now.addingTimeInterval(60 * 24 * 3600)

        let (profile, summary) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: base, feedback: fbs, now: now,
            raceDate: raceDate, discipline: .roadHalf, experience: .advanced
        )

        #expect(summary == nil)
        #expect(profile.intervalPacePerKm == base.intervalPacePerKm)
    }

    // MARK: - Slow-down paths

    @Test("Slow pace + high RPE → strong slow down")
    func slowPaceHighRPESlowsDown() {
        let base = makeBaseProfile()
        let now = Date()
        let fbs = makeFeedback(
            count: 4, targetPace: 240,
            perRepDeviationSeconds: 8, perceivedEffort: 9, completedAllReps: true, now: now
        )
        let raceDate = now.addingTimeInterval(60 * 24 * 3600)

        let (profile, summary) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: base, feedback: fbs, now: now,
            raceDate: raceDate, discipline: .roadHalf, experience: .advanced
        )

        #expect(summary != nil)
        #expect(profile.intervalPacePerKm > base.intervalPacePerKm)
        let entry = summary?.entry(for: .intervals)
        #expect(entry?.reason == .slowDownPaceDrift)
    }

    @Test("Incomplete reps repeatedly → slow down independently of pace")
    func incompleteRepsSlowsDown() {
        let base = makeBaseProfile()
        let now = Date()
        let fbs = (0..<4).map { idx in
            let completed = idx >= 2 // 2 of 4 incomplete = 50% rate
            return makeFeedback(
                count: 1, targetPace: 240,
                perRepDeviationSeconds: 0, perceivedEffort: 7,
                completedAllReps: completed,
                now: now.addingTimeInterval(-Double(idx + 1) * 3 * 24 * 3600)
            ).first!
        }
        let raceDate = now.addingTimeInterval(60 * 24 * 3600)

        let (profile, summary) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: base, feedback: fbs, now: now,
            raceDate: raceDate, discipline: .roadHalf, experience: .advanced
        )

        let entry = summary?.entry(for: .intervals)
        #expect(entry?.reason == .slowDownIncompleteReps)
        #expect(profile.intervalPacePerKm > base.intervalPacePerKm)
    }

    @Test("On-target pace + high RPE → mild slow down")
    func onTargetHighRPESlowsDown() {
        let base = makeBaseProfile()
        let now = Date()
        let fbs = makeFeedback(
            count: 4, targetPace: 240,
            perRepDeviationSeconds: 0, perceivedEffort: 9, completedAllReps: true, now: now
        )
        let raceDate = now.addingTimeInterval(60 * 24 * 3600)

        let (profile, summary) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: base, feedback: fbs, now: now,
            raceDate: raceDate, discipline: .roadHalf, experience: .advanced
        )

        let entry = summary?.entry(for: .intervals)
        #expect(entry?.reason == .slowDownHighRPE)
        #expect(profile.intervalPacePerKm > base.intervalPacePerKm)
    }

    // MARK: - Speed-up paths

    @Test("Fast pace + low RPE + completed → speeds up")
    func fastPaceLowRPESpeedsUp() {
        let base = makeBaseProfile()
        let now = Date()
        let fbs = makeFeedback(
            count: 4, targetPace: 240,
            perRepDeviationSeconds: -8, perceivedEffort: 5, completedAllReps: true, now: now
        )
        let raceDate = now.addingTimeInterval(60 * 24 * 3600)

        let (profile, summary) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: base, feedback: fbs, now: now,
            raceDate: raceDate, discipline: .roadHalf, experience: .advanced
        )

        let entry = summary?.entry(for: .intervals)
        #expect(entry?.reason == .speedUpFitnessHeadroom)
        #expect(profile.intervalPacePerKm < base.intervalPacePerKm)
    }

    @Test("Fast pace + high RPE → NO speed up (unsustainable)")
    func fastPaceHighRPENoSpeedUp() {
        let base = makeBaseProfile()
        let now = Date()
        let fbs = makeFeedback(
            count: 4, targetPace: 240,
            perRepDeviationSeconds: -8, perceivedEffort: 9, completedAllReps: true, now: now
        )
        let raceDate = now.addingTimeInterval(60 * 24 * 3600)

        let (_, summary) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: base, feedback: fbs, now: now,
            raceDate: raceDate, discipline: .roadHalf, experience: .advanced
        )

        #expect(summary == nil)
    }

    @Test("Very-ambitious goal → never speeds up from feedback")
    func veryAmbitiousNeverSpeedsUp() {
        let base = makeBaseProfile(ambitious: .veryAmbitious)
        let now = Date()
        let fbs = makeFeedback(
            count: 5, targetPace: 240,
            perRepDeviationSeconds: -10, perceivedEffort: 5, completedAllReps: true, now: now
        )
        let raceDate = now.addingTimeInterval(60 * 24 * 3600)

        let (profile, summary) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: base, feedback: fbs, now: now,
            raceDate: raceDate, discipline: .roadHalf, experience: .advanced
        )

        #expect(summary == nil)
        #expect(profile.intervalPacePerKm == base.intervalPacePerKm)
    }

    // MARK: - Gates

    @Test("Taper phase locks — no adjustment ever")
    func taperLocked() {
        let base = makeBaseProfile()
        let now = Date()
        let fbs = makeFeedback(
            count: 5, targetPace: 240,
            perRepDeviationSeconds: 15, perceivedEffort: 10, completedAllReps: false, now: now
        )
        let raceDate = now.addingTimeInterval(10 * 24 * 3600) // 10d = taper

        let (profile, summary) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: base, feedback: fbs, now: now,
            raceDate: raceDate, discipline: .roadHalf, experience: .advanced
        )

        #expect(summary == nil)
        #expect(profile.intervalPacePerKm == base.intervalPacePerKm)
    }

    @Test("Non-data-derived profile → no adjustment")
    func nonDataDerivedNoAdjustment() {
        let base = makeBaseProfile(isDataDerived: false)
        let now = Date()
        let fbs = makeFeedback(
            count: 5, targetPace: 240,
            perRepDeviationSeconds: 15, perceivedEffort: 10, now: now
        )
        let raceDate = now.addingTimeInterval(60 * 24 * 3600)

        let (profile, summary) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: base, feedback: fbs, now: now,
            raceDate: raceDate, discipline: .roadHalf, experience: .advanced
        )

        #expect(summary == nil)
        #expect(profile.intervalPacePerKm == base.intervalPacePerKm)
    }

    // MARK: - Modifiers & caps

    @Test("Beginners get smaller adjustments than advanced for same signal")
    func beginnersDampened() {
        let base = makeBaseProfile()
        let now = Date()
        let fbs = makeFeedback(
            count: 5, targetPace: 240,
            perRepDeviationSeconds: 10, perceivedEffort: 9, completedAllReps: true, now: now
        )
        let raceDate = now.addingTimeInterval(60 * 24 * 3600)

        let (beginnerProfile, _) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: base, feedback: fbs, now: now,
            raceDate: raceDate, discipline: .roadHalf, experience: .beginner
        )
        let (advancedProfile, _) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: base, feedback: fbs, now: now,
            raceDate: raceDate, discipline: .roadHalf, experience: .advanced
        )

        let beginnerDelta = beginnerProfile.intervalPacePerKm - base.intervalPacePerKm
        let advancedDelta = advancedProfile.intervalPacePerKm - base.intervalPacePerKm
        #expect(beginnerDelta < advancedDelta)
    }

    @Test("10K tightens adjustment vs marathon for the same signal")
    func tenKTighterThanMarathon() {
        let base = makeBaseProfile()
        let now = Date()
        let fbs = makeFeedback(
            count: 5, targetPace: 240,
            perRepDeviationSeconds: 10, perceivedEffort: 9, completedAllReps: true, now: now
        )
        let raceDate = now.addingTimeInterval(60 * 24 * 3600)

        let (tenKProfile, _) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: base, feedback: fbs, now: now,
            raceDate: raceDate, discipline: .road10K, experience: .advanced
        )
        let (marathonProfile, _) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: base, feedback: fbs, now: now,
            raceDate: raceDate, discipline: .roadMarathon, experience: .advanced
        )

        let tenKDelta = tenKProfile.intervalPacePerKm - base.intervalPacePerKm
        let marathonDelta = marathonProfile.intervalPacePerKm - base.intervalPacePerKm
        #expect(tenKDelta < marathonDelta)
    }

    @Test("±8% hard cap holds under extreme feedback")
    func eightPercentHardCap() {
        let base = makeBaseProfile(interval: 240)
        let now = Date()
        let fbs = makeFeedback(
            count: 10, targetPace: 240,
            perRepDeviationSeconds: 60, perceivedEffort: 10, completedAllReps: false, now: now
        )
        let raceDate = now.addingTimeInterval(60 * 24 * 3600)

        let (profile, _) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: base, feedback: fbs, now: now,
            raceDate: raceDate, discipline: .roadMarathon, experience: .advanced
        )

        // Never exceed +8% from baseline (240 × 1.08 = 259.2).
        #expect(profile.intervalPacePerKm <= 259.21)
    }

    // MARK: - Isolation

    @Test("Intervals feedback does not affect threshold pace")
    func intervalsDontAffectThreshold() {
        let base = makeBaseProfile()
        let now = Date()
        let fbs = makeFeedback(
            type: .intervals, count: 5, targetPace: 240,
            perRepDeviationSeconds: 10, perceivedEffort: 9, now: now
        )
        let raceDate = now.addingTimeInterval(60 * 24 * 3600)

        let (profile, _) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: base, feedback: fbs, now: now,
            raceDate: raceDate, discipline: .roadHalf, experience: .advanced
        )

        #expect(profile.thresholdPacePerKm == base.thresholdPacePerKm)
        #expect(profile.intervalPacePerKm != base.intervalPacePerKm)
    }

    // MARK: - Deadband

    @Test("Tiny deviations fall into the deadband (no user-visible change)")
    func deadband() {
        let base = makeBaseProfile()
        let now = Date()
        // +2s/km deviation, RPE 6 — within tolerance, should not trigger
        let fbs = makeFeedback(
            count: 4, targetPace: 240,
            perRepDeviationSeconds: 2, perceivedEffort: 6, completedAllReps: true, now: now
        )
        let raceDate = now.addingTimeInterval(60 * 24 * 3600)

        let (profile, summary) = RefineRoadPaceFromFeedbackUseCase.refine(
            baseProfile: base, feedback: fbs, now: now,
            raceDate: raceDate, discipline: .roadHalf, experience: .advanced
        )

        #expect(summary == nil)
        #expect(profile.intervalPacePerKm == base.intervalPacePerKm)
    }
}
