import Foundation

struct AnalyzedFoodItem: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var portionGrams: Double
    var calories: Int
    var carbsGrams: Double
    var proteinGrams: Double
    var fatGrams: Double
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
