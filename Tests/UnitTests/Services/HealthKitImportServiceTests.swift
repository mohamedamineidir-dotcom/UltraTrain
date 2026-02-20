import Foundation
import Testing
@testable import UltraTrain

@Suite("HealthKitImportService Tests")
struct HealthKitImportServiceTests {

    private let athleteId = UUID()

    private func makeService(
        healthKitService: MockHealthKitService = MockHealthKitService(),
        runRepo: MockRunRepository = MockRunRepository(),
        planRepo: MockTrainingPlanRepository = MockTrainingPlanRepository()
    ) -> (HealthKitImportService, MockHealthKitService, MockRunRepository, MockTrainingPlanRepository) {
        let hk = healthKitService
        hk.authorizationStatus = .authorized
        let service = HealthKitImportService(
            healthKitService: hk,
            runRepository: runRepo,
            planRepository: planRepo
        )
        return (service, hk, runRepo, planRepo)
    }

    private func makeWorkout(
        originalUUID: String = UUID().uuidString,
        startDate: Date = Date.now,
        distanceKm: Double = 10,
        elevationGainM: Double = 200,
        duration: TimeInterval = 3600,
        averageHeartRate: Int? = 150,
        maxHeartRate: Int? = 175,
        source: String = "Apple Watch"
    ) -> HealthKitWorkout {
        HealthKitWorkout(
            id: UUID(),
            originalUUID: originalUUID,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(duration),
            distanceKm: distanceKm,
            elevationGainM: elevationGainM,
            duration: duration,
            averageHeartRate: averageHeartRate,
            maxHeartRate: maxHeartRate,
            source: source
        )
    }

    // MARK: - Import

    @Test("No workouts returns zero counts")
    func emptyWorkouts() async throws {
        let (service, _, _, _) = makeService()
        let result = try await service.importNewWorkouts(athleteId: athleteId)
        #expect(result.importedCount == 0)
        #expect(result.skippedCount == 0)
        #expect(result.matchedSessionCount == 0)
    }

    @Test("Imports new workouts and saves to repository")
    func importsNewWorkouts() async throws {
        let hk = MockHealthKitService()
        hk.authorizationStatus = .authorized
        hk.workouts = [
            makeWorkout(distanceKm: 10, duration: 3600),
            makeWorkout(distanceKm: 15, duration: 5400)
        ]

        let (service, _, runRepo, _) = makeService(healthKitService: hk)
        let result = try await service.importNewWorkouts(athleteId: athleteId)

        #expect(result.importedCount == 2)
        #expect(result.skippedCount == 0)
        #expect(runRepo.runs.count == 2)
        #expect(runRepo.runs[0].isHealthKitImport == true)
        #expect(runRepo.runs[1].isHealthKitImport == true)
    }

    @Test("Skips duplicate by healthKitWorkoutUUID")
    func skipsDuplicateByUUID() async throws {
        let workoutUUID = UUID().uuidString
        let hk = MockHealthKitService()
        hk.authorizationStatus = .authorized
        hk.workouts = [makeWorkout(originalUUID: workoutUUID)]

        let runRepo = MockRunRepository()
        runRepo.runs = [CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: Date.now,
            distanceKm: 10,
            elevationGainM: 200,
            elevationLossM: 180,
            duration: 3600,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            pausedDuration: 0,
            isHealthKitImport: true,
            healthKitWorkoutUUID: workoutUUID
        )]

        let (service, _, _, _) = makeService(healthKitService: hk, runRepo: runRepo)
        let result = try await service.importNewWorkouts(athleteId: athleteId)

