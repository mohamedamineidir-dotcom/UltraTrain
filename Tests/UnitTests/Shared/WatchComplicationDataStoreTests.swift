import Foundation
import Testing
@testable import UltraTrain

@Suite("Watch Complication Data Store Tests", .serialized)
struct WatchComplicationDataStoreTests {

    private let testDefaults = UserDefaults(suiteName: "com.ultratrain.test.complication")!

    private func writeToDefaults(_ data: WatchComplicationData) {
        let encoded = try! JSONEncoder().encode(data)
        testDefaults.set(encoded, forKey: WatchComplicationDataKeys.complicationData)
    }

    private func readFromDefaults() -> WatchComplicationData? {
        guard let data = testDefaults.data(forKey: WatchComplicationDataKeys.complicationData) else {
            return nil
        }
        return try? JSONDecoder().decode(WatchComplicationData.self, from: data)
    }

    private func clearDefaults() {
        testDefaults.removeObject(forKey: WatchComplicationDataKeys.complicationData)
    }

    // MARK: - Tests

    @Test("Round-trip with all fields")
    func roundTripAllFields() {
        clearDefaults()

        let original = WatchComplicationData(
            nextSessionType: "Long Run",
            nextSessionIcon: "figure.run",
            nextSessionDistanceKm: 25.0,
            nextSessionDate: Date(timeIntervalSince1970: 1700000000),
            raceCountdownDays: 42,
            raceName: "UTMB"
        )

        writeToDefaults(original)
        let restored = readFromDefaults()

        #expect(restored != nil)
        #expect(restored?.nextSessionType == "Long Run")
        #expect(restored?.nextSessionIcon == "figure.run")
        #expect(restored?.nextSessionDistanceKm == 25.0)
        #expect(restored?.raceCountdownDays == 42)
        #expect(restored?.raceName == "UTMB")

        clearDefaults()
    }

    @Test("Round-trip with only session fields")
    func roundTripSessionOnly() {
        clearDefaults()

        let original = WatchComplicationData(
            nextSessionType: "Intervals",
            nextSessionIcon: "timer",
            nextSessionDistanceKm: 12.0,
            nextSessionDate: .now
        )

        writeToDefaults(original)
        let restored = readFromDefaults()

        #expect(restored?.nextSessionType == "Intervals")
        #expect(restored?.nextSessionIcon == "timer")
        #expect(restored?.nextSessionDistanceKm == 12.0)
        #expect(restored?.raceCountdownDays == nil)
        #expect(restored?.raceName == nil)

        clearDefaults()
    }

    @Test("Round-trip with only race fields")
    func roundTripRaceOnly() {
        clearDefaults()

        let original = WatchComplicationData(
            raceCountdownDays: 7,
            raceName: "CCC"
        )

        writeToDefaults(original)
        let restored = readFromDefaults()

        #expect(restored?.nextSessionType == nil)
        #expect(restored?.nextSessionIcon == nil)
        #expect(restored?.raceCountdownDays == 7)
        #expect(restored?.raceName == "CCC")

        clearDefaults()
    }

    @Test("Read returns nil when no data written")
    func readReturnsNilWhenEmpty() {
        clearDefaults()
        let result = readFromDefaults()
        #expect(result == nil)
    }

    @Test("Clear removes data")
    func clearRemovesData() {
        let data = WatchComplicationData(raceName: "Test")
        writeToDefaults(data)

        #expect(readFromDefaults() != nil)

        clearDefaults()

        #expect(readFromDefaults() == nil)
    }

    @Test("Decodes gracefully when nextSessionIcon is missing (backward compat)")
    func backwardCompatibility() {
        clearDefaults()

        // Simulate old data without nextSessionIcon
        let json = """
        {"nextSessionType":"Tempo","nextSessionDistanceKm":15.0}
        """
        testDefaults.set(json.data(using: .utf8), forKey: WatchComplicationDataKeys.complicationData)

        let restored = readFromDefaults()
        #expect(restored?.nextSessionType == "Tempo")
        #expect(restored?.nextSessionIcon == nil)
        #expect(restored?.nextSessionDistanceKm == 15.0)

        clearDefaults()
    }
}
