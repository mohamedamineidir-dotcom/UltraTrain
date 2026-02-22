import Foundation

enum FallDetectionAlgorithm {

    struct FallResult: Sendable {
        let isFallDetected: Bool
        let impactG: Double
        let stillnessAfterImpact: Bool
    }

    static let impactThresholdG: Double = 3.0
    static let stillnessThresholdG: Double = 0.3
    static let stillnessDurationSeconds: TimeInterval = 5.0

    static func analyze(readings: [MotionReading]) -> FallResult {
        guard readings.count >= 10 else {
            return FallResult(isFallDetected: false, impactG: 0, stillnessAfterImpact: false)
        }

        var maxImpact: Double = 0
        var impactIndex: Int?

        for (index, reading) in readings.enumerated() {
            let g = reading.totalAcceleration
            if g > maxImpact {
                maxImpact = g
                impactIndex = index
            }
        }

        guard maxImpact >= impactThresholdG, let impactIdx = impactIndex else {
            return FallResult(isFallDetected: false, impactG: maxImpact, stillnessAfterImpact: false)
        }

        let afterImpact = readings.suffix(from: min(impactIdx + 1, readings.count - 1))
        guard !afterImpact.isEmpty else {
            return FallResult(isFallDetected: false, impactG: maxImpact, stillnessAfterImpact: false)
        }

        guard let impactTime = readings[safe: impactIdx]?.timestamp else {
            return FallResult(isFallDetected: false, impactG: maxImpact, stillnessAfterImpact: false)
        }

        let withinWindow = afterImpact.filter {
            $0.timestamp.timeIntervalSince(impactTime) <= stillnessDurationSeconds
        }

        let allStill = !withinWindow.isEmpty && withinWindow.allSatisfy { reading in
            abs(reading.totalAcceleration - 1.0) < stillnessThresholdG
        }

        return FallResult(
            isFallDetected: maxImpact >= impactThresholdG && allStill,
            impactG: maxImpact,
            stillnessAfterImpact: allStill
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
