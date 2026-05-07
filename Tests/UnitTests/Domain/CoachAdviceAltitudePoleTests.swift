import Foundation
import Testing
@testable import UltraTrain

/// T8: altitude + pole training advisories surface only on the right
/// session types in the right phases. Both are pure coaching cues —
/// no plan structure changes — so we verify presence/absence in the
/// advice string for each combination.
@Suite("Coach Advice — Altitude + Pole Cues (T8)")
struct CoachAdviceAltitudePoleTests {

    // MARK: - Altitude advisory

    @Test("Altitude advisory fires on peak long runs when ≥ 2500m")
    func altitudeOnPeakLongRun() {
        let advice = CoachAdviceGenerator.advice(
            for: .longRun,
            intensity: .easy,
            phase: .peak,
            plannedDurationSeconds: 4 * 3600,
            raceMaxElevationM: 4300 // Hardrock-class
        )
        #expect(advice?.contains("4300m") == true,
                "Should mention max elevation in advisory, got: \(advice ?? "nil")")
        #expect(advice?.contains("acclimatiz") == true || advice?.contains("altitude") == true,
                "Should mention altitude / acclimatization, got: \(advice ?? "nil")")
    }

    @Test("Altitude advisory uses high-altitude framing at ≥ 3500m")
    func altitudeHighFramingAt3500() {
        let advice = CoachAdviceGenerator.advice(
            for: .longRun,
            intensity: .easy,
            phase: .peak,
            plannedDurationSeconds: 4 * 3600,
            raceMaxElevationM: 4300
        )
        #expect(advice?.contains("10-15%") == true,
                "High-altitude framing should mention 10-15% pace cost, got: \(advice ?? "nil")")
    }

    @Test("Altitude advisory uses moderate framing at 2500-3499m")
    func altitudeModerateFraming() {
        let advice = CoachAdviceGenerator.advice(
            for: .longRun,
            intensity: .easy,
            phase: .peak,
            plannedDurationSeconds: 4 * 3600,
            raceMaxElevationM: 2800
        )
        #expect(advice?.contains("5-10%") == true,
                "Moderate-altitude framing should mention 5-10% pace cost, got: \(advice ?? "nil")")
    }

    @Test("Altitude advisory does NOT fire below 2500m")
    func altitudeSilentBelowThreshold() {
        let advice = CoachAdviceGenerator.advice(
            for: .longRun,
            intensity: .easy,
            phase: .peak,
            plannedDurationSeconds: 4 * 3600,
            raceMaxElevationM: 2400
        )
        #expect(advice?.contains("altitude") == false,
                "No altitude advisory below 2500m, got: \(advice ?? "nil")")
    }

    @Test("Altitude advisory does NOT fire when maxElevationM is nil")
    func altitudeSilentWhenNil() {
        let advice = CoachAdviceGenerator.advice(
            for: .longRun,
            intensity: .easy,
            phase: .peak,
            plannedDurationSeconds: 4 * 3600,
            raceMaxElevationM: nil
        )
        #expect(advice?.contains("altitude") == false,
                "No altitude advisory when nil, got: \(advice ?? "nil")")
    }

    @Test("Altitude advisory does NOT fire on base-phase sessions")
    func altitudeSilentInBase() {
        let advice = CoachAdviceGenerator.advice(
            for: .longRun,
            intensity: .easy,
            phase: .base,
            plannedDurationSeconds: 4 * 3600,
            raceMaxElevationM: 4000
        )
        #expect(advice?.contains("altitude") == false,
                "No altitude advisory in base phase, got: \(advice ?? "nil")")
    }

    @Test("Altitude advisory does NOT fire on intervals/tempo (only LR/B2B)")
    func altitudeSilentOnQualitySessions() {
        for type in [SessionType.intervals, .tempo, .verticalGain] {
            let advice = CoachAdviceGenerator.advice(
                for: type,
                intensity: .hard,
                phase: .peak,
                plannedDurationSeconds: 60 * 60,
                raceMaxElevationM: 4000
            )
            #expect(advice?.contains("altitude") == false,
                    "No altitude advisory on \(type), got: \(advice ?? "nil")")
        }
    }

    @Test("Altitude advisory fires on B2B day 2")
    func altitudeOnB2B() {
        let advice = CoachAdviceGenerator.advice(
            for: .backToBack,
            intensity: .easy,
            phase: .peak,
            plannedDurationSeconds: 4 * 3600,
            raceMaxElevationM: 3200
        )
        #expect(advice?.contains("altitude") == true)
    }

    // MARK: - Pole advisory

    @Test("Pole cue fires on VG sessions in build/peak when allowed")
    func poleOnVGBuildPeak() {
        for phase in [TrainingPhase.build, .peak] {
            let advice = CoachAdviceGenerator.advice(
                for: .verticalGain,
                intensity: .hard,
                phase: phase,
                plannedDurationSeconds: 60 * 60,
                racePolesAllowed: true
            )
            #expect(advice?.contains("Poles") == true,
                    "Pole cue should fire on VG in \(phase), got: \(advice ?? "nil")")
        }
    }

    @Test("Pole cue does NOT fire when polesAllowed = false")
    func poleSilentWhenForbidden() {
        let advice = CoachAdviceGenerator.advice(
            for: .verticalGain,
            intensity: .hard,
            phase: .peak,
            plannedDurationSeconds: 60 * 60,
            racePolesAllowed: false
        )
        #expect(advice?.contains("Poles") == false,
                "No pole cue when not allowed, got: \(advice ?? "nil")")
    }

    @Test("Pole cue does NOT fire when polesAllowed is nil")
    func poleSilentWhenNil() {
        let advice = CoachAdviceGenerator.advice(
            for: .verticalGain,
            intensity: .hard,
            phase: .peak,
            plannedDurationSeconds: 60 * 60,
            racePolesAllowed: nil
        )
        #expect(advice?.contains("Poles") == false)
    }

    @Test("Pole cue does NOT fire on non-VG sessions")
    func poleSilentOnNonVG() {
        for type in [SessionType.longRun, .intervals, .tempo, .recovery, .backToBack] {
            let advice = CoachAdviceGenerator.advice(
                for: type,
                intensity: .easy,
                phase: .peak,
                plannedDurationSeconds: 60 * 60,
                racePolesAllowed: true
            )
            #expect(advice?.contains("Poles") == false,
                    "No pole cue on \(type), got: \(advice ?? "nil")")
        }
    }

    @Test("Pole cue does NOT fire in base phase or recovery week")
    func poleSilentInBaseAndRecovery() {
        let baseAdvice = CoachAdviceGenerator.advice(
            for: .verticalGain,
            intensity: .hard,
            phase: .base,
            plannedDurationSeconds: 60 * 60,
            racePolesAllowed: true
        )
        #expect(baseAdvice?.contains("Poles") == false)

        let recoveryAdvice = CoachAdviceGenerator.advice(
            for: .verticalGain,
            intensity: .easy,
            phase: .peak,
            isRecoveryWeek: true,
            plannedDurationSeconds: 60 * 60,
            racePolesAllowed: true
        )
        #expect(recoveryAdvice?.contains("Poles") == false)
    }
}
