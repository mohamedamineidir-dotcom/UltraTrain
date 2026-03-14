import Foundation
import Testing
@testable import UltraTrain

@Suite("SessionTemplateGenerator Tests")
struct SessionTemplateGeneratorTests {

    // MARK: - Helpers

    private func makeSkeleton(
        phase: TrainingPhase = .base,
        isRecovery: Bool = false
    ) -> WeekSkeletonBuilder.WeekSkeleton {
        let start = Date()
        return WeekSkeletonBuilder.WeekSkeleton(
            weekNumber: 1,
            startDate: start,
            endDate: start.addingTimeInterval(6 * 86400),
            phase: phase,
            isRecoveryWeek: isRecovery,
            phaseFocus: phase.defaultFocus
        )
    }

    private func makeVolume(
        km: Double = 50,
        elevation: Double = 2500,
        durationSeconds: TimeInterval = 18000,
        longRunSeconds: TimeInterval = 7200,
        isB2B: Bool = false,
        b2bDay1: TimeInterval = 0,
        b2bDay2: TimeInterval = 0,
        easy1: TimeInterval = 2700,
        easy2: TimeInterval = 2700,
        interval: TimeInterval = 3000,
        vg: TimeInterval = 3000
    ) -> VolumeCalculator.WeekVolume {
        VolumeCalculator.WeekVolume(
            weekNumber: 1,
            targetVolumeKm: km,
            targetElevationGainM: elevation,
            targetDurationSeconds: durationSeconds,
            targetLongRunDurationSeconds: longRunSeconds,
            isB2BWeek: isB2B,
            b2bDay1Seconds: b2bDay1,
            b2bDay2Seconds: b2bDay2,
            baseSessionDurations: VolumeCalculator.BaseSessionDurations(
                easyRun1Seconds: easy1,
                easyRun2Seconds: easy2,
                intervalSeconds: interval,
                vgSeconds: vg
            )
        )
    }

    // MARK: - Session Count

    @Test("each phase generates 7 sessions (one per day)")
    func sevenSessionsPerWeek() {
        let phases: [TrainingPhase] = [.base, .build, .peak, .taper]
        for phase in phases {
            let result = SessionTemplateGenerator.sessions(
                for: makeSkeleton(phase: phase),
                volume: makeVolume(),
                experience: .intermediate
            )
            #expect(result.sessions.count == 7, "Phase \(phase) should produce 7 sessions")
        }
    }

