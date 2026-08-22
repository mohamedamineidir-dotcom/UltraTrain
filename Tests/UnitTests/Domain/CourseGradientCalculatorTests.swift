import Foundation
import Testing
@testable import UltraTrain

@Suite("CourseGradientCalculator Tests")
struct CourseGradientCalculatorTests {

    // MARK: - Helpers

    /// Creates a line of TrackPoints along a constant latitude with specified altitudes.
    /// Each point is spaced far enough apart (~111m per 0.001 deg latitude) to exceed
    /// the 100m sample interval used internally by the calculator.
    private func makeRoute(
        altitudes: [Double],
        latitudeSpacing: Double = 0.002
    ) -> [TrackPoint] {
        let baseDate = Date(timeIntervalSince1970: 1_000_000)
        return altitudes.enumerated().map { index, alt in
            TrackPoint(
                latitude: 45.0 + Double(index) * latitudeSpacing,
                longitude: 6.0,
                altitudeM: alt,
                timestamp: baseDate.addingTimeInterval(Double(index) * 60),
                heartRate: nil
            )
        }
    }

    // MARK: - buildGradientProfile

    @Test("buildGradientProfile with empty array returns empty")
    func buildGradientProfile_emptyArray_returnsEmpty() {
        let result = CourseGradientCalculator.buildGradientProfile(from: [])
        #expect(result.isEmpty)
    }

    @Test("buildGradientProfile with single point returns empty")
    func buildGradientProfile_singlePoint_returnsEmpty() {
        let route = makeRoute(altitudes: [500])
        let result = CourseGradientCalculator.buildGradientProfile(from: route)
        #expect(result.isEmpty)
    }

    @Test("buildGradientProfile with flat route produces flat category segments")
    func buildGradientProfile_flatRoute_producesFlatCategory() {
        let route = makeRoute(altitudes: [500, 500, 500, 500, 500])
        let segments = CourseGradientCalculator.buildGradientProfile(from: route)

        for segment in segments {
            #expect(segment.category == .flat)
            #expect(abs(segment.gradientPercent) < 5)
        }
    }

    @Test("buildGradientProfile with uphill route produces positive gradient")
    func buildGradientProfile_uphillRoute_producesPositiveGradient() {
        // Each step rises 50m over ~222m horizontal = ~22.5% gradient
        let route = makeRoute(altitudes: [500, 550, 600, 650, 700])
        let segments = CourseGradientCalculator.buildGradientProfile(from: route)

        #expect(!segments.isEmpty)
        for segment in segments {
            #expect(segment.gradientPercent > 0)
            #expect(segment.endAltitudeM >= segment.altitudeM)
        }
    }

    @Test("buildGradientProfile with downhill route produces negative gradient")
    func buildGradientProfile_downhillRoute_producesNegativeGradient() {
        let route = makeRoute(altitudes: [700, 650, 600, 550, 500])
        let segments = CourseGradientCalculator.buildGradientProfile(from: route)

        #expect(!segments.isEmpty)
        for segment in segments {
            #expect(segment.gradientPercent < 0)
            #expect(segment.endAltitudeM <= segment.altitudeM)
        }
    }

    // MARK: - interpolatedAltitude

    @Test("interpolatedAltitude at start returns first altitude")
    func interpolatedAltitude_atStart_returnsFirstAltitude() {
        let segments = [
            GradientSegment(
                distanceKm: 0,
                endDistanceKm: 1.0,
                altitudeM: 500,
                endAltitudeM: 600,
                gradientPercent: 10,
                category: .moderateUp
            )
        ]
        let result = CourseGradientCalculator.interpolatedAltitude(at: 0, in: segments)
        #expect(result == 500)
    }

    @Test("interpolatedAltitude between segments interpolates correctly")
    func interpolatedAltitude_midSegment_interpolatesCorrectly() throws {
        let segments = [
            GradientSegment(
                distanceKm: 0,
                endDistanceKm: 1.0,
                altitudeM: 500,
                endAltitudeM: 600,
                gradientPercent: 10,
                category: .moderateUp
            )
        ]
        let result = CourseGradientCalculator.interpolatedAltitude(at: 0.5, in: segments)
        #expect(result != nil)
        // At 50% through, altitude should be ~550
        let altitude = try #require(result)
        #expect(abs(altitude - 550) < 1)
    }

