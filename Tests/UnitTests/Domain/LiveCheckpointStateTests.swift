import Foundation
import Testing
@testable import UltraTrain

@Suite("LiveCheckpointState Tests")
struct LiveCheckpointStateTests {

    @Test("Delta is nil when not crossed")
    func deltaNotCrossed() {
        let state = LiveCheckpointState(
            id: UUID(),
            checkpointName: "CP1",
            distanceFromStartKm: 10,
            hasAidStation: true,
            predictedTime: 3600,
            actualTime: nil
        )
        #expect(state.delta == nil)
        #expect(!state.isCrossed)
    }

    @Test("Delta is negative when ahead of prediction")
    func deltaAhead() {
        let state = LiveCheckpointState(
            id: UUID(),
            checkpointName: "CP1",
            distanceFromStartKm: 10,
            hasAidStation: true,
            predictedTime: 3600,
            actualTime: 3300
        )
        #expect(state.delta == -300)
        #expect(state.isCrossed)
    }

    @Test("Delta is positive when behind prediction")
    func deltaBehind() {
        let state = LiveCheckpointState(
            id: UUID(),
            checkpointName: "CP1",
            distanceFromStartKm: 10,
            hasAidStation: false,
            predictedTime: 3600,
            actualTime: 4000
        )
        #expect(state.delta == 400)
        #expect(state.isCrossed)
    }

    @Test("Delta is zero when exactly on prediction")
    func deltaExact() {
        let state = LiveCheckpointState(
            id: UUID(),
            checkpointName: "CP1",
            distanceFromStartKm: 10,
            hasAidStation: true,
            predictedTime: 3600,
            actualTime: 3600
        )
        #expect(state.delta == 0)
        #expect(state.isCrossed)
    }

    @Test("Equatable conformance")
    func equatable() {
        let id = UUID()
        let state1 = LiveCheckpointState(
            id: id, checkpointName: "CP1",
            distanceFromStartKm: 10, hasAidStation: true,
            predictedTime: 3600, actualTime: nil
        )
        let state2 = LiveCheckpointState(
            id: id, checkpointName: "CP1",
            distanceFromStartKm: 10, hasAidStation: true,
            predictedTime: 3600, actualTime: nil
        )
        #expect(state1 == state2)
    }
}
