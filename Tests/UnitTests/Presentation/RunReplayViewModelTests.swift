import Foundation
import Testing
@testable import UltraTrain

@Suite("RunReplayViewModel Tests")
struct RunReplayViewModelTests {

    // MARK: - Helpers

    private func makeTrackPoints(count: Int = 10) -> [TrackPoint] {
        let baseDate = Date.now.addingTimeInterval(-3600)
        var points: [TrackPoint] = []
        for index in 0..<count {
            let lat = 48.8566 + Double(index) * 0.001
            let lon = 2.3522 + Double(index) * 0.001
            let alt = 100.0 + Double(index) * 5.0
            let ts = baseDate.addingTimeInterval(Double(index) * 60)
            let hr = 140 + index
            points.append(TrackPoint(latitude: lat, longitude: lon, altitudeM: alt, timestamp: ts, heartRate: hr))
        }
        return points
    }

    private func makeRun(trackPoints: [TrackPoint]? = nil) -> CompletedRun {
        let track = trackPoints ?? makeTrackPoints()
        return CompletedRun(
            id: UUID(),
            athleteId: UUID(),
            date: Date.now,
            distanceKm: 10.0,
            elevationGainM: 500,
            elevationLossM: 480,
            duration: 3600,
            averageHeartRate: 150,
            maxHeartRate: 175,
            averagePaceSecondsPerKm: 360,
            gpsTrack: track,
            splits: [],
            linkedSessionId: nil,
            linkedRaceId: nil,
            notes: nil,
            pausedDuration: 0
        )
    }

    @MainActor
    private func makeSUT(trackPointCount: Int = 10) -> RunReplayViewModel {
        let run = makeRun(trackPoints: makeTrackPoints(count: trackPointCount))
        return RunReplayViewModel(run: run)
    }

    // MARK: - Tests

    @Test("Prepare builds frames from GPS track")
    @MainActor
    func prepareBuildFrames() {
        let vm = makeSUT(trackPointCount: 10)

        vm.prepare()

        #expect(vm.frames.count == 10)
        #expect(vm.currentFrameIndex == 0)
    }

    @Test("Prepare does nothing with fewer than 2 track points")
    @MainActor
    func prepareNoFramesWithSinglePoint() {
        let vm = makeSUT(trackPointCount: 1)

        vm.prepare()

        #expect(vm.frames.isEmpty)
    }

    @Test("Frames have cumulative distance and elapsed time")
    @MainActor
    func framesHaveCumulativeData() {
        let vm = makeSUT(trackPointCount: 5)

        vm.prepare()

        let firstFrame = vm.frames.first
        let lastFrame = vm.frames.last
        #expect(firstFrame?.elapsedSeconds == 0)
        #expect(firstFrame?.cumulativeDistanceKm == 0)
        #expect(lastFrame != nil)
        #expect(lastFrame!.elapsedSeconds > 0)
        #expect(lastFrame!.cumulativeDistanceKm > 0)
    }

    @Test("Progress is zero at start and 1.0 at end")
    @MainActor
    func progressRange() {
        let vm = makeSUT(trackPointCount: 10)
        vm.prepare()

        vm.currentFrameIndex = 0
        #expect(vm.progress == 0)

        vm.currentFrameIndex = vm.frames.count - 1
        #expect(vm.progress == 1.0)
    }

    @Test("seekTo clamps progress between 0 and 1")
    @MainActor
    func seekToClampsProgress() {
        let vm = makeSUT(trackPointCount: 20)
        vm.prepare()

        vm.seekTo(progress: -0.5)
        #expect(vm.currentFrameIndex == 0)

        vm.seekTo(progress: 1.5)
        #expect(vm.currentFrameIndex == vm.frames.count - 1)

        vm.seekTo(progress: 0.5)
        let expectedIndex = Int(0.5 * Double(vm.frames.count - 1))
        #expect(vm.currentFrameIndex == expectedIndex)
    }

    @Test("currentFrame returns correct frame at current index")
    @MainActor
    func currentFrameAtIndex() {
        let vm = makeSUT(trackPointCount: 10)
        vm.prepare()

        vm.currentFrameIndex = 3
        #expect(vm.currentFrame?.id == 3)
    }

    @Test("currentFrame returns nil when frames are empty")
    @MainActor
    func currentFrameNilWhenEmpty() {
        let vm = makeSUT(trackPointCount: 1)
        vm.prepare()

        #expect(vm.currentFrame == nil)
    }

    @Test("routeUpToCurrent returns coordinates up to current index")
    @MainActor
    func routeUpToCurrentSlice() {
        let vm = makeSUT(trackPointCount: 10)
        vm.prepare()

        vm.currentFrameIndex = 4
        let route = vm.routeUpToCurrent
        #expect(route.count == 5) // indices 0..4 inclusive
    }

    @Test("remainingRoute returns coordinates from current index onward")
    @MainActor
    func remainingRouteSlice() {
        let vm = makeSUT(trackPointCount: 10)
        vm.prepare()

        vm.currentFrameIndex = 7
        let remaining = vm.remainingRoute
        #expect(remaining.count == 3) // indices 7, 8, 9
    }

    @Test("pause stops playback")
    @MainActor
    func pauseStopsPlayback() {
        let vm = makeSUT(trackPointCount: 10)
        vm.prepare()
        vm.isPlaying = true

        vm.pause()

        #expect(vm.isPlaying == false)
    }

    @Test("togglePlayPause switches between play and pause")
    @MainActor
    func togglePlayPauseSwitches() {
        let vm = makeSUT(trackPointCount: 10)
        vm.prepare()

        vm.togglePlayPause()
        #expect(vm.isPlaying == true)

        vm.togglePlayPause()
        #expect(vm.isPlaying == false)
    }

    @Test("setSpeed updates playback speed")
    @MainActor
    func setSpeedUpdatesSpeed() {
        let vm = makeSUT(trackPointCount: 10)
        vm.prepare()

        vm.setSpeed(2.0)
        #expect(vm.playbackSpeed == 2.0)

        vm.setSpeed(0.5)
        #expect(vm.playbackSpeed == 0.5)
    }

    @Test("formatted properties return placeholder when no frames")
    @MainActor
    func formattedPlaceholders() {
        let vm = makeSUT(trackPointCount: 1)
        vm.prepare()

        #expect(vm.currentPaceFormatted == "--:--")
        #expect(vm.currentHRFormatted == "--")
        #expect(vm.currentElevationFormatted == "--")
        #expect(vm.currentDistanceFormatted == "--")
    }

    @Test("totalTimeFormatted reflects last frame duration")
    @MainActor
    func totalTimeFormatted() {
        let vm = makeSUT(trackPointCount: 10)
        vm.prepare()

        // 10 points, 60 seconds apart = 9 * 60 = 540 seconds
        #expect(vm.totalTimeFormatted != "00:00")
    }
}
