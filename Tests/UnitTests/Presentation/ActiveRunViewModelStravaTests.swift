import Foundation
import Testing
@testable import UltraTrain

@Suite("ActiveRunViewModel Strava Tests")
@MainActor
struct ActiveRunViewModelStravaTests {

    private func makeAthlete() -> Athlete {
        Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date.now)!,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 55,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 50,
            longestRunKm: 30,
            preferredUnit: .metric
        )
    }

    private func makeRun(athleteId: UUID) -> CompletedRun {
        CompletedRun(
            id: UUID(),
            athleteId: athleteId,
            date: Date.now,
            distanceKm: 10,
            elevationGainM: 200,
            elevationLossM: 180,
            duration: 3600,
            averageHeartRate: 145,
            maxHeartRate: 170,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [
                TrackPoint(latitude: 45.0, longitude: 6.0, altitudeM: 1000, timestamp: Date.now, heartRate: 140)
            ],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    private func makeViewModel(
        stravaAutoUploadEnabled: Bool = false,
        queueService: MockStravaUploadQueueService? = MockStravaUploadQueueService()
    ) -> ActiveRunViewModel {
        ActiveRunViewModel(
            locationService: LocationService(),
            healthKitService: MockHealthKitService(),
            runRepository: MockRunRepository(),
            planRepository: MockTrainingPlanRepository(),
            raceRepository: MockRaceRepository(),
            nutritionRepository: MockNutritionRepository(),
            hapticService: MockHapticService(),
            stravaUploadQueueService: queueService,
            gearRepository: MockGearRepository(),
            finishEstimateRepository: MockFinishEstimateRepository(),
            athlete: makeAthlete(),
            linkedSession: nil,
            autoPauseEnabled: false,
            nutritionRemindersEnabled: false,
            nutritionAlertSoundEnabled: false,
            stravaAutoUploadEnabled: stravaAutoUploadEnabled,
            raceId: nil
        )
    }

    @Test("Upload to Strava enqueues run to queue service")
    func uploadToStravaEnqueues() async throws {
        let queueService = MockStravaUploadQueueService()
        let vm = makeViewModel(queueService: queueService)
        let athlete = makeAthlete()
        let run = makeRun(athleteId: athlete.id)
        vm.lastSavedRun = run

        vm.uploadToStrava()

        // Allow the background Task to execute
        try await Task.sleep(for: .milliseconds(100))

        #expect(queueService.enqueuedRunIds.contains(run.id))
        #expect(queueService.processQueueCalled == true)
    }

    @Test("Upload to Strava does nothing without saved run")
    func uploadToStravaNoRun() async throws {
        let queueService = MockStravaUploadQueueService()
        let vm = makeViewModel(queueService: queueService)

        vm.uploadToStrava()
        try await Task.sleep(for: .milliseconds(100))

        #expect(queueService.enqueuedRunIds.isEmpty)
    }
}
