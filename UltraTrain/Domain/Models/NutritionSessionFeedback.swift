import Foundation

/// Feedback captured after a gut-training long run or race.
///
/// Feeds the Phase 4 feedback loop: the refinement use case aggregates these
/// across a training block and adjusts the race-day plan (excludes intolerant
/// products, clamps carbs/hr target to observed tolerance, updates sweat
/// profile from actual race data).
///
/// Research basis: NIQEC (Nutritional Intake Questionnaire for Endurance
/// Competitions, 2023) validated the GI symptom scale (0-10) used here.
struct NutritionSessionFeedback: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    var sessionId: UUID
    var plannedCarbsPerHour: Int
    var actualCarbsConsumed: Int
    var durationMinutes: Int

    // GI symptoms — 0 none, 10 severe (NIQEC scale)
    var nausea: Int
    var bloating: Int
    var cramping: Int
    var urgency: Int

    // Performance
    var energyLevel: Int     // 0 bonk, 10 fresh at finish
    var bonked: Bool

    // Product-level tolerance
    var toleratedProductIds: Set<UUID>
    var intolerantProductIds: Set<UUID>

    var notes: String?
    var createdAt: Date
}
