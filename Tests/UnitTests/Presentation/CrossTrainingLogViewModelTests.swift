import Testing
import Foundation
@testable import UltraTrain

@Suite("CrossTrainingLogViewModel Tests")
struct CrossTrainingLogViewModelTests {

    @MainActor
    private func makeViewModel(
        runRepo: MockRunRepository = MockRunRepository(),
        athleteRepo: MockAthleteRepository = MockAthleteRepository()
    ) -> (CrossTrainingLogViewModel, MockRunRepository, MockAthleteRepository) {
        let vm = CrossTrainingLogViewModel(
            runRepository: runRepo,
            athleteRepository: athleteRepo
        )
        return (vm, runRepo, athleteRepo)
    }

    private func makeAthlete() -> Athlete {
        Athlete(
            id: UUID(),
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date())!,
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

    // MARK: - Initial State

    @Test("Initial state has cycling as default activity")
    @MainActor
    func initialState() {
        let (vm, _, _) = makeViewModel()
        #expect(vm.activityType == .cycling)
        #expect(vm.durationMinutes == 45)
        #expect(vm.isSaving == false)
        #expect(vm.didSave == false)
        #expect(vm.error == nil)
    }

    // MARK: - Non-Running Types

    @Test("Non-running types exclude running and trail running")
    @MainActor
    func nonRunningTypes() {
        let (vm, _, _) = makeViewModel()
        #expect(!vm.nonRunningTypes.contains(.running))
        #expect(!vm.nonRunningTypes.contains(.trailRunning))
        #expect(vm.nonRunningTypes.contains(.cycling))
        #expect(vm.nonRunningTypes.contains(.swimming))
        #expect(vm.nonRunningTypes.contains(.strength))
    }

    // MARK: - Conditional Fields

    @Test("Distance field shown for distance-based activities")
    @MainActor
    func distanceFieldShownForCycling() {
        let (vm, _, _) = makeViewModel()
        vm.activityType = .cycling
        #expect(vm.showDistanceField == true)
        vm.activityType = .swimming
        #expect(vm.showDistanceField == true)
    }

    @Test("Distance field hidden for non-distance activities")
    @MainActor
    func distanceFieldHiddenForStrength() {
        let (vm, _, _) = makeViewModel()
        vm.activityType = .strength
        #expect(vm.showDistanceField == false)
        vm.activityType = .yoga
        #expect(vm.showDistanceField == false)
    }

    @Test("Elevation field shown for GPS activities")
    @MainActor
    func elevationFieldShownForHiking() {
        let (vm, _, _) = makeViewModel()
        vm.activityType = .hiking
        #expect(vm.showElevationField == true)
        vm.activityType = .cycling
        #expect(vm.showElevationField == true)
    }

    @Test("Elevation field hidden for non-GPS activities")
    @MainActor
    func elevationFieldHiddenForSwimming() {
        let (vm, _, _) = makeViewModel()
        vm.activityType = .swimming
        #expect(vm.showElevationField == false)
    }

    // MARK: - Save

    @Test("Save creates CompletedRun with correct activity type")
    @MainActor
    func saveCreatesRun() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let (vm, runRepo, _) = makeViewModel(athleteRepo: athleteRepo)

        vm.activityType = .cycling
        vm.durationMinutes = 60
        vm.distanceKm = 30

        await vm.save()

        #expect(vm.didSave == true)
        #expect(vm.error == nil)
        #expect(runRepo.savedRun?.activityType == .cycling)
        #expect(runRepo.savedRun?.distanceKm == 30)
        #expect(runRepo.savedRun?.duration == 3600)
    }

    @Test("Save fails without athlete profile")
    @MainActor
    func saveFailsWithoutAthlete() async {
        let (vm, _, _) = makeViewModel()

        await vm.save()

        #expect(vm.didSave == false)
        #expect(vm.error != nil)
    }

    @Test("Save handles repository error")
    @MainActor
    func saveHandlesError() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let runRepo = MockRunRepository()
        runRepo.shouldThrow = true
        let (vm, _, _) = makeViewModel(runRepo: runRepo, athleteRepo: athleteRepo)

        await vm.save()

        #expect(vm.didSave == false)
        #expect(vm.error != nil)
    }

    @Test("Save sets correct pace when distance is zero")
    @MainActor
    func saveZeroDistancePace() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let (vm, runRepo, _) = makeViewModel(athleteRepo: athleteRepo)

        vm.activityType = .strength
        vm.distanceKm = 0

        await vm.save()

        #expect(runRepo.savedRun?.averagePaceSecondsPerKm == 0)
    }

    @Test("Save includes notes when provided")
    @MainActor
    func saveIncludesNotes() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let (vm, runRepo, _) = makeViewModel(athleteRepo: athleteRepo)

        vm.notes = "Great session"
        await vm.save()

        #expect(runRepo.savedRun?.notes == "Great session")
    }

    @Test("Save excludes notes when empty")
    @MainActor
    func saveExcludesEmptyNotes() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let (vm, runRepo, _) = makeViewModel(athleteRepo: athleteRepo)

        vm.notes = ""
        await vm.save()

        #expect(runRepo.savedRun?.notes == nil)
    }
}
