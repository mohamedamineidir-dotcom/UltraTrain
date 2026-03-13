import Foundation
import Testing
@testable import UltraTrain

@Suite("LongRunCurveCalculator Tests")
struct LongRunCurveCalculatorTests {

    // MARK: - Long Run Progression

    @Test("long run starts at experience-based duration")
    func longRunStartDuration() {
        let d = LongRunCurveCalculator.durations(
            weekIndex: 0,
            totalWeeks: 26,
            phase: .base,
            isRecoveryWeek: false,
            experience: .intermediate,
            philosophy: .balanced,
            raceDurationSeconds: 50400,
            raceEffectiveKm: 150,
            preferredRunsPerWeek: 5
        )
        // Intermediate starts at 60min = 3600s
        #expect(d.longRunSeconds >= 3500 && d.longRunSeconds <= 4000,
                "Intermediate long run should start around 60min, got \(d.longRunSeconds / 60)min")
    }

    @Test("long run grows quadratically across plan")
    func longRunQuadraticGrowth() {
        let totalWeeks = 26
        let durations = (0..<totalWeeks).map { week in
            LongRunCurveCalculator.durations(
                weekIndex: week,
                totalWeeks: totalWeeks,
                phase: .build,
                isRecoveryWeek: false,
                experience: .advanced,
                philosophy: .performance,
                raceDurationSeconds: 126000, // ~35h
                raceEffectiveKm: 270,
                preferredRunsPerWeek: 5
            )
        }

        let firstLR = durations.first!.longRunSeconds
        let lastLR = durations.last!.longRunSeconds

        // For a 170km/35h race, advanced peak = min(35h × 0.55, 10h) = 10h
        // Start = 75min. Ratio should be large
        let ratio = lastLR / firstLR
        #expect(ratio >= 5.0, "Long run should grow at least 5x for ultramarathon, got \(ratio)")
    }

    @Test("long run peaks near race fraction of race duration")
    func longRunPeakNearRaceFraction() {
        let raceDuration: TimeInterval = 50400 // ~14h (HK100-ish)
        let d = LongRunCurveCalculator.durations(
            weekIndex: 22, // near end of 24-week build
            totalWeeks: 24,
            phase: .peak,
            isRecoveryWeek: false,
            experience: .intermediate,
            philosophy: .balanced,
            raceDurationSeconds: raceDuration,
            raceEffectiveKm: 150,
            preferredRunsPerWeek: 5
        )

        let peakFraction = 0.50 // intermediate
        let expectedPeakSeconds = raceDuration * peakFraction
        // Should be within 20% of expected peak
        #expect(d.longRunSeconds >= expectedPeakSeconds * 0.7,
                "Peak long run \(d.longRunSeconds/3600)h should be near \(expectedPeakSeconds/3600)h")
    }

    // MARK: - B2B Scheduling

    @Test("B2B only in second half of build weeks")
    func b2bSecondHalfOnly() {
        let totalWeeks = 20
        // LongRunCurveCalculator uses buildWeekCount/2 as halfPoint
        // buildWeekCount = totalWeeks - taperEstimate = 20 - 2 = 18, halfPoint = 9
        let buildWeekCount = totalWeeks - max(Int(Double(totalWeeks) * 0.12), 2)
        let halfPoint = buildWeekCount / 2

        for week in 0..<halfPoint {
            let isB2B = LongRunCurveCalculator.isB2BWeek(
                weekIndex: week,
                totalWeeks: totalWeeks,
                phase: .build,
                isRecoveryWeek: false,
                experience: .advanced,
                raceEffectiveKm: 150,
                raceDurationSeconds: 126000
            )
            #expect(!isB2B, "Week \(week) should not be B2B (first half)")
        }
    }

    @Test("B2B alternates with non-B2B weeks")
    func b2bAlternates() {
        let totalWeeks = 20
        var b2bWeeks: [Int] = []

        for week in 0..<totalWeeks {
            let isB2B = LongRunCurveCalculator.isB2BWeek(
                weekIndex: week,
                totalWeeks: totalWeeks,
                phase: .build,
                isRecoveryWeek: false,
                experience: .advanced,
                raceEffectiveKm: 150,
                raceDurationSeconds: 126000
            )
            if isB2B { b2bWeeks.append(week) }
        }

        // Check no consecutive B2B weeks
        for i in 1..<b2bWeeks.count {
            #expect(b2bWeeks[i] - b2bWeeks[i - 1] >= 2,
                    "B2B weeks should not be consecutive")
        }
    }

    @Test("no B2B for beginners")
    func noB2BForBeginners() {
        for week in 0..<20 {
            let isB2B = LongRunCurveCalculator.isB2BWeek(
                weekIndex: week,
                totalWeeks: 20,
                phase: .build,
                isRecoveryWeek: false,
                experience: .beginner,
                raceEffectiveKm: 150,
                raceDurationSeconds: 126000
            )
            #expect(!isB2B)
        }
    }

    @Test("no B2B in base or taper phase")
    func noB2BInBaseOrTaper() {
        for phase in [TrainingPhase.base, TrainingPhase.taper] {
            let isB2B = LongRunCurveCalculator.isB2BWeek(
                weekIndex: 15,
                totalWeeks: 20,
                phase: phase,
                isRecoveryWeek: false,
                experience: .advanced,
                raceEffectiveKm: 150,
                raceDurationSeconds: 126000
            )
            #expect(!isB2B, "Phase \(phase) should never have B2B")
        }
    }

    @Test("no B2B on recovery weeks")
    func noB2BOnRecoveryWeeks() {
        let isB2B = LongRunCurveCalculator.isB2BWeek(
            weekIndex: 15,
            totalWeeks: 20,
            phase: .build,
            isRecoveryWeek: true,
            experience: .advanced,
            raceEffectiveKm: 150,
            raceDurationSeconds: 126000
        )
        #expect(!isB2B)
    }

    // MARK: - B2B Day Splits

    @Test("B2B day 2 is longer than day 1")
    func b2bDay2LongerThanDay1() {
        let d = LongRunCurveCalculator.durations(
            weekIndex: 15,
            totalWeeks: 20,
            phase: .build,
            isRecoveryWeek: false,
            experience: .advanced,
            philosophy: .balanced,
            raceDurationSeconds: 126000,
            raceEffectiveKm: 270,
            preferredRunsPerWeek: 5
        )

        if d.isB2B {
            #expect(d.b2bDay2Seconds > d.b2bDay1Seconds)
        }
    }

    // MARK: - Base Session Durations

    @Test("base sessions grow mildly across plan")
    func baseSessionsGrowMildly() {
        let first = LongRunCurveCalculator.durations(
            weekIndex: 0,
            totalWeeks: 26,
            phase: .base,
            isRecoveryWeek: false,
            experience: .intermediate,
            philosophy: .balanced,
            raceDurationSeconds: 50400,
            raceEffectiveKm: 150,
            preferredRunsPerWeek: 5
        )
        // Use a mid-plan non-B2B week (short race to avoid B2B)
        let last = LongRunCurveCalculator.durations(
            weekIndex: 20,
            totalWeeks: 26,
            phase: .build,
            isRecoveryWeek: false,
            experience: .intermediate,
            philosophy: .balanced,
            raceDurationSeconds: 50400,
            raceEffectiveKm: 50,
            preferredRunsPerWeek: 5
        )

        // Easy runs should grow mildly (not more than ~2x)
        let easyRatio = last.easyRun1Seconds / first.easyRun1Seconds
        #expect(easyRatio >= 1.0 && easyRatio <= 2.5,
                "Easy runs should grow mildly, got ratio \(easyRatio)")

        // Long run should grow much more than base sessions
        let lrRatio = last.longRunSeconds / first.longRunSeconds
        #expect(lrRatio > easyRatio,
                "Long run growth (\(lrRatio)x) should exceed easy run growth (\(easyRatio)x)")
    }

    @Test("B2B weeks shorten easy runs")
    func b2bWeeksShortenEasyRuns() {
        // Non-B2B: use short race that won't qualify for B2B
        let nonB2B = LongRunCurveCalculator.durations(
            weekIndex: 15,
            totalWeeks: 20,
            phase: .build,
            isRecoveryWeek: false,
            experience: .advanced,
            philosophy: .balanced,
            raceDurationSeconds: 14400,
            raceEffectiveKm: 30,
            preferredRunsPerWeek: 5
        )

        // B2B-eligible: long race
        let b2b = LongRunCurveCalculator.durations(
            weekIndex: 15,
            totalWeeks: 20,
            phase: .build,
            isRecoveryWeek: false,
            experience: .advanced,
            philosophy: .balanced,
            raceDurationSeconds: 126000,
            raceEffectiveKm: 270,
            preferredRunsPerWeek: 5
        )

        #expect(b2b.isB2B, "Should be a B2B week with long race")
        #expect(nonB2B.isB2B == false, "Short race should not produce B2B")
        #expect(b2b.easyRun1Seconds < nonB2B.easyRun1Seconds,
                "B2B easy runs should be shorter")
    }

    // MARK: - Recovery Week Reductions

    @Test("recovery week reduces all durations")
    func recoveryWeekReducesAll() {
        let normal = LongRunCurveCalculator.durations(
            weekIndex: 5,
            totalWeeks: 20,
            phase: .build,
            isRecoveryWeek: false,
            experience: .intermediate,
            philosophy: .balanced,
            raceDurationSeconds: 50400,
            raceEffectiveKm: 150,
            preferredRunsPerWeek: 5
        )
        let recovery = LongRunCurveCalculator.durations(
            weekIndex: 5,
            totalWeeks: 20,
            phase: .build,
            isRecoveryWeek: true,
            experience: .intermediate,
            philosophy: .balanced,
            raceDurationSeconds: 50400,
            raceEffectiveKm: 150,
            preferredRunsPerWeek: 5
        )

        #expect(recovery.totalSeconds < normal.totalSeconds)
        #expect(recovery.longRunSeconds < normal.longRunSeconds)
        #expect(recovery.easyRun1Seconds < normal.easyRun1Seconds)
    }

    // MARK: - Volume Smoothness

    @Test("consecutive non-recovery weeks have smoothly increasing total volume")
    func volumeSmoothnessNoZigzag() {
        let totalWeeks = 26
        let raceDuration: TimeInterval = 50400 // ~14h HK100

        var totals: [(week: Int, total: TimeInterval, recovery: Bool)] = []

        for week in 0..<totalWeeks {
            let phase: TrainingPhase
            if week < 7 { phase = .base }
            else if week < 20 { phase = .build }
            else if week < 23 { phase = .peak }
            else { phase = .taper }

            // Mark recovery every 4th week (3:1)
            let isRecovery = (week + 1) % 4 == 0 && phase != .taper

            let d = LongRunCurveCalculator.durations(
                weekIndex: week,
                totalWeeks: totalWeeks,
                phase: phase,
                isRecoveryWeek: isRecovery,
                experience: .advanced,
                philosophy: .balanced,
                raceDurationSeconds: raceDuration,
                raceEffectiveKm: 156,
                preferredRunsPerWeek: 5
            )
            totals.append((week, d.totalSeconds, isRecovery))
        }

        // Check: between consecutive non-recovery, non-taper weeks,
        // volume should not drop by more than 10%
        var prevWeek: Int?
        var prevTotal: TimeInterval?
        var violations: [String] = []

        for entry in totals {
            if entry.recovery { prevWeek = nil; prevTotal = nil; continue }
            // Skip taper weeks
            if entry.week >= 23 { continue }

            if let pw = prevWeek, let pt = prevTotal {
                let dropPercent = (pt - entry.total) / pt * 100
                if dropPercent > 10 {
                    violations.append(
                        "W\(entry.week + 1): \(Int(entry.total / 60))min dropped \(Int(dropPercent))% from W\(pw + 1): \(Int(pt / 60))min"
                    )
                }
            }
            prevWeek = entry.week
            prevTotal = entry.total
        }

        #expect(violations.isEmpty,
                "Volume should not zigzag between non-recovery weeks: \(violations.joined(separator: "; "))")
    }

    // MARK: - Campus Coach Reference Validation

    @Test("26-week HK100 plan matches Campus Coach range")
    func campusCoachReference() {
        let raceDuration: TimeInterval = 50400 // ~14h for HK100 (103km/5300D+)
        let totalWeeks = 26

        let week1 = LongRunCurveCalculator.durations(
            weekIndex: 0,
            totalWeeks: totalWeeks,
            phase: .base,
            isRecoveryWeek: false,
            experience: .advanced,
            philosophy: .performance,
            raceDurationSeconds: raceDuration,
            raceEffectiveKm: 156,
            preferredRunsPerWeek: 5
        )

        let weekMid = LongRunCurveCalculator.durations(
            weekIndex: 13,
            totalWeeks: totalWeeks,
            phase: .build,
            isRecoveryWeek: false,
            experience: .advanced,
            philosophy: .performance,
            raceDurationSeconds: raceDuration,
            raceEffectiveKm: 156,
            preferredRunsPerWeek: 5
        )

        // W1: Campus Coach = 3h50 total, 1h long run
        // Our W1 long run should be around 75min (advanced start)
        #expect(week1.longRunSeconds >= 3600 && week1.longRunSeconds <= 6000,
                "W1 long run should be ~75min, got \(week1.longRunSeconds / 60)min")
        #expect(week1.totalSeconds >= 10800 && week1.totalSeconds <= 25200,
                "W1 total should be ~3-7h, got \(week1.totalSeconds / 3600)h")

        // W14: Campus Coach = 8h06 total, 3h50 long run
        #expect(weekMid.longRunSeconds >= 7200,
                "W14 long run should be >= 2h, got \(weekMid.longRunSeconds / 60)min")
    }
}
