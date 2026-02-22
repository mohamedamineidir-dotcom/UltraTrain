import AppIntents
import Foundation

struct ShowFitnessIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Fitness Summary"
    static let description: IntentDescription = "Shows your current fitness, fatigue, and form."

    init() {}

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let defaults = UserDefaults(suiteName: WidgetDataKeys.suiteName),
              let data = defaults.data(forKey: WidgetDataKeys.fitnessData),
              let fitness = try? JSONDecoder().decode(WidgetFitnessData.self, from: data) else {
            return .result(dialog: "No fitness data available yet.")
        }

        let status: String
        if fitness.form >= 10 {
            status = "You're in great form."
        } else if fitness.form >= 0 {
            status = "Your form is balanced."
        } else if fitness.form >= -10 {
            status = "You're carrying some fatigue."
        } else {
            status = "Heavy training load \u{2014} consider extra recovery."
        }

        let dialog = """
        Fitness: \(String(format: "%.0f", fitness.fitness)), \
        Fatigue: \(String(format: "%.0f", fitness.fatigue)), \
        Form: \(String(format: "%.0f", fitness.form)). \
        \(status)
        """

        return .result(dialog: "\(dialog)")
    }
}
