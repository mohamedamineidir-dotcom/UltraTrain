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

    @Test("B2B weeks concentrate volume in long run days and drop intervals")
    func b2bWeeksConcentrateVolume() {
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
        // B2B weeks drop intervals
        #expect(b2b.intervalSeconds == 0,
                "B2B weeks should drop intervals")
        #expect(nonB2B.intervalSeconds > 0,
                "Non-B2B weeks should have intervals")
        // B2B long run (combined) should be much larger than non-B2B
        #expect(b2b.longRunSeconds > nonB2B.longRunSeconds * 2,
                "B2B long run should be much larger than non-B2B")
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

        var totals: [(week: Int, total: TimeInterval, recovery: Bool, isB2B: Bool)] = []
        var previousNonRecoveryWeekTotal: TimeInterval = 0

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
                preferredRunsPerWeek: 5,
                previousNonRecoveryWeekTotal: previousNonRecoveryWeekTotal
            )

            if !isRecovery {
                previousNonRecoveryWeekTotal = d.totalSeconds
            }

            totals.append((week, d.totalSeconds, isRecovery, d.isB2B))
        }

        // Check: between consecutive non-recovery, non-taper, same-B2B-status weeks,
        // volume should not drop by more than 10%
        // B2B weeks are expected to be higher volume than non-B2B, so skip B2B→non-B2B transitions
        var prevWeek: Int?
        var prevTotal: TimeInterval?
        var prevB2B: Bool?
        var violations: [String] = []

        for entry in totals {
            if entry.recovery { prevWeek = nil; prevTotal = nil; prevB2B = nil; continue }
            // Skip taper weeks
            if entry.week >= 23 { continue }

            if let pw = prevWeek, let pt = prevTotal, let pb = prevB2B {
                // Only compare same B2B status weeks (B2B weeks naturally have different totals)
                if pb == entry.isB2B {
                    let dropPercent = (pt - entry.total) / pt * 100
                    if dropPercent > 10 {
                        violations.append(
                            "W\(entry.week + 1): \(Int(entry.total / 60))min dropped \(Int(dropPercent))% from W\(pw + 1): \(Int(pt / 60))min"
                        )
                    }
                }
            }
            prevWeek = entry.week
            prevTotal = entry.total
            prevB2B = entry.isB2B
        }

        #expect(violations.isEmpty,
                "Volume should not zigzag between non-recovery weeks: \(violations.joined(separator: "; "))")
    }

    // MARK: - B2B Experience-Based Caps

    @Test("B2B peak combined for 35h race scales by experience")
    func b2bPeakByExperience() {
        let raceDuration: TimeInterval = 126000 // ~35h DDF
        let totalWeeks = 26
        // Use near-peak week (buildWeekCount=23, halfPoint=11, so peak B2B at week ~22)
        let peakWeek = 22

        let advanced = LongRunCurveCalculator.b2bCombinedDuration(
            weekIndex: peakWeek,
            totalWeeks: totalWeeks,
            experience: .advanced,
            raceDurationSeconds: raceDuration
        )
        let elite = LongRunCurveCalculator.b2bCombinedDuration(
            weekIndex: peakWeek,
            totalWeeks: totalWeeks,
            experience: .elite,
            raceDurationSeconds: raceDuration
        )

        let advancedHours = advanced / 3600
        let eliteHours = elite / 3600
        #expect(advancedHours >= 10 && advancedHours <= 18,
                "Advanced DDF peak B2B should be 10-18h, got \(advancedHours)h")
        #expect(eliteHours >= 14 && eliteHours <= 22,
                "Elite DDF peak B2B should be 14-22h, got \(eliteHours)h")
        #expect(elite > advanced, "Elite should have higher B2B cap than advanced")
    }

    @Test("B2B peak for 14h race remains reasonable")
    func b2bPeakFor14hRace() {
        let raceDuration: TimeInterval = 50400 // ~14h HK100
        let combined = LongRunCurveCalculator.b2bCombinedDuration(
            weekIndex: 20,
            totalWeeks: 26,
            experience: .advanced,
            raceDurationSeconds: raceDuration
        )
        let hours = combined / 3600
        #expect(hours >= 5 && hours <= 10,
                "HK100 advanced peak B2B should be 5-10h, got \(hours)h")
    }

    @Test("B2B weeks have non-zero easy runs and drop intervals")
    func b2bWeeksHaveNonZeroSupportingSessions() {
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
            #expect(d.easyRun1Seconds >= 1800,
                    "B2B easy run should be >= 30min, got \(d.easyRun1Seconds / 60)min")
            #expect(d.easyRun2Seconds >= 1800,
                    "B2B easy run 2 should be >= 30min, got \(d.easyRun2Seconds / 60)min")
            // Intervals are dropped on all B2B weeks
            #expect(d.intervalSeconds == 0,
                    "B2B weeks should drop intervals, got \(d.intervalSeconds / 60)min")
            // B2B combined should be ~85% of total
            let b2bCombined = d.b2bDay1Seconds + d.b2bDay2Seconds
            let b2bFraction = b2bCombined / d.totalSeconds
            #expect(b2bFraction >= 0.70 && b2bFraction <= 0.95,
                    "B2B days should be ~85% of total, got \(Int(b2bFraction * 100))%")
        }
    }

    // MARK: - Campus Coach Reference Validation

    // MARK: - B2B Volume Distribution

    @Test("introduction B2B week volume is ~93.5% of previous non-recovery week")
    func b2bIntroductionWeekVolume() {
        // 24-week plan for advanced athlete, long race → B2B eligible
        let totalWeeks = 24
        let raceDuration: TimeInterval = 126000 // ~35h
        let raceEffKm: Double = 270

        // Simulate weeks to find the first B2B week with proper previousNonRecoveryWeekTotal
        var previousNonRecoveryTotal: TimeInterval = 0

        for week in 0..<totalWeeks {
            let phase: TrainingPhase
            if week < 6 { phase = .base }
            else if week < 19 { phase = .build }
            else if week < 22 { phase = .peak }
            else { phase = .taper }

            let isRecovery = (week + 1) % 4 == 0 && phase != .taper

            let d = LongRunCurveCalculator.durations(
                weekIndex: week,
                totalWeeks: totalWeeks,
                phase: phase,
                isRecoveryWeek: isRecovery,
                experience: .advanced,
                philosophy: .balanced,
                raceDurationSeconds: raceDuration,
                raceEffectiveKm: raceEffKm,
                preferredRunsPerWeek: 5,
                previousNonRecoveryWeekTotal: previousNonRecoveryTotal
            )

            if d.isB2B && previousNonRecoveryTotal > 0 {
                // First B2B week found — check it's an intro week near 93.5% of prev
                let ratio = d.totalSeconds / previousNonRecoveryTotal
                #expect(ratio >= 0.85 && ratio <= 1.0,
                        "Intro B2B total should be ~92-95% of previous, got \(Int(ratio * 100))%")
                return
            }

            if !isRecovery {
                previousNonRecoveryTotal = d.totalSeconds
            }
        }
        // If no B2B found at all, fail
        #expect(Bool(false), "Should have found at least one B2B week in a 24-week plan for advanced 270 effKm race")
    }

    @Test("regular B2B week total exceeds previous non-B2B week total")
    func b2bRegularWeekExceedsPrevious() {
        let totalWeeks = 24
        let raceDuration: TimeInterval = 126000
        let raceEffKm: Double = 270

        var previousNonRecoveryTotal: TimeInterval = 0
        var b2bCount = 0

        for week in 0..<totalWeeks {
            let phase: TrainingPhase
            if week < 6 { phase = .base }
            else if week < 19 { phase = .build }
            else if week < 22 { phase = .peak }
            else { phase = .taper }

            let isRecovery = (week + 1) % 4 == 0 && phase != .taper

            let d = LongRunCurveCalculator.durations(
                weekIndex: week,
                totalWeeks: totalWeeks,
                phase: phase,
                isRecoveryWeek: isRecovery,
                experience: .advanced,
                philosophy: .balanced,
                raceDurationSeconds: raceDuration,
                raceEffectiveKm: raceEffKm,
                preferredRunsPerWeek: 5,
                previousNonRecoveryWeekTotal: previousNonRecoveryTotal
            )

            if d.isB2B {
                b2bCount += 1
                let introCount = LongRunCurveCalculator.effectiveIntroCount(totalWeeks: totalWeeks)
                // After intro weeks, regular B2B should exceed previous
                if b2bCount > introCount && previousNonRecoveryTotal > 0 {
                    #expect(d.totalSeconds >= previousNonRecoveryTotal,
                            "Regular B2B W\(week) total \(Int(d.totalSeconds / 60))min should exceed prev \(Int(previousNonRecoveryTotal / 60))min")
                }
            }

            if !isRecovery {
                previousNonRecoveryTotal = d.totalSeconds
            }
        }
    }

    @Test("B2B days are approximately 85% of total week volume")
    func b2bDaysAre85PercentOfTotal() {
        let totalWeeks = 24
        let raceDuration: TimeInterval = 126000
        var previousNonRecoveryTotal: TimeInterval = 0
        var b2bCount = 0

        for week in 0..<totalWeeks {
            let phase: TrainingPhase
            if week < 6 { phase = .base }
            else if week < 19 { phase = .build }
            else if week < 22 { phase = .peak }
            else { phase = .taper }

            let isRecovery = (week + 1) % 4 == 0 && phase != .taper

            let d = LongRunCurveCalculator.durations(
                weekIndex: week,
                totalWeeks: totalWeeks,
                phase: phase,
                isRecoveryWeek: isRecovery,
                experience: .advanced,
                philosophy: .balanced,
                raceDurationSeconds: raceDuration,
                raceEffectiveKm: 270,
                preferredRunsPerWeek: 5,
                previousNonRecoveryWeekTotal: previousNonRecoveryTotal
            )

            if d.isB2B {
                b2bCount += 1
                let introCount = LongRunCurveCalculator.effectiveIntroCount(totalWeeks: totalWeeks)
                // Check fraction for regular (non-intro) B2B weeks
                if b2bCount > introCount {
                    let b2bCombined = d.b2bDay1Seconds + d.b2bDay2Seconds
                    let fraction = b2bCombined / d.totalSeconds
                    #expect(fraction >= 0.75 && fraction <= 0.92,
                            "B2B days should be ~85% of total, got \(Int(fraction * 100))% at W\(week)")
                }
            }

            if !isRecovery {
                previousNonRecoveryTotal = d.totalSeconds
            }
        }

        #expect(b2bCount > 0, "Should find at least one B2B week")
    }

    @Test("hardest B2B weeks drop all quality sessions (intervals and VG)")
    func b2bHardestWeeksDropAllQuality() {
        let totalWeeks = 24
        let raceDuration: TimeInterval = 126000
        var previousNonRecoveryTotal: TimeInterval = 0

        // Use the same hardest detection formula as the calculator
        let buildWeekCount = max(totalWeeks - max(Int(Double(totalWeeks) * 0.12), 2), 1)
        let halfPoint = buildWeekCount / 2
        let totalB2B = LongRunCurveCalculator.totalB2BWeekCount(totalWeeks: totalWeeks)
        let hardestCount = AppConfiguration.Training.b2bHardestWeekCount

        var hardestFound = 0
        var nonHardestB2BFound = 0

        for week in 0..<totalWeeks {
            let phase: TrainingPhase
            if week < 6 { phase = .base }
            else if week < 19 { phase = .build }
            else if week < 22 { phase = .peak }
            else { phase = .taper }

            let isRecovery = (week + 1) % 4 == 0 && phase != .taper

            let d = LongRunCurveCalculator.durations(
                weekIndex: week,
                totalWeeks: totalWeeks,
                phase: phase,
                isRecoveryWeek: isRecovery,
                experience: .advanced,
                philosophy: .balanced,
                raceDurationSeconds: raceDuration,
                raceEffectiveKm: 270,
                preferredRunsPerWeek: 5,
                previousNonRecoveryWeekTotal: previousNonRecoveryTotal
            )

            if d.isB2B {
                let b2bIdx = max(week - halfPoint, 0) / 2
                let isHardest = b2bIdx >= totalB2B - hardestCount

                if isHardest {
                    hardestFound += 1
                    #expect(d.intervalSeconds == 0,
                            "Hardest B2B W\(week) should have intervals=0, got \(d.intervalSeconds / 60)min")
                    #expect(d.vgSeconds == 0,
                            "Hardest B2B W\(week) should have VG=0, got \(d.vgSeconds / 60)min")
                } else {
                    nonHardestB2BFound += 1
                }
            }

            if !isRecovery {
                previousNonRecoveryTotal = d.totalSeconds
            }
        }

        #expect(hardestFound >= 1,
                "Should find at least 1 hardest B2B week, found \(hardestFound)")
        #expect(nonHardestB2BFound >= 1,
                "Should also find non-hardest B2B weeks, found \(nonHardestB2BFound)")
    }

    @Test("regular B2B weeks drop intervals but keep VG")
    func b2bRegularWeeksDropIntervals() {
        let totalWeeks = 24
        let raceDuration: TimeInterval = 126000
        var previousNonRecoveryTotal: TimeInterval = 0
        var b2bWeekDurations: [(week: Int, durations: LongRunCurveCalculator.WeekDurations)] = []

        for week in 0..<totalWeeks {
            let phase: TrainingPhase
            if week < 6 { phase = .base }
            else if week < 19 { phase = .build }
            else if week < 22 { phase = .peak }
            else { phase = .taper }

            let isRecovery = (week + 1) % 4 == 0 && phase != .taper

            let d = LongRunCurveCalculator.durations(
                weekIndex: week,
                totalWeeks: totalWeeks,
                phase: phase,
                isRecoveryWeek: isRecovery,
                experience: .advanced,
                philosophy: .balanced,
                raceDurationSeconds: raceDuration,
                raceEffectiveKm: 270,
                preferredRunsPerWeek: 5,
                previousNonRecoveryWeekTotal: previousNonRecoveryTotal
            )

            if d.isB2B {
                b2bWeekDurations.append((week, d))
            }

            if !isRecovery {
                previousNonRecoveryTotal = d.totalSeconds
            }
        }

        let hardestCount = AppConfiguration.Training.b2bHardestWeekCount
        // Non-hardest B2B weeks should have intervals=0 but VG > 0
        let regularB2B = b2bWeekDurations.dropLast(hardestCount)
        for entry in regularB2B {
            #expect(entry.durations.intervalSeconds == 0,
                    "Regular B2B W\(entry.week) should drop intervals, got \(entry.durations.intervalSeconds / 60)min")
            #expect(entry.durations.vgSeconds > 0,
                    "Regular B2B W\(entry.week) should keep VG, got \(entry.durations.vgSeconds / 60)min")
        }
    }

    @Test("short plans (≤18 weeks) have only 1 intro B2B week")
    func b2bShortPlanHasOneIntroWeek() {
        let shortIntro = LongRunCurveCalculator.effectiveIntroCount(totalWeeks: 16)
        #expect(shortIntro == 1, "16-week plan should have 1 intro B2B week, got \(shortIntro)")

        let shortBoundary = LongRunCurveCalculator.effectiveIntroCount(totalWeeks: 18)
        #expect(shortBoundary == 1, "18-week plan should have 1 intro B2B week, got \(shortBoundary)")

        let longPlan = LongRunCurveCalculator.effectiveIntroCount(totalWeeks: 20)
        #expect(longPlan == 2, "20-week plan should have 2 intro B2B weeks, got \(longPlan)")
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
