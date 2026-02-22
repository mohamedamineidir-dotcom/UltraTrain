import AppIntents
import Foundation

struct ShowWeeklyProgressIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Weekly Progress"
    static let description: IntentDescription = "Shows your training progress for the current week."

    init() {}

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let defaults = UserDefaults(suiteName: WidgetDataKeys.suiteName),
              let data = defaults.data(forKey: WidgetDataKeys.weeklyProgress),
              let progress = try? JSONDecoder().decode(WidgetWeeklyProgressData.self, from: data) else {
            return .result(dialog: "No weekly progress data available.")
        }

        let dialog = """
        Week \(progress.weekNumber), \(progress.phase) phase. \
        \(String(format: "%.1f", progress.actualDistanceKm)) of \
        \(String(format: "%.1f", progress.targetDistanceKm)) km, \
        \(Int(progress.actualElevationGainM)) of \
        \(Int(progress.targetElevationGainM)) m elevation.
        """

        return .result(dialog: "\(dialog)")
    }
}