    @Test("interpolatedAltitude past end returns last altitude")
    func interpolatedAltitude_pastEnd_returnsLastAltitude() {
        let segments = [
            GradientSegment(
                distanceKm: 0,
                endDistanceKm: 1.0,
                altitudeM: 500,
                endAltitudeM: 600,
                gradientPercent: 10,
                category: .moderateUp
            )
        ]
        let result = CourseGradientCalculator.interpolatedAltitude(at: 5.0, in: segments)
        #expect(result == 600)
    }

    // MARK: - buildEffortProfile / interpolatedCumulativeEffort

    @Test("buildEffortProfile with empty segments returns empty")
    func buildEffortProfile_emptySegments_returnsEmpty() {
        #expect(CourseGradientCalculator.buildEffortProfile(from: []).isEmpty)
    }

    @Test("buildEffortProfile on a flat course accumulates distance only")
    func buildEffortProfile_flatCourse_accumulatesDistanceOnly() {
        let segments = [
            GradientSegment(distanceKm: 0, endDistanceKm: 1, altitudeM: 500, endAltitudeM: 500, gradientPercent: 0, category: .flat),
            GradientSegment(distanceKm: 1, endDistanceKm: 2, altitudeM: 500, endAltitudeM: 500, gradientPercent: 0, category: .flat)
        ]
        let profile = CourseGradientCalculator.buildEffortProfile(from: segments)
        #expect(profile.count == 3)
        #expect(profile[0].cumulativeEffortKm == 0)
        #expect(profile[1].cumulativeEffortKm == 1)
        #expect(profile[2].cumulativeEffortKm == 2)
    }

    @Test("buildEffortProfile adds elevation gain as extra effort, ignores descent")
    func buildEffortProfile_climbAndDescent_weightsGainOnly() {
        let segments = [
            // 1km, +500m gain → effort = 1 + 500/100 = 6
            GradientSegment(distanceKm: 0, endDistanceKm: 1, altitudeM: 1000, endAltitudeM: 1500, gradientPercent: 50, category: .steepUp),
            // 1km, -500m (descent) → effort = 1 + 0 = 1 (no discount for descent either)
            GradientSegment(distanceKm: 1, endDistanceKm: 2, altitudeM: 1500, endAltitudeM: 1000, gradientPercent: -50, category: .steepDown)
        ]
        let profile = CourseGradientCalculator.buildEffortProfile(from: segments)
        #expect(profile.map(\.cumulativeEffortKm) == [0, 6, 7])
    }

    @Test("interpolatedCumulativeEffort at the very start is zero")
    func interpolatedCumulativeEffort_atStart_isZero() {
        let profile = [
            EffortProfilePoint(distanceKm: 0, cumulativeEffortKm: 0),
            EffortProfilePoint(distanceKm: 2, cumulativeEffortKm: 4)
        ]
        #expect(CourseGradientCalculator.interpolatedCumulativeEffort(at: 0, in: profile) == 0)
    }

    @Test("interpolatedCumulativeEffort interpolates linearly mid-segment")
    func interpolatedCumulativeEffort_midSegment_interpolatesLinearly() throws {
        let profile = [
            EffortProfilePoint(distanceKm: 0, cumulativeEffortKm: 0),
            EffortProfilePoint(distanceKm: 2, cumulativeEffortKm: 4)
        ]
        let result = try #require(CourseGradientCalculator.interpolatedCumulativeEffort(at: 1, in: profile))
        #expect(abs(result - 2) < 0.001)
    }

    @Test("interpolatedCumulativeEffort past the end returns total effort")
    func interpolatedCumulativeEffort_pastEnd_returnsTotal() {
        let profile = [
            EffortProfilePoint(distanceKm: 0, cumulativeEffortKm: 0),
            EffortProfilePoint(distanceKm: 2, cumulativeEffortKm: 4)
        ]
        #expect(CourseGradientCalculator.interpolatedCumulativeEffort(at: 10, in: profile) == 4)
    }
}
