import Foundation
import Testing
@testable import UltraTrain

@Suite("ActiveRunViewModel Live Race Tests")
struct ActiveRunViewModelLiveRaceTests {

    private let athleteId = UUID()
    private let raceId = UUID()

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
    private func makeViewModel(raceId: UUID? = nil) -> ActiveRunViewModel {
        ActiveRunViewModel(
            locationService: LocationService(),
            healthKitService: MockHealthKitService(),
            runRepository: MockRunRepository(),
            planRepository: MockTrainingPlanRepository(),
            raceRepository: MockRaceRepository(),
            nutritionRepository: MockNutritionRepository(),
            hapticService: MockHapticService(),
            gearRepository: MockGearRepository(),
            finishEstimateRepository: MockFinishEstimateRepository(),
            athlete: makeAthlete(),
            linkedSession: nil,
            autoPauseEnabled: false,
            nutritionRemindersEnabled: false,
            nutritionAlertSoundEnabled: false,
            raceId: raceId
        )
    }

    private func makeCheckpointStates() -> [LiveCheckpointState] {
        [
            LiveCheckpointState(
                id: UUID(), checkpointName: "CP1",
                distanceFromStartKm: 10, hasAidStation: true,
                predictedTime: 3600, actualTime: nil
            ),
            LiveCheckpointState(
                id: UUID(), checkpointName: "CP2",
                distanceFromStartKm: 25, hasAidStation: true,
                predictedTime: 9000, actualTime: nil
            ),
            LiveCheckpointState(
                id: UUID(), checkpointName: "CP3",
                distanceFromStartKm: 40, hasAidStation: false,
                predictedTime: 14400, actualTime: nil
            ),
        ]
    }

    // MARK: - isRaceModeActive

    @Test("isRaceModeActive is true with raceId and checkpoints")
    @MainActor
    func raceModeActiveWithCheckpoints() {
        let vm = makeViewModel(raceId: raceId)
        vm.liveCheckpointStates = makeCheckpointStates()

        #expect(vm.isRaceModeActive)
    }

    @Test("isRaceModeActive is false without raceId")
    @MainActor
    func raceModeInactiveWithoutRaceId() {
        let vm = makeViewModel(raceId: nil)
        vm.liveCheckpointStates = makeCheckpointStates()

        #expect(!vm.isRaceModeActive)
    }

    @Test("isRaceModeActive is false with empty checkpoints")
    @MainActor
    func raceModeInactiveWithEmptyCheckpoints() {
        let vm = makeViewModel(raceId: raceId)

        #expect(!vm.isRaceModeActive)
    }

    // MARK: - nextCheckpoint

    @Test("nextCheckpoint returns first uncrossed checkpoint")
    @MainActor
    func nextCheckpointFirstUncrossed() {
        let vm = makeViewModel(raceId: raceId)
        var states = makeCheckpointStates()
        states[0].actualTime = 3500
        vm.liveCheckpointStates = states

        #expect(vm.nextCheckpoint?.checkpointName == "CP2")
    }

    @Test("nextCheckpoint is nil when all crossed")
    @MainActor
    func nextCheckpointNilWhenAllCrossed() {
        let vm = makeViewModel(raceId: raceId)
        var states = makeCheckpointStates()
        states[0].actualTime = 3500
        states[1].actualTime = 8800
        states[2].actualTime = 14000
        vm.liveCheckpointStates = states

        #expect(vm.nextCheckpoint == nil)
    }

    // MARK: - distanceToNextCheckpointKm

    @Test("distanceToNextCheckpointKm computed correctly")
    @MainActor
    func distanceToNextCheckpoint() {
        let vm = makeViewModel(raceId: raceId)
        vm.liveCheckpointStates = makeCheckpointStates()
        vm.distanceKm = 7.5

        #expect(vm.distanceToNextCheckpointKm == 2.5)
    }

    @Test("distanceToNextCheckpointKm is nil when no next checkpoint")
    @MainActor
    func distanceToNextCheckpointNil() {
        let vm = makeViewModel(raceId: raceId)
        var states = makeCheckpointStates()
        states[0].actualTime = 3500
        states[1].actualTime = 8800
        states[2].actualTime = 14000
        vm.liveCheckpointStates = states

        #expect(vm.distanceToNextCheckpointKm == nil)
    }

    // MARK: - projectedFinishTime

