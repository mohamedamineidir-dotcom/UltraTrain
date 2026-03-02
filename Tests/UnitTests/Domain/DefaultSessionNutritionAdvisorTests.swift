import Foundation
import Testing
@testable import UltraTrain

@Suite("DefaultSessionNutritionAdvisor Tests")
struct DefaultSessionNutritionAdvisorTests {

    private let advisor = DefaultSessionNutritionAdvisor()
    private let defaultPrefs = NutritionPreferences.default

    // MARK: - Helpers

    private func makeSession(
        type: SessionType,
        durationHours: Double = 1.0,
        intensity: Intensity = .moderate
    ) -> TrainingSession {
        TrainingSession(
            id: UUID(),
            date: .now,
            type: type,
            plannedDistanceKm: 10,
            plannedElevationGainM: 300,
            plannedDuration: durationHours * 3600,
            intensity: intensity,
            description: "Test",
            nutritionNotes: nil,
            isCompleted: false,
            isSkipped: false,
            linkedRunId: nil
        )
    }

    // MARK: - Rest Session

    @Test("Rest session returns nil advice")
    func restSessionReturnsNil() {
        let session = makeSession(type: .rest)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice == nil)
    }

    // MARK: - Pre-Run: Long Run

    @Test("Long run pre-run recommends 100g carbs and 500ml hydration")
    func longRunPreRun() {
        let session = makeSession(type: .longRun, durationHours: 2.5)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice != nil)
        #expect(advice?.preRun?.carbsGrams == 100)
        #expect(advice?.preRun?.hydrationMl == 500)
    }

    @Test("Back-to-back session pre-run recommends 100g carbs")
    func backToBackPreRun() {
        let session = makeSession(type: .backToBack, durationHours: 3.0)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice?.preRun?.carbsGrams == 100)
    }

    @Test("Hard long run includes avoid notes in pre-run")
    func hardLongRunAvoidNotes() {
        let session = makeSession(type: .longRun, durationHours: 2.5, intensity: .hard)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice?.preRun?.avoidNotes != nil)
    }

    // MARK: - Pre-Run: Hard/Tempo/Intervals

    @Test("Tempo session pre-run recommends 60g carbs")
    func tempoPreRun() {
        let session = makeSession(type: .tempo, durationHours: 1.0)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice?.preRun?.carbsGrams == 60)
        #expect(advice?.preRun?.avoidNotes != nil)
    }

    @Test("Intervals session pre-run recommends 60g carbs")
    func intervalsPreRun() {
        let session = makeSession(type: .intervals, durationHours: 1.0)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice?.preRun?.carbsGrams == 60)
    }

    @Test("Vertical gain session pre-run recommends 60g carbs")
    func verticalGainPreRun() {
        let session = makeSession(type: .verticalGain, durationHours: 1.0)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice?.preRun?.carbsGrams == 60)
    }

    // MARK: - Pre-Run: Easy/Recovery

    @Test("Recovery run pre-run recommends light 25g carbs")
    func recoveryPreRun() {
        let session = makeSession(type: .recovery, durationHours: 0.75, intensity: .easy)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice?.preRun?.carbsGrams == 25)
        #expect(advice?.preRun?.hydrationMl == 400)
        #expect(advice?.preRun?.avoidNotes == nil)
    }

    // MARK: - During-Run: Short Session Returns Nil

    @Test("Short session under 45min returns nil during-run advice")
    func shortSessionNoDuringRunAdvice() {
        let session = makeSession(type: .recovery, durationHours: 0.5, intensity: .easy)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice?.duringRun == nil)
    }

    // MARK: - During-Run: Calorie Factor by Experience

    @Test("Beginner gets lower calories per hour than elite")
    func calorieFactorByExperience() {
        let session = makeSession(type: .longRun, durationHours: 2.5, intensity: .moderate)
        let beginnerAdvice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .beginner, preferences: defaultPrefs)
        let eliteAdvice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .elite, preferences: defaultPrefs)
        #expect(beginnerAdvice!.duringRun!.caloriesPerHour < eliteAdvice!.duringRun!.caloriesPerHour)
    }

    @Test("Intermediate 70kg moderate intensity gets 280 cal/hr")
    func intermediateCaloriesPerHour() {
        let session = makeSession(type: .longRun, durationHours: 2.5, intensity: .moderate)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        // factor = 4.0 * 1.0 = 4.0, cals = 70 * 4.0 = 280
        #expect(advice?.duringRun?.caloriesPerHour == 280)
    }

    @Test("Hard intensity increases calorie factor by 10%")
    func hardIntensityCalorieFactor() {
        let session = makeSession(type: .longRun, durationHours: 2.5, intensity: .hard)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        // factor = 4.0 * 1.1 = 4.4, cals = 70 * 4.4 = 308
        #expect(advice?.duringRun?.caloriesPerHour == 308)
    }

    // MARK: - During-Run: Hydration

    @Test("Sessions 2+ hours get 600ml hydration per hour")
    func longSessionHydration() {
        let session = makeSession(type: .longRun, durationHours: 2.5)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice?.duringRun?.hydrationMlPerHour == 600)
    }

    @Test("Sessions under 2 hours get 400ml hydration per hour")
    func shortSessionHydration() {
        let session = makeSession(type: .tempo, durationHours: 1.0)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice?.duringRun?.hydrationMlPerHour == 400)
    }

    // MARK: - During-Run: Product Suggestions

    @Test("Bar suggested only for 2+ hour sessions")
    func barSuggestedForLongSessions() {
        let shortSession = makeSession(type: .tempo, durationHours: 1.5)
        let longSession = makeSession(type: .longRun, durationHours: 2.5)

        let shortAdvice = advisor.advise(for: shortSession, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        let longAdvice = advisor.advise(for: longSession, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)

        let shortHasBar = shortAdvice?.duringRun?.suggestedProducts.contains { $0.product.type == .bar } ?? false
        let longHasBar = longAdvice?.duringRun?.suggestedProducts.contains { $0.product.type == .bar } ?? false

        #expect(!shortHasBar)
        #expect(longHasBar)
    }

    @Test("Salt capsule suggested only for 3+ hour sessions")
    func saltCapsuleForUltraLongSessions() {
        let twoHrSession = makeSession(type: .longRun, durationHours: 2.5)
        let threeHrSession = makeSession(type: .longRun, durationHours: 3.5)

        let twoHrAdvice = advisor.advise(for: twoHrSession, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        let threeHrAdvice = advisor.advise(for: threeHrSession, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)

        let twoHrHasSalt = twoHrAdvice?.duringRun?.suggestedProducts.contains { $0.product.type == .salt } ?? false
        let threeHrHasSalt = threeHrAdvice?.duringRun?.suggestedProducts.contains { $0.product.type == .salt } ?? false

        #expect(!twoHrHasSalt)
        #expect(threeHrHasSalt)
    }

    @Test("Avoid caffeine preference removes caffeinated products")
    func avoidCaffeineRemovesProducts() {
        let prefs = NutritionPreferences(avoidCaffeine: true, preferRealFood: false, excludedProductIds: [])
        let session = makeSession(type: .longRun, durationHours: 2.5)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: prefs)
        let hasCaffeinated = advice?.duringRun?.suggestedProducts.contains { $0.product.caffeinated } ?? false
        #expect(!hasCaffeinated)
    }

    @Test("Excluded product IDs remove specific products")
    func excludedProductIdsRemoveProducts() {
        let prefs = NutritionPreferences(avoidCaffeine: false, preferRealFood: false, excludedProductIds: [DefaultProducts.gel.id])
        let session = makeSession(type: .longRun, durationHours: 2.5)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: prefs)
        let hasGel = advice?.duringRun?.suggestedProducts.contains { $0.product.id == DefaultProducts.gel.id } ?? false
        #expect(!hasGel)
    }

    // MARK: - Gut Training

    @Test("Long run 2+ hours recommends gut training")
    func gutTrainingForLongRun() {
        let session = makeSession(type: .longRun, durationHours: 2.5)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice?.isGutTrainingRecommended == true)
    }

    @Test("Short long run under 2 hours does not recommend gut training")
    func noGutTrainingForShortLongRun() {
        let session = makeSession(type: .longRun, durationHours: 1.5)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice?.isGutTrainingRecommended == false)
    }

    @Test("Tempo session never recommends gut training")
    func noGutTrainingForTempo() {
        let session = makeSession(type: .tempo, durationHours: 2.5)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice?.isGutTrainingRecommended == false)
    }

    // MARK: - Post-Run: Recovery Priority

    @Test("Long run has high recovery priority")
    func longRunHighRecovery() {
        let session = makeSession(type: .longRun, durationHours: 2.5)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice?.postRun.priority == .high)
        #expect(advice?.postRun.windowDescription == "Within 30 minutes")
    }

    @Test("Hard session has high recovery priority")
    func hardSessionHighRecovery() {
        let session = makeSession(type: .tempo, durationHours: 1.0, intensity: .hard)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice?.postRun.priority == .high)
    }

    @Test("Tempo session has moderate recovery priority")
    func tempoModerateRecovery() {
        let session = makeSession(type: .tempo, durationHours: 1.0, intensity: .moderate)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice?.postRun.priority == .moderate)
    }

    @Test("Easy recovery run has low recovery priority")
    func recoveryLowPriority() {
        let session = makeSession(type: .recovery, durationHours: 0.75, intensity: .easy)
        let advice = advisor.advise(for: session, athleteWeightKg: 70, experienceLevel: .intermediate, preferences: defaultPrefs)
        #expect(advice?.postRun.priority == .low)
        #expect(advice?.postRun.windowDescription == "Normal meal timing")
    }

    // MARK: - Post-Run: Protein Clamping

    @Test("High recovery protein is clamped to 30-40g range")
    func highRecoveryProteinClamped() {
        // Light athlete: 50kg * 0.5 = 25 → clamped to 30
        let lightAdvice = advisor.advise(
            for: makeSession(type: .longRun, durationHours: 2.5),
            athleteWeightKg: 50, experienceLevel: .intermediate, preferences: defaultPrefs
        )
        #expect(lightAdvice?.postRun.proteinGrams == 30)

        // Heavy athlete: 100kg * 0.5 = 50 → clamped to 40
        let heavyAdvice = advisor.advise(
            for: makeSession(type: .longRun, durationHours: 2.5),
            athleteWeightKg: 100, experienceLevel: .intermediate, preferences: defaultPrefs
        )
        #expect(heavyAdvice?.postRun.proteinGrams == 40)
    }

    @Test("Moderate recovery protein is clamped to 20-30g range")
    func moderateRecoveryProteinClamped() {
        // Light athlete: 50kg * 0.35 = 17 → clamped to 20
        let lightAdvice = advisor.advise(
            for: makeSession(type: .tempo, durationHours: 1.0),
            athleteWeightKg: 50, experienceLevel: .intermediate, preferences: defaultPrefs
        )
        #expect(lightAdvice?.postRun.proteinGrams == 20)
    }
}
