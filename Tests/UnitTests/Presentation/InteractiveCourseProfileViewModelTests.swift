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
}
