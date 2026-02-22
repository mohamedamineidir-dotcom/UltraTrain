import Foundation
@testable import UltraTrain

final class MockMotionService: MotionServiceProtocol, @unchecked Sendable {
    nonisolated(unsafe) var isAvailable: Bool = true
    nonisolated(unsafe) var stopAccelerometerUpdatesCalled = false

    private nonisolated(unsafe) var continuation: AsyncStream<MotionReading>.Continuation?

    func startAccelerometerUpdates() -> AsyncStream<MotionReading> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    func stopAccelerometerUpdates() {
        stopAccelerometerUpdatesCalled = true
        continuation?.finish()
        continuation = nil
    }

    /// Send a reading into the stream for testing purposes.
    func sendReading(_ reading: MotionReading) {
        continuation?.yield(reading)
    }

    /// Finish the stream.
    func finishStream() {
        continuation?.finish()
        continuation = nil
    }
}
