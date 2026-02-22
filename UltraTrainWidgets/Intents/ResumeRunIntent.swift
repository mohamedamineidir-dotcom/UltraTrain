import AppIntents
import Foundation

struct ResumeRunIntent: AppIntent {
    static let title: LocalizedStringResource = "Resume Run"
    static let description: IntentDescription = "Resumes the paused run from the Live Activity."
    static let openAppWhenRun = false

    init() {}

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: WidgetDataKeys.suiteName)
        defaults?.set("resume", forKey: WidgetDataKeys.runCommand)
        return .result()
    }
}
