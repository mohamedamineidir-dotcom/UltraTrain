import Foundation
import Testing
@testable import UltraTrain

@Suite("Post Race Wizard ViewModel Tests")
struct PostRaceWizardViewModelTests {

    // MARK: - Test Helpers

    private func makeRace(
        actualFinishTime: TimeInterval? = nil
    ) -> Race {
        Race(
            id: UUID(),
            name: "UTMB",
            date: Date.now.adding(weeks: -1),
            distanceKm: 171,
            elevationGainM: 10000,
            elevationLossM: 10000,
            priority: .aRace,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .technical,
            actualFinishTime: actualFinishTime
        )
    }

    @MainActor
    private func makeViewModel(
        race: Race? = nil,
        raceRepo: MockRaceRepository = MockRaceRepository(),
        reflectionRepo: MockRaceReflectionRepository = MockRaceReflectionRepository(),
        runRepo: MockRunRepository = MockRunRepository(),
        estimateRepo: MockFinishEstimateRepository = MockFinishEstimateRepository()
    ) -> PostRaceWizardViewModel {
        let r = race ?? makeRace()
        return PostRaceWizardViewModel(
            race: r,
            raceRepository: raceRepo,
            raceReflectionRepository: reflectionRepo,
            runRepository: runRepo,
            finishEstimateRepository: estimateRepo
        )
    }

    // MARK: - Initial State

    @Test("Initial step is result")
    @MainActor
    func testInitialStep_isResult() {
        let vm = makeViewModel()
        #expect(vm.currentStep == .result)
    }

    @Test("Initial finish time is zero for new race")
    @MainActor
    func testInitialFinishTime_whenNoExisting_isZero() {
        let vm = makeViewModel()
        #expect(vm.finishTimeHours == 0)
        #expect(vm.finishTimeMinutes == 0)
        #expect(vm.finishTimeSeconds == 0)
        #expect(vm.finishTimeInterval == 0)
    }

    @Test("Initial finish time populated from existing race time")
    @MainActor
    func testInitialFinishTime_whenExistingTime_populatesFields() {
        // 36 hours, 42 minutes, 15 seconds = 132135 seconds
        let race = makeRace(actualFinishTime: 132135)
        let vm = makeViewModel(race: race)

        #expect(vm.finishTimeHours == 36)
        #expect(vm.finishTimeMinutes == 42)
        #expect(vm.finishTimeSeconds == 15)
    }

    @Test("Race name matches provided race")
    @MainActor
    func testRaceName_matchesProvidedRace() {
        let vm = makeViewModel()
        #expect(vm.raceName == "UTMB")
    }

    @Test("Race distance matches provided race")
    @MainActor
    func testRaceDistance_matchesProvidedRace() {
        let vm = makeViewModel()
        #expect(vm.raceDistanceKm == 171)
    }

    @Test("Initial state has not saved")
    @MainActor
    func testInitialState_hasNotSaved() {
        let vm = makeViewModel()
        #expect(vm.didSave == false)
        #expect(vm.isSaving == false)
        #expect(vm.error == nil)
    }

    // MARK: - canProceed Validation

    @Test("Cannot proceed from result step with zero finish time")
    @MainActor
    func testCanProceed_whenResultStepAndZeroTime_returnsFalse() {
        let vm = makeViewModel()
        vm.currentStep = .result
        #expect(vm.canProceed == false)
    }

    @Test("Can proceed from result step with valid finish time")
    @MainActor
    func testCanProceed_whenResultStepAndValidTime_returnsTrue() {
        let vm = makeViewModel()
        vm.currentStep = .result
        vm.finishTimeHours = 24
        vm.finishTimeMinutes = 30
        #expect(vm.canProceed == true)
    }

    @Test("Can always proceed from pacing step")
    @MainActor
    func testCanProceed_whenPacingStep_returnsTrue() {
        let vm = makeViewModel()
        vm.currentStep = .pacing
        #expect(vm.canProceed == true)
    }

