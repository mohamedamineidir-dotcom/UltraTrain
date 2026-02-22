import AppIntents
import Foundation

struct ShowRaceCountdownIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Race Countdown"
    static let description: IntentDescription = "Shows how many days until your next race."

    init() {}

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let defaults = UserDefaults(suiteName: WidgetDataKeys.suiteName),
              let data = defaults.data(forKey: WidgetDataKeys.raceCountdown),
              let race = try? JSONDecoder().decode(WidgetRaceData.self, from: data) else {
            return .result(dialog: "No upcoming race found.")
        }

        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: .now),
                                           to: calendar.startOfDay(for: race.date)).day ?? 0

        let dialog = """
        Your race \(race.name) is in \(days) days. \
        \(String(format: "%.0f", race.distanceKm)) km with \
        \(Int(race.elevationGainM)) m elevation gain. \
        Training is \(Int(race.planCompletionPercent))% complete.
        """

        return .result(dialog: "\(dialog)")
    }
}
