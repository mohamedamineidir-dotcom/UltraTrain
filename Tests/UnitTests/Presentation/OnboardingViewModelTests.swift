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
    // Steps: 0=Experience, 1=RunningHistory, 2=PersonalBests, 3=AboutYou,
    //        4=BodyMetrics, 5=HeartRate, 6=RaceName, 7=RaceProfile,
    //        8=GoalTraining, 9=Complete

    @Test("Initial state is step 0")
    @MainActor
    func initialState() {
        let (vm, _, _) = makeViewModel()
        #expect(vm.currentStep == 0)
        #expect(vm.isCompleted == false)
        #expect(vm.isSaving == false)
        #expect(vm.error == nil)
    }

    @Test("Can advance from experience step after selection")
    @MainActor
    func advanceFromExperience() {
        let (vm, _, _) = makeViewModel()
        // Step 0: Experience — need to select a level
        #expect(vm.canAdvance == false)
        vm.experienceLevel = .intermediate
        #expect(vm.canAdvance == true)
        vm.advance()
        #expect(vm.currentStep == 1)
    }

    @Test("Cannot advance past last step")
    @MainActor
    func cannotAdvancePastEnd() {
        let (vm, _, _) = makeViewModel()
        vm.currentStep = vm.totalSteps - 1
        vm.advance()
        #expect(vm.currentStep == vm.totalSteps - 1)
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

    // MARK: - Step 0 Validation (Experience)

    @Test("Cannot advance from step 0 without experience level")
    @MainActor
    func experienceRequired() {
        let (vm, _, _) = makeViewModel()
        vm.currentStep = 0
        #expect(vm.canAdvance == false)
        vm.experienceLevel = .intermediate
        #expect(vm.canAdvance == true)
    }

    // MARK: - Step 1 Validation (Running History)

    @Test("New runner can always advance from running history step")
    @MainActor
    func newRunnerSkipsHistory() {
        let (vm, _, _) = makeViewModel()
        vm.currentStep = 1
        vm.isNewRunner = true
        vm.weeklyVolumeKm = 0
        vm.longestRunKm = 0
        #expect(vm.canAdvance == true)
    }

    @Test("Experienced runner needs volume > 0")
    @MainActor
    func experiencedRunnerNeedsVolume() {
        let (vm, _, _) = makeViewModel()
        vm.currentStep = 1
        vm.isNewRunner = false
        vm.weeklyVolumeKm = 0
        vm.longestRunKm = 20
        #expect(vm.canAdvance == false)
        vm.weeklyVolumeKm = 30
        #expect(vm.canAdvance == true)
    }

    // MARK: - Step 2 Validation (Personal Bests - Optional)

    @Test("Can always advance from personal bests step")
    @MainActor
    func personalBestsOptional() {
        let (vm, _, _) = makeViewModel()
        vm.currentStep = 2
        #expect(vm.canAdvance == true)
    }

    @Test("hasAnyPB is true when at least one PB is entered")
    @MainActor
    func hasAnyPBDetection() {
        let (vm, _, _) = makeViewModel()
        #expect(vm.hasAnyPB == false)
        vm.pb5kMinutes = 24
        vm.pb5kSeconds = 30
        #expect(vm.hasAnyPB == true)
    }

    // MARK: - Step 3 Validation (About You)

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

    // MARK: - Step 4 Validation (Body Metrics)

    @Test("Body metrics must be in valid range")
    @MainActor
    func bodyMetricsValidation() {
        let (vm, _, _) = makeViewModel()
        vm.currentStep = 4
        // Defaults are valid (70 kg, 175 cm)
        #expect(vm.canAdvance == true)
        vm.weightKg = 10 // too low
        #expect(vm.canAdvance == false)
        vm.weightKg = 70
        #expect(vm.canAdvance == true)
    }

    // MARK: - Step 5 Validation (Heart Rate)

    @Test("Heart rate step always allows advancing with defaults")
    @MainActor
    func heartRateDefaults() {
        let (vm, _, _) = makeViewModel()
        vm.currentStep = 5
        #expect(vm.canAdvance == true)
    }

    // MARK: - Step 6 Validation (Race Name)

    @Test("Cannot advance with empty race name")
    @MainActor
    func raceNameRequired() {
        let (vm, _, _) = makeViewModel()
        vm.currentStep = 6
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

    @Test("PB deduction fills missing distances from entered PBs")
    @MainActor
    func pbDeductionFromSinglePB() async {
        let athleteRepo = MockAthleteRepository()
        let raceRepo = MockRaceRepository()
        let (vm, _, _) = makeViewModel(athleteRepo: athleteRepo, raceRepo: raceRepo)

        vm.experienceLevel = .intermediate
        vm.firstName = "Test"
        vm.lastName = "Runner"
        vm.raceName = "My Ultra"
        // Enter only a 10K PB
        vm.pb10kMinutes = 45
        vm.pb10kSeconds = 0

        await vm.completeOnboarding()

        let pbs = athleteRepo.savedAthlete?.personalBests ?? []
        #expect(pbs.count == 4, "All 4 PB distances should be filled")
        // The entered 10K should be preserved
        let tenK = pbs.first(where: { $0.distance == .tenK })
        #expect(tenK?.timeSeconds == 2700) // 45 min
    }

    @Test("Derived metrics are stored on athlete when PBs entered")
    @MainActor
    func derivedMetricsStored() async {
        let athleteRepo = MockAthleteRepository()
        let raceRepo = MockRaceRepository()
        let (vm, _, _) = makeViewModel(athleteRepo: athleteRepo, raceRepo: raceRepo)

        vm.experienceLevel = .intermediate
        vm.firstName = "Test"
        vm.lastName = "Runner"
        vm.raceName = "My Ultra"
        vm.pb5kMinutes = 22
        vm.pb5kSeconds = 0

        await vm.completeOnboarding()

        let athlete = athleteRepo.savedAthlete
        #expect(athlete?.vo2max != nil)
        #expect(athlete?.vmaKmh != nil)
        #expect(athlete?.thresholdPace60MinPerKm != nil)
        #expect(athlete?.thresholdPace30MinPerKm != nil)
        // A 22 min 5K corresponds to roughly VO2max ~50-55
        #expect((athlete?.vo2max ?? 0) > 40)
        #expect((athlete?.vo2max ?? 0) < 65)
    }
}
