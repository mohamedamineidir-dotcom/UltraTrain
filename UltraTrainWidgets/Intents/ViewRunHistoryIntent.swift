import AppIntents
import Foundation

struct ViewRunHistoryIntent: AppIntent {
    static let title: LocalizedStringResource = "View Run History"
    static let description: IntentDescription = "Opens UltraTrain to the run history screen."
    static let openAppWhenRun = true

    init() {}

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: WidgetDataKeys.suiteName)
        defaults?.set("runHistory", forKey: WidgetDataKeys.deepLink)
        return .result()
    }
}
