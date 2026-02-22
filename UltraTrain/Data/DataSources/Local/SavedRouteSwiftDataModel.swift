import Foundation
import SwiftData

@Model
final class SavedRouteSwiftDataModel {
    var id: UUID = UUID()
    var name: String = ""
    var distanceKm: Double = 0
    var elevationGainM: Double = 0
    var elevationLossM: Double = 0
    @Attribute(.externalStorage) var trackPointsData: Data = Data()
    @Attribute(.externalStorage) var courseRouteData: Data = Data()
    @Attribute(.externalStorage) var checkpointsData: Data = Data()
    var sourceRaw: String = "gpxImport"
    var createdAt: Date = Date()
    var notes: String?
    var sourceRunId: UUID?
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        name: String = "",
        distanceKm: Double = 0,
        elevationGainM: Double = 0,
        elevationLossM: Double = 0,
        trackPointsData: Data = Data(),
        courseRouteData: Data = Data(),
        checkpointsData: Data = Data(),
        sourceRaw: String = "gpxImport",
        createdAt: Date = Date(),
        notes: String? = nil,
        sourceRunId: UUID? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.distanceKm = distanceKm
        self.elevationGainM = elevationGainM
        self.elevationLossM = elevationLossM
        self.trackPointsData = trackPointsData
        self.courseRouteData = courseRouteData
        self.checkpointsData = checkpointsData
        self.sourceRaw = sourceRaw
        self.createdAt = createdAt
        self.notes = notes
        self.sourceRunId = sourceRunId
        self.updatedAt = updatedAt
    }
}
