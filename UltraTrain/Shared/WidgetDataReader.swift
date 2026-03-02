import Foundation
import os

enum WidgetDataReader {

    private static let logger = Logger(subsystem: "com.ultratrain.app", category: "widget")

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

    static func readRunCommand() -> String? {
        defaults?.string(forKey: WidgetDataKeys.runCommand)
    }

    static func clearRunCommand() {
        defaults?.removeObject(forKey: WidgetDataKeys.runCommand)
    }

    private static func read<T: Decodable>(key: String) -> T? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            logger.warning("WidgetDataReader: failed to decode data for key \(key): \(error)")
            return nil
        }
    }
}