    @Test("recovery week generates 7 sessions")
    func recoveryWeekSevenSessions() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(isRecovery: true),
            volume: makeVolume(),
            experience: .intermediate
        )
        #expect(result.sessions.count == 7)
    }

    // MARK: - Base Phase

    @Test("base phase includes long run")
    func basePhaseHasLongRun() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .base),
            volume: makeVolume(),
            experience: .intermediate
        )

        let longRuns = result.sessions.filter { $0.type == .longRun }
        #expect(longRuns.count >= 1)
    }

    @Test("base phase long run has the longest duration")
    func basePhaseLongRunBiggestDuration() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .base),
            volume: makeVolume(longRunSeconds: 10800),
            experience: .intermediate
        )

        let longRun = result.sessions.filter { $0.type == .longRun }.first
        let maxDuration = result.sessions.max(by: { $0.plannedDuration < $1.plannedDuration })

        #expect(longRun != nil)
        #expect(longRun?.plannedDuration == maxDuration?.plannedDuration)
    }

    // MARK: - Build Phase

    @Test("build phase includes intervals")
    func buildPhaseHasIntervals() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .intermediate
        )

        let intervals = result.sessions.filter { $0.type == .intervals }
        #expect(intervals.count >= 1)
    }

    @Test("build phase includes vertical gain")
    func buildPhaseHasVerticalGain() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .advanced
        )

        let vertical = result.sessions.filter { $0.type == .verticalGain }
        #expect(vertical.count >= 1)
    }

    // MARK: - B2B

    @Test("B2B volume produces back-to-back sessions")
    func b2bVolumeProducesB2BSessions() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(
                isB2B: true,
                b2bDay1: 14400,
                b2bDay2: 18000,
                interval: 0
            ),
            experience: .advanced
        )

        let b2b = result.sessions.filter { $0.type == .backToBack }
        #expect(b2b.count == 1, "B2B volume should produce a back-to-back session")
    }

    @Test("non-B2B volume has no back-to-back sessions")
    func nonB2BNoBackToBack() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .beginner
        )

        let b2b = result.sessions.filter { $0.type == .backToBack }
        #expect(b2b.isEmpty)
    }

    // MARK: - Taper Phase

    @Test("taper phase has reduced volume sessions")
    func taperPhaseReducedVolume() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .taper),
            volume: makeVolume(longRunSeconds: 5400),
            experience: .intermediate
        )

        let longRun = result.sessions.filter { $0.type == .longRun }.first
        #expect(longRun != nil)
    }

    @Test("taper phase includes opener intervals")
    func taperPhaseHasOpenerIntervals() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .taper),
            volume: makeVolume(),
            experience: .intermediate
        )

        let intervals = result.sessions.filter { $0.type == .intervals }
        #expect(intervals.count >= 1)
    }

    // MARK: - Volume Distribution

    @Test("rest sessions have zero duration")
    func restSessionsZeroDuration() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .base),
            volume: makeVolume(),
            experience: .intermediate
        )

        for session in result.sessions where session.type == .rest {
            #expect(session.plannedDuration == 0)
        }
    }

    // MARK: - Nutrition Notes

    @Test("long sessions get nutrition notes")
    func longSessionsGetNutritionNotes() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .base),
            volume: makeVolume(longRunSeconds: 10800),
            experience: .advanced
        )

        let longRun = result.sessions.filter { $0.type == .longRun }.first
        #expect(longRun != nil)
        #expect(longRun?.nutritionNotes != nil)
    }

    // MARK: - Race Override

    @Test("B-race override uses race week templates")
    func bRaceOverrideTemplates() {
        let override = IntermediateRaceHandler.RaceWeekOverride(
            weekNumber: 1,
            raceId: UUID(),
            behavior: .raceWeek(priority: .bRace)
        )
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .intermediate,
            raceOverride: override
        )

        #expect(result.sessions.count == 7)
        let restSessions = result.sessions.filter { $0.type == .rest }
        #expect(restSessions.count >= 4)
    }

    @Test("post-race recovery uses recovery templates")
    func postRaceRecoveryTemplates() {
        let override = IntermediateRaceHandler.RaceWeekOverride(
            weekNumber: 1,
            raceId: UUID(),
            behavior: .postRaceRecovery
        )
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .intermediate,
            raceOverride: override
        )

        let hardSessions = result.sessions.filter { $0.intensity == .hard || $0.intensity == .maxEffort }
        #expect(hardSessions.isEmpty)
    }

    // MARK: - Duration Estimation

    @Test("session durations are positive for non-rest sessions")
    func durationsPositive() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .intermediate
        )

        for session in result.sessions where session.type != .rest {
            #expect(session.plannedDuration > 0)
        }
    }

    // MARK: - Workout Generation

    @Test("interval sessions generate workouts")
    func intervalSessionsGenerateWorkouts() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .intermediate,
            weekNumberInPhase: 0
        )

        let intervals = result.sessions.filter { $0.type == .intervals }
        #expect(!intervals.isEmpty)

        for interval in intervals {
            #expect(interval.intervalWorkoutId != nil)
            let workout = result.workouts.first { $0.id == interval.intervalWorkoutId }
            #expect(workout != nil)
            #expect(!workout!.phases.isEmpty)
        }
    }

    @Test("different weeks produce different interval workouts")
    func differentWeeksProduceDifferentWorkouts() {
        let result0 = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .intermediate,
            weekNumberInPhase: 0
        )
        let result1 = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .intermediate,
            weekNumberInPhase: 1
        )

        let interval0 = result0.sessions.first { $0.type == .intervals }
        let interval1 = result1.sessions.first { $0.type == .intervals }
        #expect(interval0 != nil && interval1 != nil)
        let desc0 = interval0?.description ?? ""
        let desc1 = interval1?.description ?? ""
        #expect(desc0 != desc1, "Week 0 and week 1 interval sessions should differ")
    }

    // MARK: - Session Structure

    @Test("default 5/week has 5 active + 2 rest")
    func defaultFivePerWeek() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .intermediate
        )

        let types = result.sessions.map(\.type)
        let active = types.filter { $0 != .rest }.count
        let rest = types.filter { $0 == .rest }.count

        #expect(active == 5, "Default should have 5 active sessions, got \(active)")
        #expect(rest == 2, "Default should have 2 rest days, got \(rest)")
    }

    @Test("B2B week has long run + back-to-back instead of intervals + long run")
    func b2bWeekSessionStructure() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(
                isB2B: true,
                b2bDay1: 14400,
                b2bDay2: 18000,
                interval: 0
            ),
            experience: .advanced
        )

        let types = result.sessions.map(\.type)
        let longRun = types.filter { $0 == .longRun }.count
        let b2b = types.filter { $0 == .backToBack }.count
        let vg = types.filter { $0 == .verticalGain }.count

        #expect(longRun == 1, "B2B week should have long run day 1")
        #expect(b2b == 1, "B2B week should have back-to-back day 2")
        #expect(vg == 1, "B2B week should keep VG")
    }

    @Test("long run uses explicit duration from volume")
    func longRunUsesExplicitDuration() {
        let expectedDuration: TimeInterval = 14400 // 4 hours
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(longRunSeconds: expectedDuration),
            experience: .intermediate
        )

        let longRun = result.sessions.first { $0.type == .longRun }
        #expect(longRun != nil)
        #expect(longRun?.plannedDuration == expectedDuration)
    }

    // MARK: - Preferred Runs Per Week

    @Test("3/week produces 3 active + 4 rest")
    func threePerWeek() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .intermediate,
            preferredRunsPerWeek: 3
        )

        let types = result.sessions.map(\.type)
        let active = types.filter { $0 != .rest }.count
        let rest = types.filter { $0 == .rest }.count

        #expect(result.sessions.count == 7, "Should always produce 7 day slots")
        #expect(active == 3, "3/week should have 3 active, got \(active)")
        #expect(rest == 4, "3/week should have 4 rest, got \(rest)")
    }

    @Test("3/week includes longRun, intervals, and VG")
    func threePerWeekSessionTypes() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .intermediate,
            preferredRunsPerWeek: 3
        )

        let types = Set(result.sessions.map(\.type))
        #expect(types.contains(.longRun), "3/week should include longRun")
        #expect(types.contains(.intervals), "3/week should include intervals")
        #expect(types.contains(.verticalGain), "3/week should include VG")
    }

    @Test("6/week produces 6 active + 1 rest on normal week")
    func sixPerWeekNormal() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .intermediate,
            preferredRunsPerWeek: 6
        )

        let types = result.sessions.map(\.type)
        let active = types.filter { $0 != .rest }.count
        let rest = types.filter { $0 == .rest }.count

        #expect(active == 6, "6/week normal should have 6 active, got \(active)")
        #expect(rest == 1, "6/week normal should have 1 rest, got \(rest)")
    }

    @Test("6/week produces 5 active on recovery week")
    func sixPerWeekRecovery() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build, isRecovery: true),
            volume: makeVolume(),
            experience: .intermediate,
            preferredRunsPerWeek: 6
        )

        let types = result.sessions.map(\.type)
        let active = types.filter { $0 != .rest }.count

        #expect(active == 5, "6/week recovery should have 5 active, got \(active)")
    }

    @Test("7/week produces 7 active on normal week")
    func sevenPerWeekNormal() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .advanced,
            preferredRunsPerWeek: 7
        )

        let types = result.sessions.map(\.type)
        let active = types.filter { $0 != .rest }.count

        #expect(active == 7, "7/week normal should have 7 active, got \(active)")
    }

    @Test("7/week produces 6 active on recovery week")
    func sevenPerWeekRecovery() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build, isRecovery: true),
            volume: makeVolume(),
            experience: .advanced,
            preferredRunsPerWeek: 7
        )

        let types = result.sessions.map(\.type)
        let active = types.filter { $0 != .rest }.count

        #expect(active == 6, "7/week recovery should have 6 active, got \(active)")
    }

    @Test("3-5/week recovery keeps same session count")
    func threeToFiveRecoverySameCount() {
        for preferred in 3...5 {
            let normal = SessionTemplateGenerator.sessions(
                for: makeSkeleton(phase: .build),
                volume: makeVolume(),
                experience: .intermediate,
                preferredRunsPerWeek: preferred
            )
            let recovery = SessionTemplateGenerator.sessions(
                for: makeSkeleton(phase: .build, isRecovery: true),
                volume: makeVolume(),
                experience: .intermediate,
                preferredRunsPerWeek: preferred
            )

            let normalActive = normal.sessions.filter { $0.type != .rest }.count
            let recoveryActive = recovery.sessions.filter { $0.type != .rest }.count

            #expect(
                normalActive == recoveryActive,
                "\(preferred)/week: normal (\(normalActive)) and recovery (\(recoveryActive)) should match for 3-5"
            )
        }
    }
}
