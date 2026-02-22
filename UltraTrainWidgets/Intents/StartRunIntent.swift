import AppIntents
import Foundation

struct StartRunIntent: AppIntent {
    static let title: LocalizedStringResource = "Start a Run"
    static let description: IntentDescription = "Opens UltraTrain to the run tracking screen."
    static let openAppWhenRun = true

    init() {}

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: WidgetDataKeys.suiteName)
        defaults?.set("run", forKey: WidgetDataKeys.deepLink)
        return .result()
    }
}
