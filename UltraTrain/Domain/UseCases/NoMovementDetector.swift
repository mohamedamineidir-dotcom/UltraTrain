import Foundation

enum NoMovementDetector {

    static func shouldAlert(
        lastMovementTime: Date,
        currentTime: Date,
        thresholdMinutes: Int,
        isRunPaused: Bool
    ) -> Bool {
        guard !isRunPaused else { return false }
        let elapsed = currentTime.timeIntervalSince(lastMovementTime)
        let threshold = TimeInterval(thresholdMinutes * 60)
        return elapsed >= threshold
    }
}
