import AppIntents
import Foundation

struct MarkSessionCompleteIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Session Complete"
    static let description: IntentDescription = "Marks the next training session as completed."

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
            action: "complete",
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
