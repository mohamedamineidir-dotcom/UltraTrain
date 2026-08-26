import Foundation
import Testing
@testable import UltraTrain

@Suite("InteractiveCourseProfileViewModel Tests")
struct InteractiveCourseProfileViewModelTests {

    // MARK: - Helpers

    /// Creates a route with varying altitudes to produce interesting gradient segments.
    private func makeRoute() -> [TrackPoint] {
        let baseDate = Date(timeIntervalSince1970: 1_000_000)
        let altitudes: [Double] = [
            500, 520, 540, 560, 580, 600,   // uphill
            600, 580, 560, 540, 520, 500,   // downhill
            500, 500, 500, 500, 500, 500    // flat
        ]
        return altitudes.enumerated().map { index, alt in
            TrackPoint(
                latitude: 45.0 + Double(index) * 0.002,
                longitude: 6.0,
                altitudeM: alt,
                timestamp: baseDate.addingTimeInterval(Double(index) * 60),
                heartRate: nil
            )
        }
    }

    private func makeCheckpoints() -> [Checkpoint] {
        [
            Checkpoint(
                id: UUID(),
                name: "CP1",
                distanceFromStartKm: 0.5,
                elevationM: 550,
                hasAidStation: true
            )
        ]
    }

    // MARK: - Init

