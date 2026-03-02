import Foundation
import os

enum WatchComplicationDataStore {

    private static let logger = Logger(subsystem: "com.ultratrain.app", category: "watch")

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: WatchComplicationDataKeys.suiteName)
    }

    static func read() -> WatchComplicationData? {
        guard let data = defaults?.data(forKey: WatchComplicationDataKeys.complicationData) else {
            return nil
        }
        do {
            return try JSONDecoder().decode(WatchComplicationData.self, from: data)
        } catch {
            logger.warning("WatchComplicationDataStore: failed to decode complication data: \(error)")
            return nil
        }
    }

    static func write(_ complicationData: WatchComplicationData) {
        do {
            let encoded = try JSONEncoder().encode(complicationData)
            defaults?.set(encoded, forKey: WatchComplicationDataKeys.complicationData)
        } catch {
            logger.warning("WatchComplicationDataStore: failed to encode complication data: \(error)")
        }
    }

    static func clear() {
        defaults?.removeObject(forKey: WatchComplicationDataKeys.complicationData)
    }
}
