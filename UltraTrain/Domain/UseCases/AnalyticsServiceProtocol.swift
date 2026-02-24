import Foundation

enum AnalyticsEvent: String, Sendable {
    case appOpened
    case runStarted
    case runCompleted
    case runPaused
    case runResumed
    case planGenerated
    case planAdjusted
    case raceAdded
    case raceDeleted
    case nutritionPlanGenerated
    case finishTimeEstimated
    case settingsChanged
    case healthKitConnected
    case stravaConnected
    case exportCompleted
    case onboardingCompleted
    case achievementUnlocked
    case challengeJoined
    case routeSaved
}

protocol AnalyticsServiceProtocol: Sendable {
    func track(_ event: AnalyticsEvent)
    func track(_ event: AnalyticsEvent, properties: [String: String])
    func setTrackingEnabled(_ enabled: Bool)
}
