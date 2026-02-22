import Foundation
import Testing
@testable import UltraTrain

@Suite("WatchRunHistoryData Tests")
struct WatchRunHistoryDataTests {

    // MARK: - Helpers

    private func makeSampleData() -> WatchRunHistoryData {
        WatchRunHistoryData(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            distanceKm: 42.195,
            elevationGainM: 2500,
            duration: 18000,
            averagePaceSecondsPerKm: 426.5,
            averageHeartRate: 155
        )
    }

    // MARK: - Encoding / Decoding

    @Test("Encoding and decoding roundtrip preserves all properties")
    func encodeDecode_roundTrip_preservesProperties() throws {
        let original = makeSampleData()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(WatchRunHistoryData.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.date == original.date)
        #expect(decoded.distanceKm == original.distanceKm)
        #expect(decoded.elevationGainM == original.elevationGainM)
        #expect(decoded.duration == original.duration)
        #expect(decoded.averagePaceSecondsPerKm == original.averagePaceSecondsPerKm)
        #expect(decoded.averageHeartRate == original.averageHeartRate)
    }

    @Test("Encoding and decoding with nil heart rate roundtrips correctly")
    func encodeDecode_nilHeartRate_roundTrips() throws {
        var data = makeSampleData()
        data.averageHeartRate = nil

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(data)
        let decoded = try decoder.decode(WatchRunHistoryData.self, from: encoded)

        #expect(decoded.averageHeartRate == nil)
        #expect(decoded.distanceKm == data.distanceKm)
    }

    @Test("All properties are preserved through encode/decode cycle")
    func allProperties_preservedThroughCycle() throws {
        let id = UUID()
        let date = Date.now
        let original = WatchRunHistoryData(
            id: id,
            date: date,
            distanceKm: 10.5,
            elevationGainM: 800,
            duration: 4500,
            averagePaceSecondsPerKm: 428.6,
            averageHeartRate: 142
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(original)
        let decoded = try decoder.decode(WatchRunHistoryData.self, from: encoded)

        #expect(decoded.id == id)
        #expect(decoded.distanceKm == 10.5)
        #expect(decoded.elevationGainM == 800)
        #expect(decoded.duration == 4500)
        #expect(decoded.averagePaceSecondsPerKm == 428.6)
        #expect(decoded.averageHeartRate == 142)
    }

    @Test("Default values — new instance has expected types")
    func defaultValues_instanceHasExpectedTypes() {
        let data = WatchRunHistoryData(
            id: UUID(),
            date: Date.now,
            distanceKm: 0,
            elevationGainM: 0,
            duration: 0,
            averagePaceSecondsPerKm: 0,
            averageHeartRate: nil
        )
        #expect(data.distanceKm == 0)
        #expect(data.elevationGainM == 0)
        #expect(data.duration == 0)
        #expect(data.averagePaceSecondsPerKm == 0)
        #expect(data.averageHeartRate == nil)
    }

    @Test("Identifiable conformance uses id property")
    func identifiable_usesIdProperty() {
        let id = UUID()
        let data = WatchRunHistoryData(
            id: id,
            date: Date.now,
            distanceKm: 5,
            elevationGainM: 100,
            duration: 1800,
            averagePaceSecondsPerKm: 360,
            averageHeartRate: 140
        )
        #expect(data.id == id)
    }

    @Test("Encoding produces valid JSON")
    func encoding_producesValidJSON() throws {
        let data = makeSampleData()
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(data)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        #expect(json != nil)
        #expect(json?["distanceKm"] as? Double == 42.195)
    }
}
