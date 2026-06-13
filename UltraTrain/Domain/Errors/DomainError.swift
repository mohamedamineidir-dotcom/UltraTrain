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
    case validationFailed(field: String, reason: String)
    case invalidGPSData(reason: String)
    case subscriptionRequired
    case purchaseFailed(reason: String)
    case unknown(message: String)
}

extension DomainError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .athleteNotFound:
            return String(localized: "derr.athleteNotFound", defaultValue: "Athlete profile not found. Please complete onboarding.")
        case .raceNotFound:
            return String(localized: "derr.raceNotFound", defaultValue: "Race not found.")
        case .trainingPlanNotFound:
            return String(localized: "derr.trainingPlanNotFound", defaultValue: "No active training plan found.")
        case .nutritionPlanNotFound:
            return String(localized: "derr.nutritionPlanNotFound", defaultValue: "No nutrition plan found for this race.")
        case .invalidTrainingPlan(let reason):
            return String(localized: "derr.invalidTrainingPlan", defaultValue: "Invalid training plan: \(reason)")
        case .insufficientData(let reason):
            return String(localized: "derr.insufficientData", defaultValue: "Not enough data: \(reason)")
        case .networkUnavailable:
            return String(localized: "derr.networkUnavailable", defaultValue: "No internet connection. Please try again later.")
        case .unauthorized:
            return String(localized: "derr.unauthorized", defaultValue: "Session expired. Please sign in again.")
        case .serverError(let message):
            return String(localized: "derr.serverError", defaultValue: "Server error: \(message)")
        case .persistenceError(let message):
            return String(localized: "derr.persistenceError", defaultValue: "Storage error: \(message)")
        case .locationUnavailable:
            return String(localized: "derr.locationUnavailable", defaultValue: "Location services are unavailable.")
        case .healthKitUnavailable:
            return String(localized: "derr.healthKitUnavailable", defaultValue: "HealthKit is not available on this device.")
        case .healthKitWriteDenied:
            return String(localized: "derr.healthKitWriteDenied", defaultValue: "Cannot save workouts to Apple Health. Please allow write access in the Health app.")
        case .settingsNotFound:
            return String(localized: "derr.settingsNotFound", defaultValue: "App settings not found.")
        case .exportFailed(let reason):
            return String(localized: "derr.exportFailed", defaultValue: "Export failed: \(reason)")
        case .importFailed(let reason):
            return String(localized: "derr.importFailed", defaultValue: "Import failed: \(reason)")
        case .gpxParsingFailed(let reason):
            return String(localized: "derr.gpxParsingFailed", defaultValue: "Failed to parse GPX file: \(reason)")
        case .stravaAuthFailed(let reason):
            return String(localized: "derr.stravaAuthFailed", defaultValue: "Strava authentication failed: \(reason)")
        case .stravaUploadFailed(let reason):
            return String(localized: "derr.stravaUploadFailed", defaultValue: "Failed to upload to Strava: \(reason)")
        case .stravaImportFailed(let reason):
            return String(localized: "derr.stravaImportFailed", defaultValue: "Failed to import from Strava: \(reason)")
        case .biometricFailed(let reason):
            return String(localized: "derr.biometricFailed", defaultValue: "Biometric authentication failed: \(reason)")
        case .notificationDenied:
            return String(localized: "derr.notificationDenied", defaultValue: "Notification permission was denied. Enable in iOS Settings.")
        case .gearNotFound:
            return String(localized: "derr.gearNotFound", defaultValue: "Gear item not found.")
        case .workoutRecipeNotFound:
            return String(localized: "derr.workoutRecipeNotFound", defaultValue: "Workout recipe not found.")
        case .challengeNotFound:
            return String(localized: "derr.challengeNotFound", defaultValue: "Challenge not found.")
        case .iCloudAccountUnavailable:
            return String(localized: "derr.iCloudAccountUnavailable", defaultValue: "iCloud account is not available. Sign in to iCloud in iOS Settings.")
        case .iCloudSyncFailed(let reason):
            return String(localized: "derr.iCloudSyncFailed", defaultValue: "iCloud sync failed: \(reason)")
        case .weatherUnavailable(let reason):
            return String(localized: "derr.weatherUnavailable", defaultValue: "Weather data unavailable: \(reason)")
        case .socialProfileNotFound:
            return String(localized: "derr.socialProfileNotFound", defaultValue: "Social profile not found. Please set up your profile.")
        case .friendRequestFailed(let reason):
            return String(localized: "derr.friendRequestFailed", defaultValue: "Friend request failed: \(reason)")
        case .sharingFailed(let reason):
            return String(localized: "derr.sharingFailed", defaultValue: "Sharing failed: \(reason)")
        case .cloudKitPermissionDenied:
            return String(localized: "derr.cloudKitPermissionDenied", defaultValue: "CloudKit permission denied. Please allow access in Settings.")
        case .groupChallengeNotFound:
            return String(localized: "derr.groupChallengeNotFound", defaultValue: "Group challenge not found.")
        case .routeNotFound:
            return String(localized: "derr.routeNotFound", defaultValue: "Route not found.")
        case .invalidIntervalWorkout(let reason):
            return String(localized: "derr.invalidIntervalWorkout", defaultValue: "Invalid interval workout: \(reason)")
        case .intervalWorkoutNotFound:
            return String(localized: "derr.intervalWorkoutNotFound", defaultValue: "Interval workout not found.")
        case .emergencyContactNotFound:
            return String(localized: "derr.emergencyContactNotFound", defaultValue: "Emergency contact not found.")
        case .motionServiceUnavailable:
            return String(localized: "derr.motionServiceUnavailable", defaultValue: "Motion services are unavailable on this device.")
        case .crewTrackingUnavailable:
            return String(localized: "derr.crewTrackingUnavailable", defaultValue: "Crew tracking is currently unavailable.")
        case .validationFailed(let field, let reason):
            return String(localized: "derr.validationFailed", defaultValue: "Invalid \(field): \(reason)")
        case .invalidGPSData(let reason):
            return String(localized: "derr.invalidGPSData", defaultValue: "Invalid GPS data: \(reason)")
        case .subscriptionRequired:
            return String(localized: "derr.subscriptionRequired", defaultValue: "A subscription is required to use UltraTrain.")
        case .purchaseFailed(let reason):
            return String(localized: "derr.purchaseFailed", defaultValue: "Purchase failed: \(reason)")
        case .unknown(let message):
            return String(localized: "derr.unknown", defaultValue: "An unexpected error occurred: \(message)")
        }
    }
}
