import Foundation
import Testing
@testable import UltraTrain

@Suite("KnownRaceCourseLoader Tests")
struct KnownRaceCourseLoaderTests {

    @Test("Loads the bundled Oman by UTMB 50K course successfully")
    func loadsOmanByUTMB50K() throws {
        let result = try #require(KnownRaceCourseLoader.loadCourse(assetName: "oman-by-utmb-50k"))
        #expect(result.courseRoute.count > 1)
        #expect(result.distanceKm > 0)
        #expect(result.elevationGainM > 0)
    }

    @Test("Unknown asset name returns nil rather than crashing")
    func unknownAssetReturnsNil() {
        #expect(KnownRaceCourseLoader.loadCourse(assetName: "does-not-exist") == nil)
    }
}
