import Foundation
import Testing
@testable import UltraTrain

@Suite("WeatherCache Tests")
struct WeatherCacheTests {

    // MARK: - Key Rounding

    @Test("Key rounds coordinates to 2 decimal places")
    func keyRoundsCoordinates() {
        let key1 = WeatherCache.Key(lat: 45.12345, lon: 6.67345, type: .current)
        let key2 = WeatherCache.Key(lat: 45.12999, lon: 6.67001, type: .current)

        // 45.12345 * 100 = 4512.345 -> rounded = 4512.0 -> /100 = 45.12
        // 45.12999 * 100 = 4513.0   -> rounded = 4513.0 -> /100 = 45.13
        #expect(key1 != key2)

        let key3 = WeatherCache.Key(lat: 45.12111, lon: 6.67111, type: .current)
        // 45.12111 * 100 = 4512.111 -> rounded = 4512.0 -> /100 = 45.12
        // 6.67345 * 100 = 667.345 -> rounded = 667.0 -> /100 = 6.67
        // 6.67111 * 100 = 667.111 -> rounded = 667.0 -> /100 = 6.67
        #expect(key1 == key3)
    }

    @Test("Keys with different types are not equal")
    func keysWithDifferentTypesNotEqual() {
        let key1 = WeatherCache.Key(lat: 45.0, lon: 6.0, type: .current)
        let key2 = WeatherCache.Key(lat: 45.0, lon: 6.0, type: .hourly)
        let key3 = WeatherCache.Key(lat: 45.0, lon: 6.0, type: .daily)

        #expect(key1 != key2)
        #expect(key2 != key3)
        #expect(key1 != key3)
    }

    // MARK: - Get / Set

    @Test("get returns nil for missing key")
    func getMissingKeyReturnsNil() async {
        let cache = WeatherCache()
        let key = WeatherCache.Key(lat: 45.0, lon: 6.0, type: .current)

        let result: String? = await cache.get(for: key)
        #expect(result == nil)
    }

    @Test("set and get round-trips a value")
    func setAndGetRoundTrips() async {
        let cache = WeatherCache()
        let key = WeatherCache.Key(lat: 45.0, lon: 6.0, type: .current)

        await cache.set("Sunny, 25C", for: key, ttl: 300)
        let result: String? = await cache.get(for: key)

        #expect(result == "Sunny, 25C")
    }

    @Test("get returns nil for expired entry")
    func getExpiredEntryReturnsNil() async {
        let cache = WeatherCache()
        let key = WeatherCache.Key(lat: 45.0, lon: 6.0, type: .hourly)

        // Set with TTL of 0 seconds (already expired)
        await cache.set("Rainy", for: key, ttl: -1)

        let result: String? = await cache.get(for: key)
        #expect(result == nil)
    }

    @Test("get returns nil when type mismatch")
    func getTypeMismatchReturnsNil() async {
        let cache = WeatherCache()
        let key = WeatherCache.Key(lat: 45.0, lon: 6.0, type: .current)

        await cache.set(42, for: key, ttl: 300)

        // Try to get as String instead of Int
        let result: String? = await cache.get(for: key)
        #expect(result == nil)
    }

    // MARK: - Clear

    @Test("clear removes all entries")
    func clearRemovesAllEntries() async {
        let cache = WeatherCache()
        let key1 = WeatherCache.Key(lat: 45.0, lon: 6.0, type: .current)
        let key2 = WeatherCache.Key(lat: 46.0, lon: 7.0, type: .daily)

        await cache.set("value1", for: key1, ttl: 300)
        await cache.set("value2", for: key2, ttl: 300)

        await cache.clear()

        let result1: String? = await cache.get(for: key1)
        let result2: String? = await cache.get(for: key2)

        #expect(result1 == nil)
        #expect(result2 == nil)
    }

    @Test("overwriting a key replaces the previous value")
    func overwriteReplacesValue() async {
        let cache = WeatherCache()
        let key = WeatherCache.Key(lat: 45.0, lon: 6.0, type: .current)

        await cache.set("first", for: key, ttl: 300)
        await cache.set("second", for: key, ttl: 300)

        let result: String? = await cache.get(for: key)
        #expect(result == "second")
    }
}
