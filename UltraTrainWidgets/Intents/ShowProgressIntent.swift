import AppIntents
import Foundation

struct ShowProgressIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Progress"
    static let description: IntentDescription = "Opens UltraTrain to your progress dashboard."
    static let openAppWhenRun = true

    init() {}

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: WidgetDataKeys.suiteName)
        defaults?.set("dashboard", forKey: WidgetDataKeys.deepLink)
        return .result()
    }
}
