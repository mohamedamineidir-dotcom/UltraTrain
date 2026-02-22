import Foundation
import os

@Observable
@MainActor
final class CourseGuidanceHandler {

    // MARK: - Dependencies

    let courseRoute: [TrackPoint]
    private let checkpoints: [Checkpoint]
    private let checkpointSplits: [CheckpointSplit]?
    private let totalDistanceKm: Double

    // MARK: - State

    var currentProgress: CourseProgress?
    var isOffCourse = false
    var nextCheckpointName: String?
    var nextCheckpointDistanceKm: Double?
    var nextCheckpointETA: TimeInterval?
    var arrivedCheckpoint: Checkpoint?
    var arrivedCheckpointTimeDelta: TimeInterval?

    // MARK: - Private

    private var arrivedCheckpointIds: Set<UUID> = []
    private var dismissTask: Task<Void, Never>?
    private var previousDistanceKm: Double = 0

    // MARK: - Init

    init(
        courseRoute: [TrackPoint],
        checkpoints: [Checkpoint],
        checkpointSplits: [CheckpointSplit]?,
        totalDistanceKm: Double
    ) {
        self.courseRoute = courseRoute
        self.checkpoints = checkpoints
        self.checkpointSplits = checkpointSplits
        self.totalDistanceKm = totalDistanceKm
    }

    // MARK: - Tick

    func tick(
        latitude: Double,
        longitude: Double,
        elapsedTime: TimeInterval,
        currentPaceSecondsPerKm: Double
    ) {
        let progress = CourseProgressTracker.trackProgress(
            latitude: latitude,
            longitude: longitude,
            courseRoute: courseRoute,
            checkpoints: checkpoints,
            previousDistanceKm: previousDistanceKm
        )

        currentProgress = progress
        isOffCourse = progress.isOffCourse
        previousDistanceKm = progress.distanceAlongCourseKm

        updateNextCheckpoint(progress: progress, currentPace: currentPaceSecondsPerKm)
        checkForCheckpointArrival(progress: progress, elapsedTime: elapsedTime)
    }

    // MARK: - Private — Next Checkpoint

    private func updateNextCheckpoint(
        progress: CourseProgress,
        currentPace: Double
    ) {
        if let cp = progress.nextCheckpoint {
            nextCheckpointName = cp.name
            nextCheckpointDistanceKm = progress.distanceToNextCheckpointKm
            nextCheckpointETA = calculateETA(
                distanceKm: progress.distanceToNextCheckpointKm,
                currentPace: currentPace,
                checkpoint: cp
            )
        } else {
            nextCheckpointName = nil
            nextCheckpointDistanceKm = nil
            nextCheckpointETA = nil
        }
    }

    private func calculateETA(
        distanceKm: Double?,
        currentPace: Double,
        checkpoint: Checkpoint
    ) -> TimeInterval? {
        if let splits = checkpointSplits,
           let split = splits.first(where: { $0.checkpointId == checkpoint.id }) {
            return split.expectedTime
        }

        guard let dist = distanceKm, currentPace > 0, currentPace.isFinite else {
            return nil
        }
        return dist * currentPace
    }

    // MARK: - Private — Checkpoint Arrival

    private func checkForCheckpointArrival(
        progress: CourseProgress,
        elapsedTime: TimeInterval
    ) {
        let arrivalThresholdKm = 0.15

        let sortedCheckpoints = checkpoints
            .sorted { $0.distanceFromStartKm < $1.distanceFromStartKm }

        for checkpoint in sortedCheckpoints {
            guard !arrivedCheckpointIds.contains(checkpoint.id) else { continue }

            let distDiff = abs(
                progress.distanceAlongCourseKm - checkpoint.distanceFromStartKm
            )
            if distDiff <= arrivalThresholdKm {
                arrivedCheckpointIds.insert(checkpoint.id)
                arrivedCheckpoint = checkpoint
                arrivedCheckpointTimeDelta = computeTimeDelta(
                    checkpoint: checkpoint, elapsedTime: elapsedTime
                )

                dismissTask?.cancel()
                dismissTask = Task { [weak self] in
                    try? await Task.sleep(for: .seconds(5))
                    guard !Task.isCancelled else { return }
                    self?.arrivedCheckpoint = nil
                    self?.arrivedCheckpointTimeDelta = nil
                }

                Logger.tracking.info(
                    "Arrived at checkpoint: \(checkpoint.name)"
                )
                break
            }
        }
    }

    private func computeTimeDelta(
        checkpoint: Checkpoint,
        elapsedTime: TimeInterval
    ) -> TimeInterval? {
        guard let splits = checkpointSplits,
              let split = splits.first(where: {
                  $0.checkpointId == checkpoint.id
              })
        else { return nil }

        return elapsedTime - split.expectedTime
    }
}
