import CoreLocation
import Foundation
import os

// MARK: - ReplayFrame

struct ReplayFrame: Identifiable, Sendable {
    let id: Int
    let coordinate: CLLocationCoordinate2D
    let altitudeM: Double
    let heartRate: Int?
    let timestamp: Date
    let elapsedSeconds: TimeInterval
    let cumulativeDistanceKm: Double
    let instantPaceSecondsPerKm: Double
}

// MARK: - RunReplayViewModel

@Observable
@MainActor
final class RunReplayViewModel {

    // MARK: - Constants

    private enum Constants {
        static let maxFrameCount = 600
        static let tickIntervalSeconds: Double = 0.1
        static let rollingWindowSize = 5
    }

    // MARK: - State

    let run: CompletedRun
    private(set) var frames: [ReplayFrame] = []
    var currentFrameIndex: Int = 0
    var isPlaying: Bool = false
    var playbackSpeed: Double = 1.0
    private var playbackTask: Task<Void, Never>?

    // MARK: - Init

    init(run: CompletedRun) {
        self.run = run
    }

    // MARK: - Prepare

    func prepare() {
        let points = sampledPoints()
        guard points.count >= 2, let firstTimestamp = points.first?.timestamp else { return }

        var builtFrames: [ReplayFrame] = []
        var cumulativeDistanceM: Double = 0

        for (index, point) in points.enumerated() {
            if index > 0 {
                let prev = points[index - 1]
                cumulativeDistanceM += RunStatisticsCalculator.haversineDistance(
                    lat1: prev.latitude, lon1: prev.longitude,
                    lat2: point.latitude, lon2: point.longitude
                )
            }

            let elapsed = point.timestamp.timeIntervalSince(firstTimestamp)
            let pace = computeInstantPace(
                at: index,
                points: points,
                cumulativeDistanceM: cumulativeDistanceM
            )

            builtFrames.append(ReplayFrame(
                id: index,
                coordinate: CLLocationCoordinate2D(
                    latitude: point.latitude,
                    longitude: point.longitude
                ),
                altitudeM: point.altitudeM,
                heartRate: point.heartRate,
                timestamp: point.timestamp,
                elapsedSeconds: elapsed,
                cumulativeDistanceKm: cumulativeDistanceM / 1000,
                instantPaceSecondsPerKm: pace
            ))
        }

        frames = builtFrames
        currentFrameIndex = 0
    }

    // MARK: - Playback Controls

    func play() {
        guard !frames.isEmpty else { return }
        isPlaying = true
        playbackTask?.cancel()

        playbackTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled, self.isPlaying {
                let sleepNanoseconds = UInt64(
                    Constants.tickIntervalSeconds / self.playbackSpeed * 1_000_000_000
                )
                try? await Task.sleep(nanoseconds: sleepNanoseconds)

                guard !Task.isCancelled, self.isPlaying else { break }

                if self.currentFrameIndex < self.frames.count - 1 {
                    self.currentFrameIndex += 1
                } else {
                    self.isPlaying = false
                }
            }
        }
    }

    func pause() {
        playbackTask?.cancel()
        playbackTask = nil
        isPlaying = false
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func setSpeed(_ speed: Double) {
        playbackSpeed = speed
        if isPlaying {
            playbackTask?.cancel()
            play()
        }
    }

    func seekTo(progress: Double) {
        guard !frames.isEmpty else { return }
        let clamped = min(max(progress, 0), 1)
        currentFrameIndex = Int(clamped * Double(frames.count - 1))
    }

    // MARK: - Computed Properties

    var progress: Double {
        guard frames.count > 1 else { return 0 }
        return Double(currentFrameIndex) / Double(frames.count - 1)
    }

    var currentFrame: ReplayFrame? {
        guard frames.indices.contains(currentFrameIndex) else { return nil }
        return frames[currentFrameIndex]
    }

    var routeUpToCurrent: [CLLocationCoordinate2D] {
        guard !frames.isEmpty, currentFrameIndex >= 0 else { return [] }
        let endIndex = min(currentFrameIndex, frames.count - 1)
        return frames[0...endIndex].map(\.coordinate)
    }

    var remainingRoute: [CLLocationCoordinate2D] {
        guard currentFrameIndex < frames.count - 1 else { return [] }
        return frames[currentFrameIndex...].map(\.coordinate)
    }

    var currentCoordinate: CLLocationCoordinate2D? {
        currentFrame?.coordinate
    }

    var currentPaceFormatted: String {
        guard let frame = currentFrame else { return "--:--" }
        return RunStatisticsCalculator.formatPace(frame.instantPaceSecondsPerKm)
    }

    var currentHRFormatted: String {
        guard let frame = currentFrame, let hr = frame.heartRate else { return "--" }
        return "\(hr)"
    }

    var currentElevationFormatted: String {
        guard let frame = currentFrame else { return "--" }
        return String(format: "%.0f m", frame.altitudeM)
    }

    var currentDistanceFormatted: String {
        guard let frame = currentFrame else { return "--" }
        return String(format: "%.2f", frame.cumulativeDistanceKm)
    }

    var elapsedTimeFormatted: String {
        guard let frame = currentFrame else { return "00:00" }
        return RunStatisticsCalculator.formatDuration(frame.elapsedSeconds)
    }

    var totalTimeFormatted: String {
        guard let lastFrame = frames.last else { return "00:00" }
        return RunStatisticsCalculator.formatDuration(lastFrame.elapsedSeconds)
    }

    // MARK: - Private Helpers

    private func sampledPoints() -> [TrackPoint] {
        let track = run.gpsTrack
        guard track.count > Constants.maxFrameCount else { return track }

        let step = Double(track.count) / Double(Constants.maxFrameCount)
        var sampled: [TrackPoint] = []
        var index: Double = 0

        while Int(index) < track.count {
            sampled.append(track[Int(index)])
            index += step
        }

        // Always include the last point
        if let last = track.last, sampled.last?.timestamp != last.timestamp {
            sampled.append(last)
        }

        return sampled
    }

    private func computeInstantPace(
        at index: Int,
        points: [TrackPoint],
        cumulativeDistanceM: Double
    ) -> Double {
        guard index > 0 else { return 0 }

        let windowStart = max(0, index - Constants.rollingWindowSize)
        let startPoint = points[windowStart]
        let endPoint = points[index]

        var segmentDistanceM: Double = 0
        for i in (windowStart + 1)...index {
            segmentDistanceM += RunStatisticsCalculator.haversineDistance(
                lat1: points[i - 1].latitude, lon1: points[i - 1].longitude,
                lat2: points[i].latitude, lon2: points[i].longitude
            )
        }

        let timeDelta = endPoint.timestamp.timeIntervalSince(startPoint.timestamp)

        guard segmentDistanceM > 0, timeDelta > 0 else { return 0 }

        let distanceKm = segmentDistanceM / 1000
        return timeDelta / distanceKm
    }
}
