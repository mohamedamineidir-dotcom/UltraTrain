import AppIntents
import Foundation

struct PauseRunIntent: AppIntent {
    static let title: LocalizedStringResource = "Pause Run"
    static let description: IntentDescription = "Pauses the active run from the Live Activity."
    static let openAppWhenRun = false

    init() {}

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: WidgetDataKeys.suiteName)
        defaults?.set("pause", forKey: WidgetDataKeys.runCommand)
        return .result()
    }
}
