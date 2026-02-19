import Foundation

enum SessionMatcher {

    struct MatchResult: Sendable {
        let session: TrainingSession
        let confidence: Double
    }

    // MARK: - Public

    static func findMatch(
        runDate: Date,
        distanceKm: Double,
        duration: TimeInterval,
        candidates: [TrainingSession]
    ) -> MatchResult? {
        let eligible = candidates.filter { session in
            !session.isCompleted
                && !session.isSkipped
                && session.linkedRunId == nil
                && session.type != .rest
        }

        guard !eligible.isEmpty else { return nil }

        let calendar = Calendar.current

        // Same-day candidates
        let sameDay = eligible.filter { calendar.isDate($0.date, inSameDayAs: runDate) }

        if let result = bestMatch(from: sameDay, distanceKm: distanceKm, duration: duration, maxConfidence: 0.95) {
            return result
        }

        // ±1 day fallback
        let nearDay = eligible.filter { session in
            let dayDiff = abs(calendar.dateComponents([.day], from: session.date, to: runDate).day ?? 99)
            return dayDiff == 1
        }

        return bestMatch(from: nearDay, distanceKm: distanceKm, duration: duration, maxConfidence: 0.7)
    }

    // MARK: - Private

    private static func bestMatch(
        from sessions: [TrainingSession],
        distanceKm: Double,
        duration: TimeInterval,
        maxConfidence: Double
    ) -> MatchResult? {
        guard !sessions.isEmpty else { return nil }

        if sessions.count == 1, let only = sessions.first {
            return MatchResult(session: only, confidence: maxConfidence)
        }

        var bestResult: MatchResult?

        for session in sessions {
            let distanceScore = 1.0 - min(
                abs(session.plannedDistanceKm - distanceKm) / max(session.plannedDistanceKm, 1),
                1.0
            )
            let durationScore = 1.0 - min(
                abs(session.plannedDuration - duration) / max(session.plannedDuration, 1),
                1.0
            )
            let confidence = (distanceScore * 0.6 + durationScore * 0.4) * maxConfidence

            guard confidence >= 0.5 else { continue }

            if confidence > (bestResult?.confidence ?? 0) {
                bestResult = MatchResult(session: session, confidence: confidence)
            }
        }

        return bestResult
    }
}