    @Test("Can always proceed from nutrition step")
    @MainActor
    func testCanProceed_whenNutritionStep_returnsTrue() {
        let vm = makeViewModel()
        vm.currentStep = .nutrition
        #expect(vm.canProceed == true)
    }

    @Test("Can always proceed from weather step")
    @MainActor
    func testCanProceed_whenWeatherStep_returnsTrue() {
        let vm = makeViewModel()
        vm.currentStep = .weather
        #expect(vm.canProceed == true)
    }

    @Test("Can proceed from takeaways step with valid satisfaction")
    @MainActor
    func testCanProceed_whenTakeawaysStepAndValidSatisfaction_returnsTrue() {
        let vm = makeViewModel()
        vm.currentStep = .takeaways
        vm.overallSatisfaction = 4
        #expect(vm.canProceed == true)
    }

    @Test("Cannot proceed from takeaways step with satisfaction below 1")
    @MainActor
    func testCanProceed_whenTakeawaysStepAndSatisfactionZero_returnsFalse() {
        let vm = makeViewModel()
        vm.currentStep = .takeaways
        vm.overallSatisfaction = 0
        #expect(vm.canProceed == false)
    }

    @Test("Cannot proceed from takeaways step with satisfaction above 5")
    @MainActor
    func testCanProceed_whenTakeawaysStepAndSatisfactionSix_returnsFalse() {
        let vm = makeViewModel()
        vm.currentStep = .takeaways
        vm.overallSatisfaction = 6
        #expect(vm.canProceed == false)
    }

    @Test("Can always proceed from summary step")
    @MainActor
    func testCanProceed_whenSummaryStep_returnsTrue() {
        let vm = makeViewModel()
        vm.currentStep = .summary
        #expect(vm.canProceed == true)
    }

    // MARK: - Navigation

    @Test("Next step advances from result to pacing")
    @MainActor
    func testNextStep_fromResult_advancesToPacing() {
        let vm = makeViewModel()
        vm.finishTimeHours = 10
        vm.currentStep = .result

        vm.nextStep()

        #expect(vm.currentStep == .pacing)
    }

    @Test("Next step advances through all steps in order")
    @MainActor
    func testNextStep_advancesThroughAllSteps() {
        let vm = makeViewModel()
        vm.finishTimeHours = 10

        vm.currentStep = .result
        vm.nextStep()
        #expect(vm.currentStep == .pacing)

        vm.nextStep()
        #expect(vm.currentStep == .nutrition)

        vm.nextStep()
        #expect(vm.currentStep == .weather)

        vm.nextStep()
        #expect(vm.currentStep == .takeaways)

        vm.nextStep()
        #expect(vm.currentStep == .summary)
    }

    @Test("Next step does not advance past summary")
    @MainActor
    func testNextStep_whenSummary_doesNotAdvanceFurther() {
        let vm = makeViewModel()
        vm.currentStep = .summary

        vm.nextStep()

        #expect(vm.currentStep == .summary)
    }

    @Test("Next step does not advance when canProceed is false")
    @MainActor
    func testNextStep_whenCannotProceed_doesNotAdvance() {
        let vm = makeViewModel()
        vm.currentStep = .result
        // finishTime is zero, so canProceed is false

        vm.nextStep()

        #expect(vm.currentStep == .result)
    }

    @Test("Previous step goes back from pacing to result")
    @MainActor
    func testPreviousStep_fromPacing_goesBackToResult() {
        let vm = makeViewModel()
        vm.currentStep = .pacing

        vm.previousStep()

        #expect(vm.currentStep == .result)
    }

    @Test("Previous step does not go before result")
    @MainActor
    func testPreviousStep_whenResult_doesNotGoFurther() {
        let vm = makeViewModel()
        vm.currentStep = .result

        vm.previousStep()

        #expect(vm.currentStep == .result)
    }

