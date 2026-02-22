import Foundation

struct MotionReading: Sendable {
    let timestamp: Date
    let accelerationX: Double
    let accelerationY: Double
    let accelerationZ: Double
    
    var totalAcceleration: Double {
        (accelerationX * accelerationX + accelerationY * accelerationY + accelerationZ * accelerationZ).squareRoot()
    }
}

protocol MotionServiceProtocol: Sendable {
    var isAvailable: Bool { get }
    func startAccelerometerUpdates() -> AsyncStream<MotionReading>
    func stopAccelerometerUpdates()
}
