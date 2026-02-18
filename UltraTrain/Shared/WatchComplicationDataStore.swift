import Foundation

enum WatchComplicationDataStore {

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: WatchComplicationDataKeys.suiteName)
    }

    static func read() -> WatchComplicationData? {
        guard let data = defaults?.data(forKey: WatchComplicationDataKeys.complicationData) else {
            return nil
        }
        return try? JSONDecoder().decode(WatchComplicationData.self, from: data)
    }

    static func write(_ complicationData: WatchComplicationData) {
        guard let encoded = try? JSONEncoder().encode(complicationData) else { return }
        defaults?.set(encoded, forKey: WatchComplicationDataKeys.complicationData)
    }

    static func clear() {
        defaults?.removeObject(forKey: WatchComplicationDataKeys.complicationData)
    }
}
