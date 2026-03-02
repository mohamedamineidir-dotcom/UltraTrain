import Foundation
import Testing
@testable import UltraTrain

@Suite("ActiveRunViewModel Tests")
struct ActiveRunViewModelTests {

    // MARK: - Helpers

    private let athleteId = UUID()

    private func makeAthlete() -> Athlete {
        Athlete(
            id: athleteId,
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 50,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 50,
            longestRunKm: 30,
            preferredUnit: .metric
        )
    }

    @MainActor
    private func makeSUT(
        runRepo: MockRunRepository = MockRunRepository(),
        planRepo: MockTrainingPlanRepository = MockTrainingPlanRepository(),
        raceRepo: MockRaceRepository = MockRaceRepository(),
        hapticService: MockHapticService = MockHapticService(),
        healthKitService: MockHealthKitService = MockHealthKitService(),
        autoPauseEnabled: Bool = false,
        raceId: UUID? = nil,
        linkedSession: TrainingSession? = nil
    ) -> ActiveRunViewModel {
        ActiveRunViewModel(
            locationService: LocationService(),
            healthKitService: healthKitService,
            runRepository: runRepo,
            planRepository: planRepo,
            raceRepository: raceRepo,
            nutritionRepository: MockNutritionRepository(),
            hapticService: hapticService,
            gearRepository: MockGearRepository(),
            finishEstimateRepository: MockFinishEstimateRepository(),
            athlete: makeAthlete(),
            linkedSession: linkedSession,
            autoPauseEnabled: autoPauseEnabled,
            nutritionRemindersEnabled: false,
            nutritionAlertSoundEnabled: false,
            raceId: raceId
        )
    }

    // MARK: - Tests

    @Test("Initial state is notStarted")
    @MainActor
    func initialState() {
        let vm = makeSUT()

        #expect(vm.runState == .notStarted)
        #expect(vm.elapsedTime == 0)
        #expect(vm.distanceKm == 0)
        #expect(vm.elevationGainM == 0)
        #expect(vm.currentPace == "--:--")
        #expect(vm.currentHeartRate == nil)
        #expect(vm.trackPoints.isEmpty)
        #expect(vm.showSummary == false)
        #expect(vm.isSaving == false)
    }

    @Test("startRun transitions state to running")
    @MainActor
    func startRunTransitionsState() {
        let haptic = MockHapticService()
        let vm = makeSUT(hapticService: haptic)

        vm.startRun()

        #expect(vm.runState == .running)
        #expect(haptic.prepareHapticsCalled)
    }

    @Test("pauseRun transitions from running to paused")
    @MainActor
    func pauseRunTransitionsState() {
        let haptic = MockHapticService()
        let vm = makeSUT(hapticService: haptic)

        vm.startRun()
        vm.pauseRun()

        #expect(vm.runState == .paused)
        #expect(vm.isAutoPaused == false)
        #expect(haptic.playSelectionCalled)
    }

    @Test("pauseRun with auto flag sets isAutoPaused")
    @MainActor
    func autoPauseSetsFlag() {
        let vm = makeSUT()

        vm.startRun()
        vm.pauseRun(auto: true)

        #expect(vm.runState == .paused)
        #expect(vm.isAutoPaused == true)
    }

    @Test("resumeRun transitions from paused to running and accumulates paused duration")
    @MainActor
    func resumeRunTransitionsState() {
        let haptic = MockHapticService()
        let vm = makeSUT(hapticService: haptic)

        vm.startRun()
        vm.pauseRun()

        // Simulate short pause
        vm.pauseStartTime = Date.now.addingTimeInterval(-5)
        vm.resumeRun()

        #expect(vm.runState == .running)
        #expect(vm.pausedDuration >= 4.5) // at least ~5 seconds of pause
        #expect(vm.isAutoPaused == false)
    }

    @Test("stopRun transitions to finished and shows summary")
    @MainActor
    func stopRunShowsSummary() {
        let vm = makeSUT()

        vm.startRun()
        vm.stopRun()

        #expect(vm.runState == .finished)
        #expect(vm.showSummary == true)
    }

    @Test("pauseRun does nothing when not running")
    @MainActor
    func pauseWhenNotRunningIsNoop() {
        let vm = makeSUT()

        vm.pauseRun()

        #expect(vm.runState == .notStarted)
    }

    @Test("resumeRun does nothing when not paused")
    @MainActor
    func resumeWhenNotPausedIsNoop() {
        let vm = makeSUT()

        vm.startRun()
        vm.resumeRun()

        #expect(vm.runState == .running)
    }

    @Test("formattedDistance uses metric by default")
    @MainActor
    func formattedDistanceMetric() {
        let vm = makeSUT()
        vm.distanceKm = 12.345

        let formatted = vm.formattedDistance
        #expect(formatted == "12.35")
    }

    @Test("formattedElevation includes plus sign and unit")
    @MainActor
    func formattedElevation() {
        let vm = makeSUT()
        vm.elevationGainM = 500

        let formatted = vm.formattedElevation
        #expect(formatted.contains("+"))
        #expect(formatted.contains("500"))
    }

    @Test("isRaceModeActive requires raceId and active pacing handler")
    @MainActor
    func raceModeRequiresBothConditions() {
        let vmNoRace = makeSUT(raceId: nil)
        #expect(vmNoRace.isRaceModeActive == false)

        let vmWithRace = makeSUT(raceId: UUID())
        #expect(vmWithRace.isRaceModeActive == false) // pacing handler not yet active
    }

    @Test("saveRun persists run data to repository")
    @MainActor
    func saveRunPersists() async {
        let runRepo = MockRunRepository()
        let haptic = MockHapticService()
        let vm = makeSUT(runRepo: runRepo, hapticService: haptic)

        vm.startRun()
        vm.distanceKm = 10.5
        vm.elevationGainM = 300
        vm.elevationLossM = 280
        vm.elapsedTime = 3600
        vm.stopRun()

        await vm.saveRun(notes: "Test run")

        #expect(runRepo.savedRun != nil)
        #expect(runRepo.savedRun?.distanceKm == 10.5)
        #expect(runRepo.savedRun?.notes == "Test run")
        #expect(vm.lastSavedRun != nil)
        #expect(haptic.playSuccessCalled)
        #expect(vm.isSaving == false)
    }

    @Test("saveRun sets error on failure")
    @MainActor
    func saveRunError() async {
        let runRepo = MockRunRepository()
        runRepo.shouldThrow = true
        let haptic = MockHapticService()
        let vm = makeSUT(runRepo: runRepo, hapticService: haptic)

        vm.startRun()
        vm.stopRun()
        await vm.saveRun(notes: nil)

        #expect(vm.error != nil)
        #expect(haptic.playErrorCalled)
        #expect(vm.isSaving == false)
    }
}
