import Foundation

enum FallDetectionAlgorithm {

    struct FallResult: Sendable {
        let isFallDetected: Bool
        let impactG: Double
        let stillnessAfterImpact: Bool
    }

    // Was a separately-hardcoded 3.0 duplicating AppConfiguration.Safety's
    // constant of the same value — delegate to it so the two can't drift.
    static var impactThresholdG: Double { AppConfiguration.Safety.fallImpactThresholdG }
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

        // Require the buffer to actually SPAN the full stillness window
        // before concluding stillness — not just "whatever samples happen
        // to be available so far are calm." Ordinary rhythmic running is
        // impact → a brief, genuinely quiet flight/swing phase → the next
        // impact; without this check, a footstrike-sized impact followed
        // by only a couple of calm samples (because that's all that has
        // accumulated *so far*, e.g. early in a run before the buffer has
        // filled) satisfies "stillness" trivially, even though the runner
        // never stopped moving.
        guard let lastWithinWindow = withinWindow.last,
              lastWithinWindow.timestamp.timeIntervalSince(impactTime) >= stillnessDurationSeconds else {
            return FallResult(isFallDetected: false, impactG: maxImpact, stillnessAfterImpact: false)
        }

        let allStill = withinWindow.allSatisfy { reading in
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
