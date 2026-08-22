import Foundation
import Testing
@testable import UltraTrain

@Suite("KnownRaceCourseLoader Tests")
struct KnownRaceCourseLoaderTests {

    /// Every `KnownRace` that declares a `gpxAssetName` must actually load —
    /// this is the one test that scales automatically as more real courses
    /// get bundled, instead of needing a new hand-written case each time.
    @Test("Every KnownRace with a gpxAssetName loads its bundled course successfully",
          arguments: RaceDatabase.races.compactMap { race -> (String, Double, Double)? in
              guard let asset = race.gpxAssetName else { return nil }
              return (asset, race.distanceKm, race.elevationGainM)
          })
    func loadsBundledKnownRaceCourse(assetName: String, expectedDistanceKm: Double, expectedElevationGainM: Double) throws {
        let result = try #require(KnownRaceCourseLoader.loadCourse(assetName: assetName))
        #expect(result.courseRoute.count > 1)
        // Only races with real climbing need real elevation data in the
        // source file — a near-flat road marathon's GPX legitimately has
        // no <ele> tags without that being a data-quality problem.
        if expectedElevationGainM > 500 {
            #expect(result.elevationGainM > 0)
        }
        // GPX-measured distance should be in the right ballpark of the
        // race's declared distance — catches an asset wired to the wrong
        // KnownRace entry, while tolerating normal GPS/course variance.
        #expect(abs(result.distanceKm - expectedDistanceKm) / expectedDistanceKm < 0.35)
    }

    @Test("Unknown asset name returns nil rather than crashing")
    func unknownAssetReturnsNil() {
        #expect(KnownRaceCourseLoader.loadCourse(assetName: "does-not-exist") == nil)
    }
}
