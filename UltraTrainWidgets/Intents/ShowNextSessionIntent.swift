import AppIntents
import Foundation

struct ShowNextSessionIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Next Session"
    static let description: IntentDescription = "Shows details about your next training session."

    init() {}

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let defaults = UserDefaults(suiteName: WidgetDataKeys.suiteName),
              let data = defaults.data(forKey: WidgetDataKeys.nextSession),
              let session = try? JSONDecoder().decode(WidgetSessionData.self, from: data) else {
            return .result(dialog: "No upcoming session found.")
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: session.date)

        let dialog = """
        Your next session is \(session.displayName) on \(dateString). \
        \(String(format: "%.1f", session.plannedDistanceKm)) km with \
        \(Int(session.plannedElevationGainM)) m elevation gain. \
        Intensity: \(session.intensity).
        """

        return .result(dialog: "\(dialog)")
    }
}