    @Test("Is first step true for result")
    @MainActor
    func testIsFirstStep_whenResult_returnsTrue() {
        let vm = makeViewModel()
        vm.currentStep = .result
        #expect(vm.isFirstStep == true)
    }

    @Test("Is last step true for summary")
    @MainActor
    func testIsLastStep_whenSummary_returnsTrue() {
        let vm = makeViewModel()
        vm.currentStep = .summary
        #expect(vm.isLastStep == true)
    }

    @Test("Step progress increases with each step")
    @MainActor
    func testStepProgress_increasesPerStep() {
        let vm = makeViewModel()

        vm.currentStep = .result
        let progressResult = vm.stepProgress

        vm.currentStep = .nutrition
        let progressNutrition = vm.stepProgress

        vm.currentStep = .summary
        let progressSummary = vm.stepProgress

        #expect(progressResult < progressNutrition)
        #expect(progressNutrition < progressSummary)
        #expect(progressSummary == 1.0)
    }

    // MARK: - Save

    @Test("Save updates race actual finish time and saves reflection")
    @MainActor
    func testSave_updatesRaceAndSavesReflection() async {
        let race = makeRace()
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let reflectionRepo = MockRaceReflectionRepository()

        let vm = makeViewModel(
            race: race,
            raceRepo: raceRepo,
            reflectionRepo: reflectionRepo
        )
        vm.finishTimeHours = 28
        vm.finishTimeMinutes = 45
        vm.finishTimeSeconds = 30
        vm.overallSatisfaction = 4
        vm.keyTakeaways = "Great experience"

        await vm.save()

        #expect(vm.didSave == true)
        #expect(vm.isSaving == false)
        #expect(vm.error == nil)

        // Race should be updated with actual finish time
        let updatedRace = raceRepo.savedRace
        #expect(updatedRace != nil)
        let expectedTime = TimeInterval(28 * 3600 + 45 * 60 + 30)
        #expect(updatedRace?.actualFinishTime == expectedTime)

        // Reflection should be saved
        let reflection = reflectionRepo.reflections[race.id]
        #expect(reflection != nil)
        #expect(reflection?.actualFinishTime == expectedTime)
        #expect(reflection?.overallSatisfaction == 4)
        #expect(reflection?.keyTakeaways == "Great experience")
    }

    @Test("Save stores pacing and nutrition assessments")
    @MainActor
    func testSave_storesAssessments() async {
        let race = makeRace()
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let reflectionRepo = MockRaceReflectionRepository()

        let vm = makeViewModel(
            race: race,
            raceRepo: raceRepo,
            reflectionRepo: reflectionRepo
        )
        vm.finishTimeHours = 10
        vm.pacingAssessment = .tooFast
        vm.nutritionAssessment = .majorProblems
        vm.hadStomachIssues = true
        vm.weatherImpact = .severe
        vm.overallSatisfaction = 2

        await vm.save()

        let reflection = reflectionRepo.reflections[race.id]
        #expect(reflection?.pacingAssessment == .tooFast)
        #expect(reflection?.nutritionAssessment == .majorProblems)
        #expect(reflection?.hadStomachIssues == true)
        #expect(reflection?.weatherImpact == .severe)
        #expect(reflection?.overallSatisfaction == 2)
    }

    @Test("Save handles error from race repository")
    @MainActor
    func testSave_whenRaceRepoError_setsErrorMessage() async {
        let race = makeRace()
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        raceRepo.shouldThrow = true

        let vm = makeViewModel(race: race, raceRepo: raceRepo)
        vm.finishTimeHours = 10

        await vm.save()

        #expect(vm.didSave == false)
        #expect(vm.error != nil)
        #expect(vm.isSaving == false)
    }

    @Test("Save handles error from reflection repository")
    @MainActor
    func testSave_whenReflectionRepoError_setsErrorMessage() async {
        let race = makeRace()
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let reflectionRepo = MockRaceReflectionRepository()
        reflectionRepo.shouldThrow = true

        let vm = makeViewModel(
            race: race,
            raceRepo: raceRepo,
            reflectionRepo: reflectionRepo
        )
        vm.finishTimeHours = 10

        await vm.save()

        #expect(vm.didSave == false)
        #expect(vm.error != nil)
    }

