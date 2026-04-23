import Foundation

/// Persistence for per-rep feedback captured after road intervals / tempo
/// sessions. Consumed by the IR-2 refinement use case (adjusts future target
/// paces) and by coach-advice surfacing (shows the athlete when and why a
/// target was refined).
protocol IntervalPerformanceRepository: Sendable {
    /// Saves a feedback entry. Replaces any existing entry for the same
    /// sessionId — an athlete re-logging the same session overwrites.
    func save(_ feedback: IntervalPerformanceFeedback) async throws

    /// All feedback entries, newest first.
    func getAll() async throws -> [IntervalPerformanceFeedback]

    /// Returns an existing feedback for a given session, if one exists.
    /// Used by the sheet to pre-populate when re-opening.
    func get(for sessionId: UUID) async throws -> IntervalPerformanceFeedback?

    /// Feedback entries newer than `cutoff` for the given session type.
    /// IR-2 uses this to load the sliding window it reasons over (typically
    /// the last 21 days) without dragging the full history into memory.
    func getRecent(
        since cutoff: Date,
        sessionType: SessionType
    ) async throws -> [IntervalPerformanceFeedback]
}
