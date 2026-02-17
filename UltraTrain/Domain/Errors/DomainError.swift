import Foundation

enum DomainError: Error, Equatable, Sendable {
    case athleteNotFound
    case raceNotFound
    case trainingPlanNotFound
    case nutritionPlanNotFound
    case invalidTrainingPlan(reason: String)
    case insufficientData(reason: String)
    case networkUnavailable
    case unauthorized
    case serverError(message: String)
    case persistenceError(message: String)
    case locationUnavailable
    case healthKitUnavailable
    case settingsNotFound
    case exportFailed(reason: String)
    case importFailed(reason: String)
    case gpxParsingFailed(reason: String)
    case stravaAuthFailed(reason: String)
    case stravaUploadFailed(reason: String)
    case stravaImportFailed(reason: String)
    case unknown(message: String)
}

extension DomainError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .athleteNotFound:
            return "Athlete profile not found. Please complete onboarding."
        case .raceNotFound:
            return "Race not found."
        case .trainingPlanNotFound:
            return "No active training plan found."
        case .nutritionPlanNotFound:
            return "No nutrition plan found for this race."
        case .invalidTrainingPlan(let reason):
            return "Invalid training plan: \(reason)"
        case .insufficientData(let reason):
            return "Not enough data: \(reason)"
        case .networkUnavailable:
            return "No internet connection. Please try again later."
        case .unauthorized:
            return "Session expired. Please sign in again."
        case .serverError(let message):
            return "Server error: \(message)"
        case .persistenceError(let message):
            return "Storage error: \(message)"
        case .locationUnavailable:
            return "Location services are unavailable."
        case .healthKitUnavailable:
            return "HealthKit is not available on this device."
        case .settingsNotFound:
            return "App settings not found."
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        case .importFailed(let reason):
            return "Import failed: \(reason)"
        case .gpxParsingFailed(let reason):
            return "Failed to parse GPX file: \(reason)"
        case .stravaAuthFailed(let reason):
            return "Strava authentication failed: \(reason)"
        case .stravaUploadFailed(let reason):
            return "Failed to upload to Strava: \(reason)"
        case .stravaImportFailed(let reason):
            return "Failed to import from Strava: \(reason)"
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
}
