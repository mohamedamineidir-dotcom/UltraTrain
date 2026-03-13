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
            isRecoveryWeek: isRecovery
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

        // Find the interval session workouts specifically
        let interval0 = result0.sessions.first { $0.type == .intervals }
        let interval1 = result1.sessions.first { $0.type == .intervals }
        #expect(interval0 != nil && interval1 != nil)
        let desc0 = interval0?.description ?? ""
        let desc1 = interval1?.description ?? ""
        #expect(desc0 != desc1, "Week 0 and week 1 interval sessions should differ")
    }

    // MARK: - Session Structure

    @Test("standard week has 2 easy + 1 VG + 1 interval + 1 long run")
    func standardWeekSessionStructure() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .intermediate
        )

        let types = result.sessions.map(\.type)
        let recovery = types.filter { $0 == .recovery }.count
        let vg = types.filter { $0 == .verticalGain }.count
        let intervals = types.filter { $0 == .intervals }.count
        let longRun = types.filter { $0 == .longRun }.count
        let rest = types.filter { $0 == .rest }.count

        #expect(recovery == 2, "Should have 2 easy/recovery runs")
        #expect(vg == 1, "Should have 1 VG session")
        #expect(intervals == 1, "Should have 1 interval session")
        #expect(longRun == 1, "Should have 1 long run")
        #expect(rest == 2, "Should have 2 rest days")
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
}
