import Foundation

actor WeatherCache {

    struct Key: Hashable {
        let lat: Double
        let lon: Double
        let type: RequestType

        init(lat: Double, lon: Double, type: RequestType) {
            self.lat = (lat * 100).rounded() / 100
            self.lon = (lon * 100).rounded() / 100
            self.type = type
        }
    }

    enum RequestType: Hashable {
        case current
        case hourly
        case daily
    }

    private struct CacheEntry {
        let value: Any
        let expiresAt: Date
    }

    private var entries: [Key: CacheEntry] = [:]

    func get<T>(for key: Key) -> T? {
        guard let entry = entries[key],
              entry.expiresAt > Date.now,
              let value = entry.value as? T else {
            entries[key] = nil
            return nil
        }
        return value
    }

    func set(_ value: Any, for key: Key, ttl: TimeInterval) {
        entries[key] = CacheEntry(value: value, expiresAt: Date.now.addingTimeInterval(ttl))
    }

    func clear() {
        entries.removeAll()
    }
}
