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
        elevation: Double = 2500
    ) -> VolumeCalculator.WeekVolume {
        VolumeCalculator.WeekVolume(
            weekNumber: 1,
            targetVolumeKm: km,
            targetElevationGainM: elevation
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
            volume: makeVolume(km: 60),
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

    @Test("build phase includes vertical gain for advanced athletes")
    func buildPhaseHasVerticalForAdvanced() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .advanced
        )

        let vertical = result.sessions.filter { $0.type == .verticalGain }
        #expect(vertical.count >= 1)
    }

    @Test("build phase does not include vertical gain for beginners")
    func buildPhaseNoVerticalForBeginners() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .beginner
        )

        let vertical = result.sessions.filter { $0.type == .verticalGain }
        #expect(vertical.isEmpty)
    }

    // MARK: - Peak Phase

    @Test("peak phase includes back-to-back for elite with high effective km")
    func peakPhaseBackToBackForElite() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .peak),
            volume: makeVolume(),
            experience: .elite,
            raceEffectiveKm: 150
        )

        let b2b = result.sessions.filter { $0.type == .backToBack }
        #expect(b2b.count >= 1)
    }

    @Test("peak phase has no back-to-back for beginner")
    func peakPhaseNoB2BForBeginner() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .peak),
            volume: makeVolume(),
            experience: .beginner,
            raceEffectiveKm: 50
        )

        let b2b = result.sessions.filter { $0.type == .backToBack }
        #expect(b2b.isEmpty)
    }

    // MARK: - Taper Phase

    @Test("taper phase has reduced volume sessions")
    func taperPhaseReducedVolume() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .taper),
            volume: makeVolume(km: 30),
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

    @Test("volume distributes to non-rest sessions only")
    func volumeDistributedToNonRestSessions() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .base),
            volume: makeVolume(km: 60),
            experience: .intermediate
        )

        let restSessions = result.sessions.filter { $0.type == .rest }
        for session in restSessions {
            #expect(session.plannedDistanceKm == 0)
        }
    }

    // MARK: - Nutrition Notes

    @Test("long sessions get nutrition notes")
    func longSessionsGetNutritionNotes() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .base),
            volume: makeVolume(km: 80, elevation: 4000),
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
            volume: makeVolume(km: 50),
            experience: .intermediate
        )

        for session in result.sessions where session.type != .rest {
            #expect(session.plannedDuration > 0)
        }
    }

    @Test("rest sessions have zero duration")
    func restSessionsZeroDuration() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .base),
            volume: makeVolume(),
            experience: .intermediate
        )

        for session in result.sessions where session.type == .rest {
            #expect(session.plannedDuration == 0)
            #expect(session.plannedDistanceKm == 0)
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

        let desc0 = result0.workouts.first?.descriptionText ?? ""
        let desc1 = result1.workouts.first?.descriptionText ?? ""
        #expect(desc0 != desc1, "Week 0 and week 1 should have different workout descriptions")
    }

    // MARK: - Cross-Training Restriction

    @Test("beginner has no cross-training sessions in base phase")
    func beginnerNoCrossTrainingBase() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .base),
            volume: makeVolume(),
            experience: .beginner
        )

        let crossTraining = result.sessions.filter { $0.type == .crossTraining }
        #expect(crossTraining.isEmpty, "Beginner should have no cross-training")
    }

    @Test("intermediate has no cross-training sessions in build phase")
    func intermediateNoCrossTrainingBuild() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .intermediate
        )

        let crossTraining = result.sessions.filter { $0.type == .crossTraining }
        #expect(crossTraining.isEmpty, "Intermediate should have no cross-training")
    }

    @Test("elite keeps cross-training in base phase")
    func eliteKeepsCrossTrainingBase() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .base),
            volume: makeVolume(),
            experience: .elite
        )

        let crossTraining = result.sessions.filter { $0.type == .crossTraining }
        #expect(!crossTraining.isEmpty, "Elite should have cross-training")
    }

    @Test("elite keeps cross-training in recovery week")
    func eliteKeepsCrossTrainingRecovery() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(isRecovery: true),
            volume: makeVolume(),
            experience: .elite
        )

        let crossTraining = result.sessions.filter { $0.type == .crossTraining }
        #expect(!crossTraining.isEmpty, "Elite recovery week should have cross-training")
    }

    @Test("advanced gets recovery run instead of cross-training in non-recovery week")
    func advancedGetsRecoveryRunInsteadOfCrossTraining() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .base),
            volume: makeVolume(),
            experience: .advanced
        )

        let crossTraining = result.sessions.filter { $0.type == .crossTraining }
        #expect(crossTraining.isEmpty, "Advanced non-recovery should replace cross-training with recovery run")
    }

    @Test("advanced keeps cross-training in recovery week")
    func advancedKeepsCrossTrainingRecovery() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(isRecovery: true),
            volume: makeVolume(),
            experience: .advanced
        )

        let crossTraining = result.sessions.filter { $0.type == .crossTraining }
        #expect(!crossTraining.isEmpty, "Advanced recovery week should have cross-training")
    }

    @Test("beginner gets rest instead of cross-training in recovery week")
    func beginnerGetsRestInsteadOfCrossTrainingRecovery() {
        let result = SessionTemplateGenerator.sessions(
            for: makeSkeleton(isRecovery: true),
            volume: makeVolume(),
            experience: .beginner
        )

        let crossTraining = result.sessions.filter { $0.type == .crossTraining }
        #expect(crossTraining.isEmpty, "Beginner should never have cross-training, even in recovery week")
    }
}
