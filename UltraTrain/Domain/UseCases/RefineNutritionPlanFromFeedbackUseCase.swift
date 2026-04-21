import Foundation

/// Applies recent gut-training feedback to the athlete's nutrition
/// preferences so the next generated plan reflects what the gut can
/// actually tolerate.
///
/// ## Rules (summarised from Pfitzinger / Daniels / Jeukendrup coaching
/// practice and the NIQEC validated scale)
///
/// 1. **Carbs/hour tolerance ceiling**
///    Take the highest `actualCarbsConsumed` across sessions where GI
///    symptoms stayed tolerable (max symptom <= 5). That's the proven
///    tolerance. If it's lower than the planned target we clamp
///    `carbsPerHourTolerance` so the generator won't re-prescribe above it.
///    If all sessions stayed well below plan but symptoms were high, we
///    drop the ceiling another 10% to force a deload.
///
/// 2. **Product intolerance**
///    Any product that appears in `intolerantProductIds` on **2 or more
///    sessions** is added to `excludedProductIds` so future plans skip
///    it. Single-occurrence intolerance is ignored (could be one bad
///    day).
///
/// 3. **Favorites promotion**
///    Products appearing in `toleratedProductIds` on 3+ sessions with
///    low symptoms get promoted to `favoriteProductIds` (top of
///    selector priority).
///
/// 4. **Under-fueling detection**
///    If multiple sessions have `bonked == true` while `actualCarbsConsumed`
///    is below the planned target, we do NOT lower the ceiling. Instead
///    we leave a caller-visible note — the athlete may simply have
///    under-fueled rather than being intolerant.
enum RefineNutritionPlanFromFeedbackUseCase {

    /// Result of refinement: an updated `NutritionPreferences` plus a
    /// human-readable note explaining what changed.
    struct RefinementResult: Equatable, Sendable {
        let refinedPreferences: NutritionPreferences
        let notes: [String]
        let feedbacksConsidered: Int
    }

    /// Applies the rules above. Returns the unchanged preferences (with an
    /// empty notes list) if there aren't at least 2 feedback sessions to
    /// draw signal from — one feedback is too noisy to act on.
    static func refine(
        preferences: NutritionPreferences,
        feedbacks: [NutritionSessionFeedback]
    ) -> RefinementResult {
        guard feedbacks.count >= 2 else {
            return RefinementResult(
                refinedPreferences: preferences,
                notes: [],
                feedbacksConsidered: feedbacks.count
            )
        }

        var refined = preferences
        var notes: [String] = []

        // --- Rule 1: tolerance ceiling ------------------------------------
        let tolerableFeedbacks = feedbacks.filter { $0.maxSymptom <= 5 && !$0.bonked }
        if let best = tolerableFeedbacks.map(\.actualCarbsConsumed).max(), best > 0 {
            let previousCeiling = refined.carbsPerHourTolerance
            // Only lower the ceiling; never raise it speculatively (athlete
            // opts in via the onboarding sheet).
            if previousCeiling == nil || best < previousCeiling! {
                refined.carbsPerHourTolerance = best
                notes.append("Carbs/hr ceiling updated to \(best) g — highest you've comfortably tolerated.")
            }
        }

        // Aggressive deload if every session had >5 GI symptoms
        let highSymptomFeedbacks = feedbacks.filter { $0.maxSymptom > 5 }
        if highSymptomFeedbacks.count >= 2,
           highSymptomFeedbacks.count == feedbacks.count,
           let mostRecent = feedbacks.first {
            let dropped = max(30, Int(Double(mostRecent.actualCarbsConsumed) * 0.85))
            if dropped < (refined.carbsPerHourTolerance ?? Int.max) {
                refined.carbsPerHourTolerance = dropped
                notes.append("Carbs/hr ceiling dropped 15% to \(dropped) g — GI symptoms reported on every recent session.")
            }
        }

        // --- Rule 2: exclude repeatedly intolerant products ---------------
        var intoleranceCount: [UUID: Int] = [:]
        for feedback in feedbacks {
            for productId in feedback.intolerantProductIds {
                intoleranceCount[productId, default: 0] += 1
            }
        }
        let newExclusions = intoleranceCount
            .filter { $0.value >= 2 }
            .map(\.key)
            .filter { !refined.excludedProductIds.contains($0) }

        if !newExclusions.isEmpty {
            for id in newExclusions {
                refined.excludedProductIds.insert(id)
            }
            notes.append("\(newExclusions.count) product\(newExclusions.count == 1 ? "" : "s") excluded from future plans (GI issues on 2+ sessions).")
        }

        // --- Rule 3: promote favorites ------------------------------------
        var toleranceCount: [UUID: Int] = [:]
        for feedback in feedbacks where feedback.maxSymptom <= 4 {
            for productId in feedback.toleratedProductIds {
                toleranceCount[productId, default: 0] += 1
            }
        }
        let newFavorites = toleranceCount
            .filter { $0.value >= 3 }
            .map(\.key)
            .filter { !refined.favoriteProductIds.contains($0) }

        if !newFavorites.isEmpty {
            for id in newFavorites {
                refined.favoriteProductIds.append(id)
            }
            notes.append("\(newFavorites.count) product\(newFavorites.count == 1 ? "" : "s") promoted to favorites (well-tolerated on 3+ sessions).")
        }

        // --- Rule 4: under-fueling detection ------------------------------
        let bonkedUnderplanned = feedbacks.filter {
            $0.bonked && $0.actualCarbsConsumed < $0.plannedCarbsPerHour
        }
        if bonkedUnderplanned.count >= 2 {
            notes.append("You've bonked \(bonkedUnderplanned.count) times with actual intake below plan — try hitting the full target before considering a lower ceiling.")
        }

        return RefinementResult(
            refinedPreferences: refined,
            notes: notes,
            feedbacksConsidered: feedbacks.count
        )
    }
}

private extension NutritionSessionFeedback {
    /// Worst GI symptom across the four NIQEC-style axes.
    var maxSymptom: Int {
        max(max(nausea, bloating), max(cramping, urgency))
    }
}
