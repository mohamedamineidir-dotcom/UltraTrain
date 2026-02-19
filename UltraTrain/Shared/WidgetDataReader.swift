import Foundation

enum WidgetDataReader {

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: WidgetDataKeys.suiteName)
    }

    static func readNextSession() -> WidgetSessionData? {
        read(key: WidgetDataKeys.nextSession)
    }

    static func readRaceCountdown() -> WidgetRaceData? {
        read(key: WidgetDataKeys.raceCountdown)
    }

    static func readWeeklyProgress() -> WidgetWeeklyProgressData? {
        read(key: WidgetDataKeys.weeklyProgress)
    }

    static func readLastRun() -> WidgetLastRunData? {
        read(key: WidgetDataKeys.lastRun)
    }

    static func readFitnessData() -> WidgetFitnessData? {
        read(key: WidgetDataKeys.fitnessData)
    }

    static func readPendingAction() -> WidgetPendingAction? {
        read(key: WidgetDataKeys.pendingAction)
    }

    static func clearPendingAction() {
        defaults?.removeObject(forKey: WidgetDataKeys.pendingAction)
    }

    private static func read<T: Decodable>(key: String) -> T? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
