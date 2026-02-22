import AppIntents
import Foundation

struct SkipSessionIntent: AppIntent {
    static let title: LocalizedStringResource = "Skip Session"
    static let description: IntentDescription = "Skips the next training session."
    static let openAppWhenRun = false

    static var parameterSummary: some ParameterSummary {
        Summary("Skip session \(\.$sessionId)")
    }

    @Parameter(title: "Session ID")
    var sessionId: String

    init() {}

    init(sessionId: UUID) {
        self.sessionId = sessionId.uuidString
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: sessionId) else {
            return .result()
        }

        let action = WidgetPendingAction(
            sessionId: uuid,
            action: "skip",
            timestamp: .now
        )

        guard let defaults = UserDefaults(suiteName: WidgetDataKeys.suiteName),
              let encoded = try? JSONEncoder().encode(action) else {
            return .result()
        }

        defaults.set(encoded, forKey: WidgetDataKeys.pendingAction)
        return .result()
    }
}
