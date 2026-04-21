import Foundation
import Testing
@testable import UltraTrain

@Suite("Refine Nutrition Plan From Feedback")
struct RefineNutritionPlanFromFeedbackUseCaseTests {

    // MARK: - Helpers

    private func feedback(
        planned: Int = 75,
        actual: Int,
        symptoms: (nausea: Int, bloating: Int, cramping: Int, urgency: Int) = (0, 0, 0, 0),
        bonked: Bool = false,
        tolerated: Set<UUID> = [],
        intolerant: Set<UUID> = [],
        createdAt: Date = Date()
    ) -> NutritionSessionFeedback {
        NutritionSessionFeedback(
            id: UUID(),
            sessionId: UUID(),
            plannedCarbsPerHour: planned,
            actualCarbsConsumed: actual,
            durationMinutes: 150,
            nausea: symptoms.nausea,
            bloating: symptoms.bloating,
            cramping: symptoms.cramping,
            urgency: symptoms.urgency,
            energyLevel: 7,
            bonked: bonked,
            toleratedProductIds: tolerated,
            intolerantProductIds: intolerant,
            notes: nil,
            createdAt: createdAt
        )
    }

    // MARK: - Rule 1: ceiling

    @Test("Single feedback returns unchanged preferences (too noisy)")
    func singleFeedbackNoChange() {
        let prefs = NutritionPreferences.default
        let f = [feedback(actual: 60)]
        let result = RefineNutritionPlanFromFeedbackUseCase.refine(
            preferences: prefs, feedbacks: f
        )
        #expect(result.refinedPreferences == prefs)
        #expect(result.notes.isEmpty)
    }

    @Test("Ceiling set to highest tolerable intake when lower than prior")
    func ceilingLoweredFromTolerable() {
        var prefs = NutritionPreferences.default
        prefs.carbsPerHourTolerance = 90
        let feedbacks = [
            feedback(actual: 65),
            feedback(actual: 70),
            feedback(actual: 75)
        ]
        let result = RefineNutritionPlanFromFeedbackUseCase.refine(
            preferences: prefs, feedbacks: feedbacks
        )
        #expect(result.refinedPreferences.carbsPerHourTolerance == 75)
        #expect(result.notes.contains { $0.contains("75 g") })
    }

    @Test("Ceiling is never raised speculatively beyond current value")
    func ceilingNotRaised() {
        var prefs = NutritionPreferences.default
        prefs.carbsPerHourTolerance = 60
        let feedbacks = [
            feedback(actual: 80),
            feedback(actual: 85)
        ]
        let result = RefineNutritionPlanFromFeedbackUseCase.refine(
            preferences: prefs, feedbacks: feedbacks
        )
        #expect(result.refinedPreferences.carbsPerHourTolerance == 60)
    }

    @Test("Aggressive deload when every session had high GI symptoms")
    func deloadOnConsistentSymptoms() {
        var prefs = NutritionPreferences.default
        prefs.carbsPerHourTolerance = 90
        let feedbacks = [
            feedback(actual: 70, symptoms: (6, 3, 4, 2)),
            feedback(actual: 75, symptoms: (8, 2, 3, 1))
        ]
        let result = RefineNutritionPlanFromFeedbackUseCase.refine(
            preferences: prefs, feedbacks: feedbacks
        )
        // First feedback (.first = newest) had 70 g; 70 * 0.85 = 59.5 → 59
        #expect(result.refinedPreferences.carbsPerHourTolerance == 59)
        #expect(result.notes.contains { $0.contains("15%") })
    }

    // MARK: - Rule 2: exclude intolerant products

    @Test("Product intolerant in 2+ sessions is added to excludedProductIds")
    func intolerantProductExcludedAfterTwoStrikes() {
        let bad = UUID()
        let prefs = NutritionPreferences.default
        let feedbacks = [
            feedback(actual: 60, intolerant: [bad]),
            feedback(actual: 65, intolerant: [bad])
        ]
        let result = RefineNutritionPlanFromFeedbackUseCase.refine(
            preferences: prefs, feedbacks: feedbacks
        )
        #expect(result.refinedPreferences.excludedProductIds.contains(bad))
    }

    @Test("Product intolerant only once is NOT excluded")
    func intolerantProductNotExcludedAfterOneStrike() {
        let maybeBad = UUID()
        let prefs = NutritionPreferences.default
        let feedbacks = [
            feedback(actual: 60, intolerant: [maybeBad]),
            feedback(actual: 65)
        ]
        let result = RefineNutritionPlanFromFeedbackUseCase.refine(
            preferences: prefs, feedbacks: feedbacks
        )
        #expect(!result.refinedPreferences.excludedProductIds.contains(maybeBad))
    }

    // MARK: - Rule 3: promote favorites

    @Test("Product tolerated 3+ times with low symptoms is promoted")
    func toleratedProductPromotedToFavorite() {
        let good = UUID()
        let prefs = NutritionPreferences.default
        let feedbacks = [
            feedback(actual: 60, symptoms: (1, 0, 0, 0), tolerated: [good]),
            feedback(actual: 65, symptoms: (2, 0, 1, 0), tolerated: [good]),
            feedback(actual: 70, symptoms: (0, 1, 0, 0), tolerated: [good])
        ]
        let result = RefineNutritionPlanFromFeedbackUseCase.refine(
            preferences: prefs, feedbacks: feedbacks
        )
        #expect(result.refinedPreferences.favoriteProductIds.contains(good))
    }

    // MARK: - Rule 4: under-fueling note

    @Test("Bonking while under-fueling surfaces an advisory note without lowering ceiling")
    func bonkingUnderFuelAdvisoryNote() {
        let prefs = NutritionPreferences.default
        let feedbacks = [
            feedback(planned: 80, actual: 45, bonked: true),
            feedback(planned: 80, actual: 50, bonked: true)
        ]
        let result = RefineNutritionPlanFromFeedbackUseCase.refine(
            preferences: prefs, feedbacks: feedbacks
        )
        #expect(result.notes.contains { $0.lowercased().contains("bonked") })
    }
}
