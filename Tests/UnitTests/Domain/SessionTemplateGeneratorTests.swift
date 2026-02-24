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
            let sessions = SessionTemplateGenerator.sessions(
                for: makeSkeleton(phase: phase),
                volume: makeVolume(),
                experience: .intermediate
            )
            #expect(sessions.count == 7, "Phase \(phase) should produce 7 sessions")
        }
    }

    @Test("recovery week generates 7 sessions")
    func recoveryWeekSevenSessions() {
        let sessions = SessionTemplateGenerator.sessions(
            for: makeSkeleton(isRecovery: true),
            volume: makeVolume(),
            experience: .intermediate
        )
        #expect(sessions.count == 7)
    }

    // MARK: - Base Phase

    @Test("base phase includes long run")
    func basePhaseHasLongRun() {
        let sessions = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .base),
            volume: makeVolume(),
            experience: .intermediate
        )

        let longRuns = sessions.filter { $0.type == .longRun }
        #expect(longRuns.count >= 1)
    }

    @Test("base phase long run is the biggest volume session")
    func basePhaseLongRunBiggestVolume() {
        let sessions = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .base),
            volume: makeVolume(km: 60),
            experience: .intermediate
        )

        let longRun = sessions.filter { $0.type == .longRun }.first
        let maxDistance = sessions.max(by: { $0.plannedDistanceKm < $1.plannedDistanceKm })

        #expect(longRun != nil)
        #expect(longRun?.plannedDistanceKm == maxDistance?.plannedDistanceKm)
    }

    // MARK: - Build Phase

    @Test("build phase includes intervals")
    func buildPhaseHasIntervals() {
        let sessions = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .intermediate
        )

        let intervals = sessions.filter { $0.type == .intervals }
        #expect(intervals.count >= 1)
    }

    @Test("build phase includes vertical gain for advanced athletes")
    func buildPhaseHasVerticalForAdvanced() {
        let sessions = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .advanced
        )

        let vertical = sessions.filter { $0.type == .verticalGain }
        #expect(vertical.count >= 1)
    }

    @Test("build phase does not include vertical gain for beginners")
    func buildPhaseNoVerticalForBeginners() {
        let sessions = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .beginner
        )

        let vertical = sessions.filter { $0.type == .verticalGain }
        #expect(vertical.isEmpty)
    }

    // MARK: - Peak Phase

    @Test("peak phase includes back-to-back for elite")
    func peakPhaseBackToBackForElite() {
        let sessions = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .peak),
            volume: makeVolume(),
            experience: .elite
        )

        let b2b = sessions.filter { $0.type == .backToBack }
        #expect(b2b.count >= 1)
    }

    @Test("peak phase uses cross-training instead of back-to-back for non-elite")
    func peakPhaseNoCrossTrainingForNonElite() {
        let sessions = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .peak),
            volume: makeVolume(),
            experience: .intermediate
        )

        let b2b = sessions.filter { $0.type == .backToBack }
        let cross = sessions.filter { $0.type == .crossTraining }
        #expect(b2b.isEmpty)
        #expect(cross.count >= 1)
    }

    // MARK: - Taper Phase

    @Test("taper phase has reduced volume sessions")
    func taperPhaseReducedVolume() {
        let sessions = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .taper),
            volume: makeVolume(km: 30),
            experience: .intermediate
        )

        let longRun = sessions.filter { $0.type == .longRun }.first
        #expect(longRun != nil)
        // Long run in taper should have reduced fraction
        #expect(longRun!.plannedDistanceKm < 30) // Less than full volume
    }

    @Test("taper phase includes opener intervals")
    func taperPhaseHasOpenerIntervals() {
        let sessions = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .taper),
            volume: makeVolume(),
            experience: .intermediate
        )

        let intervals = sessions.filter { $0.type == .intervals }
        #expect(intervals.count >= 1)
    }

    // MARK: - Volume Distribution

    @Test("volume distributes to non-rest sessions only")
    func volumeDistributedToNonRestSessions() {
        let sessions = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .base),
            volume: makeVolume(km: 60),
            experience: .intermediate
        )

        let restSessions = sessions.filter { $0.type == .rest }
        for session in restSessions {
            #expect(session.plannedDistanceKm == 0)
        }

        let activeSessions = sessions.filter { $0.type != .rest }
        let totalDistance = activeSessions.reduce(0.0) { $0 + $1.plannedDistanceKm }
        // Total should be close to 60 km
        #expect(abs(totalDistance - 60.0) < 1.0)
    }

    // MARK: - Nutrition Notes

    @Test("long sessions get nutrition notes")
    func longSessionsGetNutritionNotes() {
        let sessions = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .base),
            volume: makeVolume(km: 80, elevation: 4000),
            experience: .advanced
        )

        let longRun = sessions.filter { $0.type == .longRun }.first
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
        let sessions = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .intermediate,
            raceOverride: override
        )

        #expect(sessions.count == 7)
        // B-race week should have mostly rest days
        let restSessions = sessions.filter { $0.type == .rest }
        #expect(restSessions.count >= 4)
    }

    @Test("post-race recovery uses recovery templates")
    func postRaceRecoveryTemplates() {
        let override = IntermediateRaceHandler.RaceWeekOverride(
            weekNumber: 1,
            raceId: UUID(),
            behavior: .postRaceRecovery
        )
        let sessions = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(),
            experience: .intermediate,
            raceOverride: override
        )

        // Recovery templates should have easy intensity
        let hardSessions = sessions.filter { $0.intensity == .hard || $0.intensity == .maxEffort }
        #expect(hardSessions.isEmpty)
    }

    // MARK: - Duration Estimation

    @Test("session durations are positive for non-rest sessions")
    func durationsPositive() {
        let sessions = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .build),
            volume: makeVolume(km: 50),
            experience: .intermediate
        )

        for session in sessions where session.type != .rest {
            #expect(session.plannedDuration > 0)
        }
    }

    @Test("rest sessions have zero duration")
    func restSessionsZeroDuration() {
        let sessions = SessionTemplateGenerator.sessions(
            for: makeSkeleton(phase: .base),
            volume: makeVolume(),
            experience: .intermediate
        )

        for session in sessions where session.type == .rest {
            #expect(session.plannedDuration == 0)
            #expect(session.plannedDistanceKm == 0)
        }
    }
}
