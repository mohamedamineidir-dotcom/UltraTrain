import Foundation
import Testing
@testable import UltraTrain

/// Guards that the localized (String(localized:)) coach-advice strings keep
/// valid format specifiers: every interpolated key is exercised so a wrong
/// specifier (arg count/type) crashes or garbles here instead of in the app.
/// Runs in the en locale, which now resolves to the catalog's en values.
@Suite("Road coach advice localization")
struct RoadCoachAdviceLocalizationTests {

    private func profile(goalTime: TimeInterval?) -> RoadPaceProfile {
        RoadPaceCalculator.paceProfile(
            goalTime: goalTime, raceDistanceKm: 42.195,
            personalBests: [PersonalBest(id: UUID(), distance: .tenK, timeSeconds: 2100, date: .now)],
            vmaKmh: nil, experience: .advanced
        )
    }

    @Test("interpolated advice resolves with correct values, no specifier crash")
    func interpolationIntegrity() {
        let p = profile(goalTime: nil)

        // targetRange (2 String args) via easy run.
        let easy = RoadCoachAdviceGenerator.advice(
            type: .recovery, intensity: .easy, phase: .base,
            discipline: .roadMarathon, isRecoveryWeek: false, paceProfile: p)
        #expect(easy?.contains("/km") == true)

        // interval.peak (displayName %@) + targetPace (%@).
        let iv = RoadCoachAdviceGenerator.advice(
            type: .intervals, intensity: .hard, phase: .peak,
            discipline: .roadMarathon, isRecoveryWeek: false, paceProfile: p)
        #expect(iv?.contains("Marathon") == true)
        #expect(iv?.contains("/km") == true)

        // targetHR (2 Int args).
        let hr = RoadCoachAdviceGenerator.advice(
            type: .tempo, intensity: .moderate, phase: .build,
            discipline: .roadMarathon, isRecoveryWeek: false, paceProfile: p,
            restingHR: 45, maxHR: 190)
        #expect(hr?.contains("bpm") == true)

        // refine.summary (6 args: String, Int, String, String, Int, String).
        let entry = RefineRoadPaceFromFeedbackUseCase.PaceRefinementSummary.Entry(
            sessionType: .intervals, originalPacePerKm: 240, adjustedPacePerKm: 248,
            reason: .slowDownPaceDrift, evidenceCount: 4, meanRPE: 7.5,
            meanDeviationSecondsPerKm: 6)
        let summary = RefineRoadPaceFromFeedbackUseCase.PaceRefinementSummary(
            entries: [entry], gatePhase: .build)
        let refined = RoadCoachAdviceGenerator.advice(
            type: .intervals, intensity: .hard, phase: .build,
            discipline: .roadMarathon, isRecoveryWeek: false, paceProfile: p,
            refinementSummary: summary)
        #expect(refined?.contains("📊") == true)
        #expect(refined?.contains("recent sessions") == true)

        // goal.veryAmbitious.withTarget (%@) — absurdly fast goal.
        let amb = RoadCoachAdviceGenerator.advice(
            type: .longRun, intensity: .easy, phase: .peak,
            discipline: .roadMarathon, isRecoveryWeek: false,
            paceProfile: profile(goalTime: 7200))
        #expect(amb != nil)
    }
}
