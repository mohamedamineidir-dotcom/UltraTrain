import Foundation
import Testing
@testable import UltraTrain

@Suite("Session Nutrition Advisor Tests")
struct SessionNutritionAdvisorTests {

    private let advisor = DefaultSessionNutritionAdvisor()

    private func makeSession(
        type: SessionType = .longRun,
        intensity: Intensity = .easy,
        distanceKm: Double = 20,
        elevationGainM: Double = 500,
        durationSeconds: TimeInterval = 2 * 3600
    ) -> TrainingSession {
        TrainingSession(
            id: UUID(),
            date: .now,
            type: type,
            plannedDistanceKm: distanceKm,
            plannedElevationGainM: elevationGainM,
            plannedDuration: durationSeconds,
            intensity: intensity,
            description: "Test session",
            nutritionNotes: nil,
            isCompleted: false,
            isSkipped: false,
            linkedRunId: nil
        )
    }

    // MARK: - Rest

    @Test("Rest sessions return nil")
    func restReturnsNil() {
        let session = makeSession(type: .rest, durationSeconds: 0)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate)
        #expect(advice == nil)
    }

    // MARK: - Pre-Run

    @Test("Long run gets high-carb pre-run advice")
    func longRunPreRun() {
        let session = makeSession(type: .longRun, durationSeconds: 3 * 3600)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate)
        #expect(advice?.preRun != nil)
        #expect(advice!.preRun!.carbsGrams >= 80)
        #expect(advice!.preRun!.hydrationMl >= 400)
    }

    @Test("Recovery gets light pre-run advice")
    func recoveryPreRun() {
        let session = makeSession(type: .recovery, intensity: .easy, durationSeconds: 40 * 60)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate)
        #expect(advice?.preRun != nil)
        #expect(advice!.preRun!.carbsGrams <= 30)
    }

    @Test("Hard intervals gets avoid notes")
    func hardIntervalsAvoidNotes() {
        let session = makeSession(type: .intervals, intensity: .hard, durationSeconds: 75 * 60)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .advanced)
        #expect(advice?.preRun?.avoidNotes != nil)
    }

    // MARK: - During-Run

    @Test("Short session has no during-run advice")
    func shortNoDuring() {
        let session = makeSession(type: .recovery, intensity: .easy, durationSeconds: 30 * 60)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate)
        #expect(advice?.duringRun == nil)
    }

    @Test("Session over 45 min gets during-run advice")
    func mediumGetsDuring() {
        let session = makeSession(type: .tempo, intensity: .moderate, durationSeconds: 75 * 60)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate)
        #expect(advice?.duringRun != nil)
        #expect(advice!.duringRun!.caloriesPerHour > 0)
        #expect(advice!.duringRun!.hydrationMlPerHour > 0)
    }

    @Test("Calories scale with athlete weight")
    func caloriesScaleWithWeight() {
        let session = makeSession(type: .longRun, durationSeconds: 2 * 3600)
        let light = advisor.advise(for: session, athleteWeightKg: 55, experienceLevel: .intermediate)
        let heavy = advisor.advise(for: session, athleteWeightKg: 85, experienceLevel: .intermediate)
        #expect(heavy!.duringRun!.caloriesPerHour > light!.duringRun!.caloriesPerHour)
    }

    @Test("Calories increase with experience level")
    func caloriesScaleWithExperience() {
        let session = makeSession(type: .longRun, durationSeconds: 2 * 3600)
        let beginner = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .beginner)
        let elite = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .elite)
        #expect(elite!.duringRun!.caloriesPerHour > beginner!.duringRun!.caloriesPerHour)
    }

    @Test("Long session includes product suggestions")
    func longSessionProducts() {
        let session = makeSession(type: .longRun, durationSeconds: 3 * 3600)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate)
        #expect(!advice!.duringRun!.suggestedProducts.isEmpty)
    }

    @Test("Very long session includes bar and salt")
    func veryLongSessionBarAndSalt() {
        let session = makeSession(type: .longRun, distanceKm: 40, durationSeconds: 4 * 3600)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate)
        let types = advice!.duringRun!.suggestedProducts.map(\.product.type)
        #expect(types.contains(.bar))
        #expect(types.contains(.salt))
    }

    // MARK: - Gut Training

    @Test("Long run over 2h recommends gut training")
    func gutTrainingLongRun() {
        let session = makeSession(type: .longRun, durationSeconds: 2.5 * 3600)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate)
        #expect(advice!.isGutTrainingRecommended)
    }

    @Test("Short session does not recommend gut training")
    func noGutTrainingShort() {
        let session = makeSession(type: .tempo, durationSeconds: 60 * 60)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate)
        #expect(!advice!.isGutTrainingRecommended)
    }

    @Test("Back-to-back over 2h recommends gut training")
    func gutTrainingBackToBack() {
        let session = makeSession(type: .backToBack, durationSeconds: 2.5 * 3600)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate)
        #expect(advice!.isGutTrainingRecommended)
    }

    // MARK: - Post-Run

    @Test("Hard intervals gets high priority recovery")
    func hardHighPriority() {
        let session = makeSession(type: .intervals, intensity: .hard, durationSeconds: 75 * 60)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate)
        #expect(advice?.postRun.priority == .high)
    }

    @Test("Recovery session gets low priority")
    func recoveryLowPriority() {
        let session = makeSession(type: .recovery, intensity: .easy, durationSeconds: 40 * 60)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate)
        #expect(advice?.postRun.priority == .low)
    }

    @Test("Tempo session gets moderate priority")
    func tempoModeratePriority() {
        let session = makeSession(type: .tempo, intensity: .moderate, durationSeconds: 60 * 60)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate)
        #expect(advice?.postRun.priority == .moderate)
    }

    @Test("Post-run has meal suggestions")
    func postRunMealSuggestions() {
        let session = makeSession(type: .tempo, intensity: .moderate, durationSeconds: 90 * 60)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate)
        #expect(!advice!.postRun.mealSuggestions.isEmpty)
    }
}