    @Test("projectedFinishTime extrapolates from current pace")
    @MainActor
    func projectedFinishTime() {
        let vm = makeViewModel(raceId: raceId)
        vm.liveCheckpointStates = makeCheckpointStates()
        vm.raceDistanceKm = 50
        vm.distanceKm = 10
        vm.elapsedTime = 3600

        // pace = 3600/10 = 360 s/km, remaining = 40 km
        // projected = 3600 + 40 * 360 = 18000
        #expect(vm.projectedFinishTime == 18000)
    }

    @Test("projectedFinishTime is nil when distance too small")
    @MainActor
    func projectedFinishTimeNilEarly() {
        let vm = makeViewModel(raceId: raceId)
        vm.liveCheckpointStates = makeCheckpointStates()
        vm.raceDistanceKm = 50
        vm.distanceKm = 0.3
        vm.elapsedTime = 120

        #expect(vm.projectedFinishTime == nil)
    }

    // MARK: - Checkpoint Crossing Detection

    @Test("Checkpoint crossing detected when distance passes threshold")
    @MainActor
    func checkpointCrossingDetected() {
        let vm = makeViewModel(raceId: raceId)
        vm.liveCheckpointStates = makeCheckpointStates()
        vm.distanceKm = 10.5
        vm.elapsedTime = 3500

        vm.detectCheckpointCrossings()

        #expect(vm.liveCheckpointStates[0].isCrossed)
        #expect(vm.liveCheckpointStates[0].actualTime == 3500)
        #expect(!vm.liveCheckpointStates[1].isCrossed)
    }

    @Test("activeCrossingBanner set on crossing")
    @MainActor
    func crossingBannerSet() {
        let vm = makeViewModel(raceId: raceId)
        vm.liveCheckpointStates = makeCheckpointStates()
        vm.distanceKm = 10.5
        vm.elapsedTime = 3500

        vm.detectCheckpointCrossings()

        #expect(vm.activeCrossingBanner != nil)
        #expect(vm.activeCrossingBanner?.checkpointName == "CP1")
    }

    @Test("Multiple checkpoints crossed in sequence")
    @MainActor
    func multipleCheckpointsCrossed() {
        let vm = makeViewModel(raceId: raceId)
        vm.liveCheckpointStates = makeCheckpointStates()

        // Cross first checkpoint
        vm.distanceKm = 10.5
        vm.elapsedTime = 3500
        vm.detectCheckpointCrossings()

        #expect(vm.liveCheckpointStates[0].isCrossed)
        #expect(!vm.liveCheckpointStates[1].isCrossed)

        // Cross second checkpoint
        vm.distanceKm = 25.5
        vm.elapsedTime = 9200
        vm.detectCheckpointCrossings()

        #expect(vm.liveCheckpointStates[1].isCrossed)
        #expect(vm.liveCheckpointStates[1].actualTime == 9200)
        #expect(!vm.liveCheckpointStates[2].isCrossed)
    }

    @Test("Crossing two checkpoints at once when large distance jump")
    @MainActor
    func crossTwoCheckpointsAtOnce() {
        let vm = makeViewModel(raceId: raceId)
        vm.liveCheckpointStates = makeCheckpointStates()
        vm.distanceKm = 30
        vm.elapsedTime = 10000

        vm.detectCheckpointCrossings()

        #expect(vm.liveCheckpointStates[0].isCrossed)
        #expect(vm.liveCheckpointStates[1].isCrossed)
        #expect(!vm.liveCheckpointStates[2].isCrossed)
    }

    @Test("dismissCrossingBanner clears the banner")
    @MainActor
    func dismissBanner() {
        let vm = makeViewModel(raceId: raceId)
        vm.liveCheckpointStates = makeCheckpointStates()
        vm.distanceKm = 10.5
        vm.elapsedTime = 3500
        vm.detectCheckpointCrossings()

        #expect(vm.activeCrossingBanner != nil)

        vm.dismissCrossingBanner()

        #expect(vm.activeCrossingBanner == nil)
    }

    @Test("No detection when no live checkpoint states")
    @MainActor
    func noDetectionWithoutStates() {
        let vm = makeViewModel(raceId: raceId)
        vm.distanceKm = 50
        vm.elapsedTime = 18000

        vm.detectCheckpointCrossings()

        #expect(vm.activeCrossingBanner == nil)
    }
}