        #expect(result.importedCount == 0)
        #expect(result.skippedCount == 1)
        #expect(runRepo.runs.count == 1)
    }

    @Test("Skips duplicate by fuzzy date and distance match")
    func skipsDuplicateByFuzzyMatch() async throws {
        let runDate = Date.now.addingTimeInterval(-1800)
        let hk = MockHealthKitService()
        hk.authorizationStatus = .authorized
        hk.workouts = [makeWorkout(startDate: runDate, distanceKm: 10.2)]

        let runRepo = MockRunRepository()
        runRepo.runs = [CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: runDate.addingTimeInterval(300),
            distanceKm: 10.0,
            elevationGainM: 200,
            elevationLossM: 180,
            duration: 3600,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            pausedDuration: 0
        )]

        let (service, _, _, _) = makeService(healthKitService: hk, runRepo: runRepo)
        let result = try await service.importNewWorkouts(athleteId: athleteId)

        #expect(result.importedCount == 0)
        #expect(result.skippedCount == 1)
    }

    @Test("Calculates pace correctly from distance and duration")
    func paceCalculation() async throws {
        let hk = MockHealthKitService()
        hk.authorizationStatus = .authorized
        hk.workouts = [makeWorkout(distanceKm: 10, duration: 3600)]

        let (service, _, runRepo, _) = makeService(healthKitService: hk)
        _ = try await service.importNewWorkouts(athleteId: athleteId)

        let savedRun = runRepo.runs.first!
        #expect(savedRun.averagePaceSecondsPerKm == 360)
    }

    @Test("Sets healthKitWorkoutUUID on imported run")
    func setsWorkoutUUID() async throws {
        let workoutUUID = UUID().uuidString
        let hk = MockHealthKitService()
        hk.authorizationStatus = .authorized
        hk.workouts = [makeWorkout(originalUUID: workoutUUID)]

        let (service, _, runRepo, _) = makeService(healthKitService: hk)
        _ = try await service.importNewWorkouts(athleteId: athleteId)

        let savedRun = runRepo.runs.first!
        #expect(savedRun.healthKitWorkoutUUID == workoutUUID)
        #expect(savedRun.isHealthKitImport == true)
        #expect(savedRun.gpsTrack.isEmpty)
        #expect(savedRun.splits.isEmpty)
    }

    // MARK: - Session Matching

    @Test("Auto-matches imported run to training session")
    func autoMatchesSession() async throws {
        let sessionDate = Date.now
        let session = TrainingSession(
            id: UUID(),
            date: sessionDate,
            type: .longRun,
            plannedDistanceKm: 15,
            plannedElevationGainM: 300,
            plannedDuration: 5400,
            intensity: .moderate,
            description: "Long run",
            isCompleted: false,
            isSkipped: false
        )
        let week = TrainingWeek(
            id: UUID(),
            weekNumber: 1,
            startDate: sessionDate.adding(days: -3),
            endDate: sessionDate.adding(days: 4),
            phase: .base,
            sessions: [session],
            isRecoveryWeek: false,
            targetVolumeKm: 50,
            targetElevationGainM: 1000
        )
        let plan = TrainingPlan(
            id: UUID(),
            athleteId: athleteId,
            targetRaceId: UUID(),
            createdAt: Date.now,
            weeks: [week],
            intermediateRaceIds: [],
            intermediateRaceSnapshots: []
        )

        let hk = MockHealthKitService()
        hk.authorizationStatus = .authorized
        hk.workouts = [makeWorkout(
            startDate: sessionDate,
            distanceKm: 14.5,
            duration: 5200
        )]

        let planRepo = MockTrainingPlanRepository()
        planRepo.activePlan = plan

        let (service, _, runRepo, _) = makeService(
            healthKitService: hk,
            planRepo: planRepo
        )
        let result = try await service.importNewWorkouts(athleteId: athleteId)

        #expect(result.importedCount == 1)
        #expect(result.matchedSessionCount == 1)
        #expect(planRepo.updatedSessions.count == 1)
        #expect(planRepo.updatedSessions[0].isCompleted == true)
        #expect(planRepo.updatedSessions[0].linkedRunId == runRepo.runs.first?.id)
        #expect(runRepo.linkedSessionUpdate?.sessionId == session.id)
    }
}
