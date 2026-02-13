import Foundation
import Testing
@testable import UltraTrain

@Suite("Onboarding ViewModel Tests")
struct OnboardingViewModelTests {

    @MainActor
    private func makeViewModel(
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        raceRepo: MockRaceRepository = MockRaceRepository()
    ) -> (OnboardingViewModel, MockAthleteRepository, MockRaceRepository) {
        let vm = OnboardingViewModel(athleteRepository: athleteRepo, raceRepository: raceRepo)
        return (vm, athleteRepo, raceRepo)
    }

    // MARK: - Navigation

    @Test("Initial state is step 0")
    @MainActor
    func initialState() {
        let (vm, _, _) = makeViewModel()
        #expect(vm.currentStep == 0)
        #expect(vm.isCompleted == false)
        #expect(vm.isSaving == false)
        #expect(vm.error == nil)
    }

    @Test("Can advance from welcome step")
    @MainActor
    func advanceFromWelcome() {
        let (vm, _, _) = makeViewModel()
        #expect(vm.canAdvance == true)
        vm.advance()
        #expect(vm.currentStep == 1)
    }

    @Test("Cannot advance past last step")
    @MainActor
    func cannotAdvancePastEnd() {
        let (vm, _, _) = makeViewModel()
        vm.currentStep = 5
        vm.advance()
        #expect(vm.currentStep == 5)
    }

    @Test("Go back decrements step")
    @MainActor
    func goBack() {
        let (vm, _, _) = makeViewModel()
        vm.currentStep = 3
        vm.goBack()
        #expect(vm.currentStep == 2)
    }

    @Test("Cannot go back from step 0")
    @MainActor
    func cannotGoBackFromStart() {
        let (vm, _, _) = makeViewModel()
        vm.goBack()
        #expect(vm.currentStep == 0)
    }

    // MARK: - Step 1 Validation (Experience)

    @Test("Cannot advance from step 1 without experience level")
    @MainActor
    func experienceRequired() {
        let (vm, _, _) = makeViewModel()
        vm.currentStep = 1
        #expect(vm.canAdvance == false)
        vm.experienceLevel = .intermediate
        #expect(vm.canAdvance == true)
    }

    // MARK: - Step 2 Validation (Running History)

    @Test("New runner can always advance from step 2")
    @MainActor
    func newRunnerSkipsHistory() {
        let (vm, _, _) = makeViewModel()
        vm.currentStep = 2
        vm.isNewRunner = true
        vm.weeklyVolumeKm = 0
        vm.longestRunKm = 0
        #expect(vm.canAdvance == true)
    }

    @Test("Experienced runner needs volume > 0")
    @MainActor
    func experiencedRunnerNeedsVolume() {
        let (vm, _, _) = makeViewModel()
        vm.currentStep = 2
        vm.isNewRunner = false
        vm.weeklyVolumeKm = 0
        vm.longestRunKm = 20
        #expect(vm.canAdvance == false)
        vm.weeklyVolumeKm = 30
        #expect(vm.canAdvance == true)
    }

    // MARK: - Step 3 Validation (Physical Data)

    @Test("Cannot advance with empty first name")
    @MainActor
    func nameRequired() {
        let (vm, _, _) = makeViewModel()
        vm.currentStep = 3
        vm.firstName = ""
        vm.lastName = "Runner"
        #expect(vm.canAdvance == false)
        vm.firstName = "Test"
        #expect(vm.canAdvance == true)
    }

    @Test("Max HR must be greater than resting HR")
    @MainActor
    func heartRateValidation() {
        let (vm, _, _) = makeViewModel()
        vm.currentStep = 3
        vm.firstName = "Test"
        vm.lastName = "Runner"
        vm.restingHeartRate = 60
        vm.maxHeartRate = 50
        #expect(vm.canAdvance == false)
        vm.maxHeartRate = 185
        #expect(vm.canAdvance == true)
    }

    // MARK: - Step 4 Validation (Race Goal)

    @Test("Cannot advance with empty race name")
    @MainActor
    func raceNameRequired() {
        let (vm, _, _) = makeViewModel()
        vm.currentStep = 4
        vm.raceName = ""
        #expect(vm.canAdvance == false)
        vm.raceName = "UTMB"
        #expect(vm.canAdvance == true)
    }

    // MARK: - Complete Onboarding

    @Test("Complete onboarding saves athlete and race")
    @MainActor
    func completeOnboardingSaves() async {
        let athleteRepo = MockAthleteRepository()
        let raceRepo = MockRaceRepository()
        let (vm, _, _) = makeViewModel(athleteRepo: athleteRepo, raceRepo: raceRepo)

        vm.experienceLevel = .beginner
        vm.firstName = "Test"
        vm.lastName = "Runner"
        vm.raceName = "My Ultra"
        vm.raceDistanceKm = 100

        await vm.completeOnboarding()

        #expect(athleteRepo.savedAthlete != nil)
        #expect(athleteRepo.savedAthlete?.firstName == "Test")
        #expect(raceRepo.savedRace != nil)
        #expect(raceRepo.savedRace?.name == "My Ultra")
        #expect(vm.isCompleted == true)
        #expect(vm.error == nil)
    }

    @Test("Complete onboarding handles save failure")
    @MainActor
    func completeOnboardingFailure() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.shouldThrow = true
        let raceRepo = MockRaceRepository()
        let (vm, _, _) = makeViewModel(athleteRepo: athleteRepo, raceRepo: raceRepo)

        vm.experienceLevel = .beginner
        vm.firstName = "Test"
        vm.lastName = "Runner"
        vm.raceName = "My Ultra"

        await vm.completeOnboarding()

        #expect(vm.isCompleted == false)
        #expect(vm.error != nil)
    }

    @Test("New runner sets volume to zero on save")
    @MainActor
    func newRunnerZeroVolume() async {
        let athleteRepo = MockAthleteRepository()
        let raceRepo = MockRaceRepository()
        let (vm, _, _) = makeViewModel(athleteRepo: athleteRepo, raceRepo: raceRepo)

        vm.experienceLevel = .beginner
        vm.isNewRunner = true
        vm.weeklyVolumeKm = 50
        vm.longestRunKm = 30
        vm.firstName = "Test"
        vm.lastName = "Runner"
        vm.raceName = "My Ultra"

        await vm.completeOnboarding()

        #expect(athleteRepo.savedAthlete?.weeklyVolumeKm == 0)
        #expect(athleteRepo.savedAthlete?.longestRunKm == 0)
    }
}