    @Test("Save stores linked run id when selected")
    @MainActor
    func testSave_whenRunSelected_storesLinkedRunId() async {
        let race = makeRace()
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let reflectionRepo = MockRaceReflectionRepository()

        let runId = UUID()
        let vm = makeViewModel(
            race: race,
            raceRepo: raceRepo,
            reflectionRepo: reflectionRepo
        )
        vm.finishTimeHours = 10
        vm.selectedRunId = runId

        await vm.save()

        #expect(raceRepo.savedRace?.linkedRunId == runId)
        #expect(reflectionRepo.reflections[race.id]?.completedRunId == runId)
    }

    @Test("Save omits empty notes")
    @MainActor
    func testSave_whenNotesEmpty_storesNil() async {
        let race = makeRace()
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let reflectionRepo = MockRaceReflectionRepository()

        let vm = makeViewModel(
            race: race,
            raceRepo: raceRepo,
            reflectionRepo: reflectionRepo
        )
        vm.finishTimeHours = 10
        vm.pacingNotes = ""
        vm.nutritionNotes = ""
        vm.weatherNotes = ""

        await vm.save()

        let reflection = reflectionRepo.reflections[race.id]
        #expect(reflection?.pacingNotes == nil)
        #expect(reflection?.nutritionNotes == nil)
        #expect(reflection?.weatherNotes == nil)
    }

    @Test("Save stores non-empty notes")
    @MainActor
    func testSave_whenNotesProvided_storesNotes() async {
        let race = makeRace()
        let raceRepo = MockRaceRepository()
        raceRepo.races = [race]
        let reflectionRepo = MockRaceReflectionRepository()

        let vm = makeViewModel(
            race: race,
            raceRepo: raceRepo,
            reflectionRepo: reflectionRepo
        )
        vm.finishTimeHours = 10
        vm.pacingNotes = "Started too fast"
        vm.nutritionNotes = "Gels worked well"
        vm.weatherNotes = "Very hot"

        await vm.save()

        let reflection = reflectionRepo.reflections[race.id]
        #expect(reflection?.pacingNotes == "Started too fast")
        #expect(reflection?.nutritionNotes == "Gels worked well")
        #expect(reflection?.weatherNotes == "Very hot")
    }

    // MARK: - Load

    @Test("Load populates recent runs")
    @MainActor
    func testLoad_populatesRecentRuns() async {
        let race = makeRace()
        let runRepo = MockRunRepository()
        let run = CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: Date.now.adding(days: -1),
            distanceKm: 15,
            elevationGainM: 400,
            elevationLossM: 400,
            duration: 5400,
            averageHeartRate: 145,
            maxHeartRate: 170,
            averagePaceSecondsPerKm: 360,
            gpsTrack: [],
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )
        runRepo.runs = [run]

        let vm = makeViewModel(race: race, runRepo: runRepo)
        await vm.load()

        #expect(vm.recentRuns.count == 1)
    }

    @Test("Load populates finish estimate if available")
    @MainActor
    func testLoad_populatesFinishEstimate() async {
        let race = makeRace()
        let estimateRepo = MockFinishEstimateRepository()
        let estimate = FinishEstimate(
            id: UUID(),
            raceId: race.id,
            athleteId: UUID(),
            calculatedAt: .now,
            optimisticTime: 80000,
            expectedTime: 90000,
            conservativeTime: 100000,
            checkpointSplits: [],
            confidencePercent: 70,
            raceResultsUsed: 2
        )
        estimateRepo.estimates[race.id] = estimate

        let vm = makeViewModel(race: race, estimateRepo: estimateRepo)
        await vm.load()

        #expect(vm.finishEstimate != nil)
        #expect(vm.finishEstimate?.expectedTime == 90000)
    }
}
