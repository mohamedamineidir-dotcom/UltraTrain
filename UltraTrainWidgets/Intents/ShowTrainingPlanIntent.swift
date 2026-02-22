import AppIntents
import Foundation

struct ShowTrainingPlanIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Training Plan"
    static let description: IntentDescription = "Opens UltraTrain to your training plan."
    static let openAppWhenRun = true

    init() {}

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: WidgetDataKeys.suiteName)
        defaults?.set("plan", forKey: WidgetDataKeys.deepLink)
        return .result()
    }
}