    @Test("init computes gradientSegments from route")
    @MainActor
    func init_computesGradientSegments() {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(),
            checkpoints: makeCheckpoints()
        )
        #expect(!vm.gradientSegments.isEmpty)
    }

    @Test("init computes elevationProfile from route")
    @MainActor
    func init_computesElevationProfile() {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(),
            checkpoints: makeCheckpoints()
        )
        #expect(!vm.elevationProfile.isEmpty)
        #expect(vm.totalDistanceKm > 0)
    }

    // MARK: - Selection

    @Test("selectPoint sets selectedDistance")
    @MainActor
    func selectPoint_setsSelectedDistance() {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(),
            checkpoints: makeCheckpoints()
        )

        #expect(vm.selectedDistance == nil)
        vm.selectPoint(at: 0.5)
        #expect(vm.selectedDistance != nil)
    }

    @Test("selectPoint sets selectedSegment when within a segment")
    @MainActor
    func selectPoint_setsSelectedSegment() {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(),
            checkpoints: makeCheckpoints()
        )

        guard let firstSegment = vm.gradientSegments.first else {
            Issue.record("No gradient segments generated")
            return
        }

        let midDistance = (firstSegment.distanceKm + firstSegment.endDistanceKm) / 2
        vm.selectPoint(at: midDistance)
        #expect(vm.selectedSegment != nil)
    }

    @Test("clearSelection resets all selection state")
    @MainActor
    func clearSelection_resetsAllState() {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(),
            checkpoints: makeCheckpoints()
        )

        vm.selectPoint(at: 0.5)
        #expect(vm.selectedDistance != nil)

        vm.clearSelection()
        #expect(vm.selectedDistance == nil)
        #expect(vm.selectedSegment == nil)
        #expect(vm.selectedAltitude == nil)
        #expect(vm.selectedCumulativeGain == nil)
    }

    // MARK: - Cumulative D+ while scrubbing

    @Test("selectPoint sets cumulative gain to zero at the very start")
    @MainActor
    func selectPoint_atStart_cumulativeGainIsZero() {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(),
            checkpoints: makeCheckpoints()
        )
        vm.selectPoint(at: 0)
        #expect(vm.selectedCumulativeGain == 0)
    }

    @Test("selectPoint's cumulative gain increases monotonically with distance")
    @MainActor
    func selectPoint_cumulativeGain_increasesMonotonically() throws {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(),
            checkpoints: makeCheckpoints()
        )
        vm.selectPoint(at: vm.totalDistanceKm * 0.25)
        let earlyGain = try #require(vm.selectedCumulativeGain)
        vm.selectPoint(at: vm.totalDistanceKm * 0.9)
        let lateGain = try #require(vm.selectedCumulativeGain)
        #expect(lateGain >= earlyGain)
    }

    @Test("selectPoint's cumulative gain at the end matches the route's total climb, not net elevation change")
    @MainActor
    func selectPoint_cumulativeGain_atEnd_matchesTotalClimb() throws {
        // Route climbs 500->600 (100m gain), descends 600->500 (0 gain),
        // then stays flat — net elevation change is 0, but total D+ is ~100m.
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(),
            checkpoints: makeCheckpoints()
        )
        vm.selectPoint(at: vm.totalDistanceKm)
        let finalGain = try #require(vm.selectedCumulativeGain)
        #expect(finalGain > 50)
        #expect(finalGain < 150)
    }

    // MARK: - Computed Properties

    @Test("minAltitude and maxAltitude computed correctly")
    @MainActor
    func minMaxAltitude_computedCorrectly() {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(),
            checkpoints: makeCheckpoints()
        )

        #expect(vm.minAltitude <= vm.maxAltitude)
        // The route has altitudes 500-600
        #expect(vm.minAltitude <= 500)
        #expect(vm.maxAltitude >= 600)
    }

    // MARK: - Adaptive Axis Domains

    /// A route peaking at roughly `peakAltitudeM`, starting near sea level
    /// and spanning `totalKm` — used to check that the chart domain scales
    /// with the actual course rather than a fixed literal.
    private func makeRoute(peakAltitudeM: Double, totalKm: Double) -> [TrackPoint] {
        let baseDate = Date(timeIntervalSince1970: 1_000_000)
        let pointCount = 20
        // Degrees-per-point tuned so the total haversine distance is
        // roughly `totalKm` (~111km per degree of latitude).
        let degreesPerPoint = totalKm / 111.0 / Double(pointCount)
        return (0..<pointCount).map { index in
            let progress = Double(index) / Double(pointCount - 1)
            // Triangular profile: climbs to the peak at the midpoint, then
            // back down — guarantees maxAltitude ≈ peakAltitudeM.
            let altitude = progress <= 0.5
                ? peakAltitudeM * (progress * 2)
                : peakAltitudeM * (2 - progress * 2)
            return TrackPoint(
                latitude: 45.0 + Double(index) * degreesPerPoint,
                longitude: 6.0,
                altitudeM: altitude,
                timestamp: baseDate.addingTimeInterval(Double(index) * 60),
                heartRate: nil
            )
        }
    }

    @Test("altitudeDomain tops out a modest amount above a low peak, not a fixed literal")
    @MainActor
    func altitudeDomain_lowPeak_scalesDown() {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(peakAltitudeM: 900, totalKm: 50),
            checkpoints: []
        )
        let domain = vm.altitudeDomain
        // Ceiling should sit a modest amount above the real 900m peak —
        // not a generic 4000m-style constant that's wrong for this course.
        #expect(domain.upperBound > 900)
        #expect(domain.upperBound < 1400)
    }

    @Test("altitudeDomain tops out proportionally higher above a high peak")
    @MainActor
    func altitudeDomain_highPeak_scalesUp() {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(peakAltitudeM: 4000, totalKm: 160),
            checkpoints: []
        )
        let domain = vm.altitudeDomain
        // Still "a bit more than 4000m" — well short of a 900m-course's
        // padding scaled up, and nowhere near the 15000m regression seen
        // when the axis was left fully automatic.
        #expect(domain.upperBound > 4000)
        #expect(domain.upperBound < 5000)
    }

    @Test("altitudeDomain ceiling for a high-peak course is well above a low-peak course's")
    @MainActor
    func altitudeDomain_scalesWithCourse_notFixed() {
        let lowVM = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(peakAltitudeM: 900, totalKm: 50),
            checkpoints: []
        )
        let highVM = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(peakAltitudeM: 4000, totalKm: 160),
            checkpoints: []
        )
        #expect(highVM.altitudeDomain.upperBound > lowVM.altitudeDomain.upperBound * 2)
    }

    @Test("distanceDomain ends just past the course's actual total distance")
    @MainActor
    func distanceDomain_endsJustPastTotalDistance() {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(peakAltitudeM: 900, totalKm: 50),
            checkpoints: []
        )
        let domain = vm.distanceDomain
        #expect(domain.lowerBound == 0)
        #expect(domain.upperBound >= vm.totalDistanceKm)
        // Padding should be small — the chart shouldn't run on for miles
        // past the course's actual finish.
        #expect(domain.upperBound - vm.totalDistanceKm < vm.totalDistanceKm * 0.1)
    }

    @Test("distanceDomain scales with a much longer course (e.g. a 100-miler)")
    @MainActor
    func distanceDomain_scalesWithLongCourse() {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(peakAltitudeM: 2000, totalKm: 160),
            checkpoints: []
        )
        let domain = vm.distanceDomain
        #expect(domain.upperBound > 150)
        #expect(domain.upperBound < 170)
    }

    @Test("selectedGradientText formatting includes sign and percent")
    @MainActor
    func selectedGradientText_formatsCorrectly() {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(),
            checkpoints: makeCheckpoints()
        )

        // Before selection, should be nil
        #expect(vm.selectedGradientText == nil)

        // Select a point within the first segment
        if let firstSeg = vm.gradientSegments.first {
            let midDist = (firstSeg.distanceKm + firstSeg.endDistanceKm) / 2
            vm.selectPoint(at: midDist)

            if let text = vm.selectedGradientText {
                #expect(text.contains("%"))
                // Should start with + or - sign or digit
                let firstChar = text.first!
                #expect(firstChar == "+" || firstChar == "-" || firstChar.isNumber)
            }
        }
    }

    // MARK: - Split-time projection

    @Test("Without scenario times, hasScenarioTimes is false and no split is projected")
    @MainActor
    func noScenarioTimes_noSplitProjected() {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(),
            checkpoints: makeCheckpoints()
        )
        #expect(vm.hasScenarioTimes == false)
        vm.selectPoint(at: 0.5)
        #expect(vm.selectedExpectedSplitText == nil)
    }

    @Test("With scenario times, scrubbing to the start projects zero elapsed time")
    @MainActor
    func withScenarioTimes_atStart_projectsZero() {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(),
            checkpoints: makeCheckpoints(),
            scenarioTimes: (optimistic: 3600, expected: 4000, conservative: 4400)
        )
        #expect(vm.hasScenarioTimes == true)
        vm.selectPoint(at: 0)
        #expect(vm.selectedExpectedSplitText == "0h00")
    }

    @Test("With scenario times, scrubbing to the end projects the full finish time")
    @MainActor
    func withScenarioTimes_atEnd_projectsFullTime() {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(),
            checkpoints: makeCheckpoints(),
            scenarioTimes: (optimistic: 3600, expected: 7200, conservative: 9000)
        )
        vm.selectPoint(at: vm.totalDistanceKm)
        #expect(vm.selectedExpectedSplitText == "2h00")
    }

    @Test("Projected split time increases monotonically with distance")
    @MainActor
    func splitTime_increasesMonotonicallyWithDistance() throws {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(),
            checkpoints: makeCheckpoints(),
            scenarioTimes: (optimistic: 3600, expected: 7200, conservative: 9000)
        )
        vm.selectPoint(at: vm.totalDistanceKm * 0.25)
        let earlySplit = try #require(vm.selectedExpectedSplitText)
        vm.selectPoint(at: vm.totalDistanceKm * 0.75)
        let lateSplit = try #require(vm.selectedExpectedSplitText)
        #expect(earlySplit != lateSplit)
    }

    @Test("Optimistic split is always faster than or equal to conservative at the same point")
    @MainActor
    func optimisticSplit_fasterThanConservative() {
        let vm = InteractiveCourseProfileViewModel(
            courseRoute: makeRoute(),
            checkpoints: makeCheckpoints(),
            scenarioTimes: (optimistic: 3600, expected: 7200, conservative: 9000)
        )
        vm.selectPoint(at: vm.totalDistanceKm * 0.5)
        guard let split = vm.selectedSplitTimes else {
            Issue.record("Expected split times to be projected")
            return
        }
        #expect(split.optimistic <= split.conservative)
    }
}
