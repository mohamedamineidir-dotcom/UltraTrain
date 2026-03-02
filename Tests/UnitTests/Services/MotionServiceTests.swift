import Foundation
import Testing
@testable import UltraTrain

@Suite("MotionService Tests")
struct MotionServiceTests {

    // NOTE: MotionService depends on CMMotionManager which requires device hardware.
    // We test the MotionReading model, the MockMotionService, and protocol conformance.

    // MARK: - MotionReading

    @Test("MotionReading totalAcceleration computes magnitude correctly")
    func totalAccelerationMagnitude() {
        let reading = MotionReading(
            timestamp: Date.now,
            accelerationX: 3.0,
            accelerationY: 4.0,
            accelerationZ: 0.0
        )
        // sqrt(9 + 16 + 0) = 5.0
        #expect(abs(reading.totalAcceleration - 5.0) < 0.001)
    }

    @Test("MotionReading totalAcceleration for gravity-only scenario")
    func totalAccelerationGravityOnly() {
        let reading = MotionReading(
            timestamp: Date.now,
            accelerationX: 0,
            accelerationY: 0,
            accelerationZ: -1.0
        )
        #expect(abs(reading.totalAcceleration - 1.0) < 0.001)
    }

    @Test("MotionReading totalAcceleration for zero acceleration")
    func totalAccelerationZero() {
        let reading = MotionReading(
            timestamp: Date.now,
            accelerationX: 0,
            accelerationY: 0,
            accelerationZ: 0
        )
        #expect(reading.totalAcceleration == 0)
    }

    @Test("MotionReading totalAcceleration for 3D vector")
    func totalAcceleration3D() {
        let reading = MotionReading(
            timestamp: Date.now,
            accelerationX: 1.0,
            accelerationY: 1.0,
            accelerationZ: 1.0
        )
        // sqrt(1 + 1 + 1) = sqrt(3) ~ 1.732
        #expect(abs(reading.totalAcceleration - 1.732) < 0.01)
    }

    // MARK: - MockMotionService

    @Test("MockMotionService starts with isAvailable true")
    func mockStartsAvailable() {
        let mock = MockMotionService()
        #expect(mock.isAvailable)
    }

    @Test("MockMotionService tracks stopAccelerometerUpdates call")
    func mockTracksStopCall() {
        let mock = MockMotionService()
        #expect(!mock.stopAccelerometerUpdatesCalled)

        mock.stopAccelerometerUpdates()
        #expect(mock.stopAccelerometerUpdatesCalled)
    }

    @Test("MockMotionService stream receives yielded readings")
    func mockStreamReceivesReadings() async {
        let mock = MockMotionService()
        let stream = mock.startAccelerometerUpdates()

        let reading = MotionReading(
            timestamp: Date.now,
            accelerationX: 0.5,
            accelerationY: -0.3,
            accelerationZ: 0.98
        )
        mock.sendReading(reading)
        mock.finishStream()

        var received: [MotionReading] = []
        for await r in stream {
            received.append(r)
        }

        #expect(received.count == 1)
        #expect(received.first?.accelerationX == 0.5)
    }

    // MARK: - Protocol Conformance

    @Test("MotionServiceProtocol requires isAvailable and accelerometer methods")
    func protocolConformance() {
        let service: any MotionServiceProtocol = MockMotionService()
        _ = service.isAvailable
        _ = service.startAccelerometerUpdates()
        service.stopAccelerometerUpdates()
    }
}
