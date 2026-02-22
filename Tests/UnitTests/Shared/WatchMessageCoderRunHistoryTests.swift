import Foundation
import Testing
@testable import UltraTrain

@Suite("WatchMessageCoder Run History Tests")
struct WatchMessageCoderRunHistoryTests {

    // MARK: - Helpers

    private func makeSampleHistory() -> [WatchRunHistoryData] {
        [
            WatchRunHistoryData(
                id: UUID(),
                date: Date(timeIntervalSince1970: 1_700_000_000),
                distanceKm: 25.0,
                elevationGainM: 1200,
                duration: 10800,
                averagePaceSecondsPerKm: 432,
                averageHeartRate: 148
            ),
            WatchRunHistoryData(
                id: UUID(),
                date: Date(timeIntervalSince1970: 1_700_100_000),
                distanceKm: 10.0,
                elevationGainM: 500,
                duration: 3600,
                averagePaceSecondsPerKm: 360,
                averageHeartRate: 155
            )
        ]
    }

    // MARK: - encodeRunHistory / decodeRunHistory

    @Test("encodeRunHistory and decodeRunHistory roundtrip preserves data")
    func encodeDecodeRunHistory_roundTrip() {
        let history = makeSampleHistory()

        let encoded = WatchMessageCoder.encodeRunHistory(history)
        #expect(encoded != nil)

        let decoded = WatchMessageCoder.decodeRunHistory(from: encoded!)
        #expect(decoded != nil)
        #expect(decoded?.count == 2)
        #expect(decoded?[0].distanceKm == 25.0)
        #expect(decoded?[0].elevationGainM == 1200)
        #expect(decoded?[1].distanceKm == 10.0)
        #expect(decoded?[1].averageHeartRate == 155)
    }

    // MARK: - encodeRunHistoryContext / decodeRunHistoryContext

    @Test("encodeRunHistoryContext and decodeRunHistoryContext roundtrip preserves data")
    func encodeDecodeRunHistoryContext_roundTrip() {
        let history = makeSampleHistory()

        let context = WatchMessageCoder.encodeRunHistoryContext(history)
        #expect(!context.isEmpty)

        let decoded = WatchMessageCoder.decodeRunHistoryContext(context)
        #expect(decoded != nil)
        #expect(decoded?.count == 2)
        #expect(decoded?[0].distanceKm == 25.0)
        #expect(decoded?[1].duration == 3600)
    }

    // MARK: - Empty Array

    @Test("encodeRunHistory with empty array produces valid data")
    func encodeRunHistory_emptyArray_producesValidData() {
        let encoded = WatchMessageCoder.encodeRunHistory([])
        #expect(encoded != nil)

        let decoded = WatchMessageCoder.decodeRunHistory(from: encoded!)
        #expect(decoded != nil)
        #expect(decoded?.isEmpty == true)
    }

    @Test("encodeRunHistoryContext with empty array produces non-empty context")
    func encodeRunHistoryContext_emptyArray_producesContext() {
        let context = WatchMessageCoder.encodeRunHistoryContext([])
        #expect(!context.isEmpty)

        let decoded = WatchMessageCoder.decodeRunHistoryContext(context)
        #expect(decoded != nil)
        #expect(decoded?.isEmpty == true)
    }

    // MARK: - Decoding Missing Key

    @Test("decodeRunHistoryContext with missing key returns nil")
    func decodeRunHistoryContext_missingKey_returnsNil() {
        let context: [String: Any] = ["wrong_key": "value"]
        let decoded = WatchMessageCoder.decodeRunHistoryContext(context)
        #expect(decoded == nil)
    }

    @Test("decodeRunHistoryContext with wrong value type returns nil")
    func decodeRunHistoryContext_wrongType_returnsNil() {
        let context: [String: Any] = ["runHistory": "not data"]
        let decoded = WatchMessageCoder.decodeRunHistoryContext(context)
        #expect(decoded == nil)
    }

    @Test("decodeRunHistory with corrupted data returns nil")
    func decodeRunHistory_corruptedData_returnsNil() {
        let corrupted = Data([0xFF, 0xFE, 0xFD])
        let decoded = WatchMessageCoder.decodeRunHistory(from: corrupted)
        #expect(decoded == nil)
    }

    @Test("decodeRunHistoryContext with empty dictionary returns nil")
    func decodeRunHistoryContext_emptyDict_returnsNil() {
        let context: [String: Any] = [:]
        let decoded = WatchMessageCoder.decodeRunHistoryContext(context)
        #expect(decoded == nil)
    }
}
