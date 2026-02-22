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
    case healthKitWriteDenied
    case settingsNotFound
    case exportFailed(reason: String)
    case importFailed(reason: String)
    case gpxParsingFailed(reason: String)
    case stravaAuthFailed(reason: String)
    case stravaUploadFailed(reason: String)
    case stravaImportFailed(reason: String)
    case biometricFailed(reason: String)
    case notificationDenied
    case gearNotFound
    case workoutRecipeNotFound
    case challengeNotFound
    case iCloudAccountUnavailable
    case iCloudSyncFailed(reason: String)
    case weatherUnavailable(reason: String)
    case socialProfileNotFound
    case friendRequestFailed(reason: String)
    case sharingFailed(reason: String)
    case cloudKitPermissionDenied
    case groupChallengeNotFound
    case routeNotFound
    case invalidIntervalWorkout(reason: String)
    case intervalWorkoutNotFound
    case emergencyContactNotFound
    case motionServiceUnavailable
    case crewTrackingUnavailable
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
        case .healthKitWriteDenied:
            return "Cannot save workouts to Apple Health. Please allow write access in the Health app."
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
        case .biometricFailed(let reason):
            return "Biometric authentication failed: \(reason)"
        case .notificationDenied:
            return "Notification permission was denied. Enable in iOS Settings."
        case .gearNotFound:
            return "Gear item not found."
        case .workoutRecipeNotFound:
            return "Workout recipe not found."
        case .challengeNotFound:
            return "Challenge not found."
        case .iCloudAccountUnavailable:
            return "iCloud account is not available. Sign in to iCloud in iOS Settings."
        case .iCloudSyncFailed(let reason):
            return "iCloud sync failed: \(reason)"
        case .weatherUnavailable(let reason):
            return "Weather data unavailable: \(reason)"
        case .socialProfileNotFound:
            return "Social profile not found. Please set up your profile."
        case .friendRequestFailed(let reason):
            return "Friend request failed: \(reason)"
        case .sharingFailed(let reason):
            return "Sharing failed: \(reason)"
        case .cloudKitPermissionDenied:
            return "CloudKit permission denied. Please allow access in Settings."
        case .groupChallengeNotFound:
            return "Group challenge not found."
        case .routeNotFound:
            return "Route not found."
        case .invalidIntervalWorkout(let reason):
            return "Invalid interval workout: \(reason)"
        case .intervalWorkoutNotFound:
            return "Interval workout not found."
        case .emergencyContactNotFound:
            return "Emergency contact not found."
        case .motionServiceUnavailable:
            return "Motion services are unavailable on this device."
        case .crewTrackingUnavailable:
            return "Crew tracking is currently unavailable."
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
}
