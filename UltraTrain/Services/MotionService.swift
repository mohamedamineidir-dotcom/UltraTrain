import CoreMotion
import Foundation
import os

final class MotionService: MotionServiceProtocol, @unchecked Sendable {

    private let motionManager = CMMotionManager()
    private let updateInterval: TimeInterval = 0.1 // 10 Hz

    var isAvailable: Bool {
        motionManager.isAccelerometerAvailable
    }

    func startAccelerometerUpdates() -> AsyncStream<MotionReading> {
        AsyncStream { continuation in
            motionManager.accelerometerUpdateInterval = updateInterval
            motionManager.startAccelerometerUpdates(to: .main) { data, error in
                if let error {
                    Logger.motion.error("Accelerometer error: \(error.localizedDescription)")
                    return
                }
                guard let data else { return }
                let reading = MotionReading(
                    timestamp: Date.now,
                    accelerationX: data.acceleration.x,
                    accelerationY: data.acceleration.y,
                    accelerationZ: data.acceleration.z
                )
                continuation.yield(reading)
            }
            continuation.onTermination = { [weak self] _ in
                self?.motionManager.stopAccelerometerUpdates()
            }
        }
    }

    func stopAccelerometerUpdates() {
        motionManager.stopAccelerometerUpdates()
    }
}

extension Logger {
    static let motion = Logger(subsystem: "com.ultratrain.app", category: "motion")
}
