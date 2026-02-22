import Foundation
import os

@Observable
@MainActor
final class PostRaceWizardViewModel {
    enum Step: Int, CaseIterable {
        case result
        case pacing
        case nutrition
        case weather
        case takeaways
        case summary
    }

    // MARK: - Dependencies

    private let race: Race
    private let raceRepository: any RaceRepository
    private let raceReflectionRepository: any RaceReflectionRepository
    private let runRepository: any RunRepository
    private let finishEstimateRepository: any FinishEstimateRepository

    // MARK: - State

    var currentStep: Step = .result
    var finishTimeHours: Int
    var finishTimeMinutes: Int
    var finishTimeSeconds: Int
    var actualPosition: Int?
    var selectedRunId: UUID?
    var pacingAssessment: PacingAssessment = .wellPaced
    var pacingNotes: String = ""
    var nutritionAssessment: NutritionAssessment = .goodEnough
    var nutritionNotes: String = ""
    var hadStomachIssues: Bool = false
    var weatherImpact: WeatherImpactLevel = .noImpact
    var weatherNotes: String = ""
    var overallSatisfaction: Int = 3
    var keyTakeaways: String = ""
    var recentRuns: [CompletedRun] = []
    var finishEstimate: FinishEstimate?
    var isSaving = false
    var error: String?
    var didSave = false

    // MARK: - Computed

    var raceName: String { race.name }
    var raceDistanceKm: Double { race.distanceKm }
    var raceDate: Date { race.date }

    var finishTimeInterval: TimeInterval {
        TimeInterval(finishTimeHours * 3600 + finishTimeMinutes * 60 + finishTimeSeconds)
    }

    var canProceed: Bool {
        switch currentStep {
        case .result:
            return finishTimeInterval > 0
        case .pacing, .nutrition, .weather:
            return true
        case .takeaways:
            return overallSatisfaction >= 1 && overallSatisfaction <= 5
        case .summary:
            return true
        }
    }

    var isFirstStep: Bool { currentStep == Step.allCases.first }
    var isLastStep: Bool { currentStep == .summary }

    var stepProgress: Double {
        let total = Double(Step.allCases.count)
        let current = Double(currentStep.rawValue + 1)
        return current / total
    }

    // MARK: - Init

    init(
        race: Race,
        raceRepository: any RaceRepository,
        raceReflectionRepository: any RaceReflectionRepository,
        runRepository: any RunRepository,
        finishEstimateRepository: any FinishEstimateRepository
    ) {
        self.race = race
        self.raceRepository = raceRepository
        self.raceReflectionRepository = raceReflectionRepository
        self.runRepository = runRepository
        self.finishEstimateRepository = finishEstimateRepository

        let existingTime = race.actualFinishTime ?? 0
        self.finishTimeHours = Int(existingTime) / 3600
        self.finishTimeMinutes = (Int(existingTime) % 3600) / 60
        self.finishTimeSeconds = Int(existingTime) % 60
    }

    // MARK: - Actions

    func load() async {
        do {
            recentRuns = try await runRepository.getRecentRuns(limit: 20)
            finishEstimate = try await finishEstimateRepository.getEstimate(for: race.id)
        } catch {
            Logger.persistence.error("Failed to load post-race data: \(error.localizedDescription)")
        }
    }

    func save() async {
        guard !isSaving else { return }
        isSaving = true
        error = nil

        do {
            var updatedRace = race
            updatedRace.actualFinishTime = finishTimeInterval
            updatedRace.linkedRunId = selectedRunId
            try await raceRepository.updateRace(updatedRace)

            let reflection = RaceReflection(
                id: UUID(),
                raceId: race.id,
                completedRunId: selectedRunId,
                actualFinishTime: finishTimeInterval,
                actualPosition: actualPosition,
                pacingAssessment: pacingAssessment,
                pacingNotes: pacingNotes.isEmpty ? nil : pacingNotes,
                nutritionAssessment: nutritionAssessment,
                nutritionNotes: nutritionNotes.isEmpty ? nil : nutritionNotes,
                hadStomachIssues: hadStomachIssues,
                weatherImpact: weatherImpact,
                weatherNotes: weatherNotes.isEmpty ? nil : weatherNotes,
                overallSatisfaction: overallSatisfaction,
                keyTakeaways: keyTakeaways,
                createdAt: Date()
            )
            try await raceReflectionRepository.saveReflection(reflection)
            didSave = true
            Logger.persistence.info("Post-race reflection saved successfully")
        } catch {
            self.error = error.localizedDescription
            Logger.persistence.error("Failed to save post-race reflection: \(error.localizedDescription)")
        }

        isSaving = false
    }

    func nextStep() {
        guard canProceed else { return }
        let allSteps = Step.allCases
        guard let idx = allSteps.firstIndex(of: currentStep),
              allSteps.index(after: idx) < allSteps.endIndex else { return }
        currentStep = allSteps[allSteps.index(after: idx)]
    }

    func previousStep() {
        let allSteps = Step.allCases
        guard let idx = allSteps.firstIndex(of: currentStep), idx > allSteps.startIndex else { return }
        currentStep = allSteps[allSteps.index(before: idx)]
    }
}
