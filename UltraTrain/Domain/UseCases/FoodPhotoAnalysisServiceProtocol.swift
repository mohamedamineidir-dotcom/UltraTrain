import Foundation

struct AnalyzedFoodItem: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var portionGrams: Double
    var calories: Int
    var carbsGrams: Double
    var proteinGrams: Double
    var fatGrams: Double

    /// Scales calories and all three macros by `ratio` — used when the
    /// athlete corrects the portion size or the total calories, both of
    /// which mean "there was more/less of this same food," not "the
    /// composition is different." Portion itself isn't touched here; the
    /// caller sets whichever of portion/calories triggered the edit
    /// separately, after scaling everything else off the pre-edit ratio.
    mutating func scale(by ratio: Double) {
        calories = Int((Double(calories) * ratio).rounded())
        carbsGrams = (carbsGrams * ratio * 10).rounded() / 10
        proteinGrams = (proteinGrams * ratio * 10).rounded() / 10
        fatGrams = (fatGrams * ratio * 10).rounded() / 10
    }

    /// Re-derives calories from the macros via the standard Atwater
    /// factors (4 kcal/g carbs & protein, 9 kcal/g fat) — used when the
    /// athlete edits an individual macro directly, meaning the detected
    /// composition itself was wrong, not just the portion.
    mutating func recalculateCaloriesFromMacros() {
        calories = Int((carbsGrams * 4 + proteinGrams * 4 + fatGrams * 9).rounded())
    }
}

enum FoodPhotoAnalysisError: Error, LocalizedError {
    case noApiKey
    case imageEncodingFailed
    case invalidResponse
    case noFoodDetected
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noApiKey:
            return "OpenAI API key not configured. Add it in Secrets.xcconfig."
        case .imageEncodingFailed:
            return "Failed to process the photo. Please try again."
        case .invalidResponse:
            return "Could not parse the AI response. Please try again."
        case .noFoodDetected:
            return "No food items detected in the photo. Try a clearer photo."
        case .apiError(let message):
            return message
        }
    }
}

protocol FoodPhotoAnalysisServiceProtocol: Sendable {
    func analyzePhoto(_ imageData: Data) async throws -> [AnalyzedFoodItem]
}
