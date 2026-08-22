import UIKit
import os

/// Loads a bundled GPX course for the small set of known races we've
/// sourced a real, official course for (`KnownRace.gpxAssetName`), running
/// it through the exact same parse/import pipeline as a user-uploaded GPX
/// so the result is indistinguishable to the rest of the app.
///
/// Bundled as an Asset Catalog Data Set (not a loose resource file) —
/// xcodegen's default resource-file-type detection doesn't reliably add
/// unrecognized extensions like `.gpx` to the app target's Resources
/// build phase, while Data Sets always do since they go through
/// Assets.xcassets, which is already correctly bundled.
enum KnownRaceCourseLoader {
    static func loadCourse(assetName: String) -> CourseImportResult? {
        guard let asset = NSDataAsset(name: "RaceCourse-\(assetName)") else {
            Logger.importData.warning("KnownRaceCourseLoader: bundled GPX asset 'RaceCourse-\(assetName)' not found")
            return nil
        }
        do {
            let parseResult = try GPXParser().parse(asset.data)
            return try CourseImportUseCase.importCourse(from: parseResult)
        } catch {
            Logger.importData.error("KnownRaceCourseLoader: failed to load '\(assetName)': \(error.localizedDescription)")
            return nil
        }
    }
}
