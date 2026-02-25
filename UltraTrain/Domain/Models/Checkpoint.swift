import Foundation

struct Checkpoint: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    var name: String
    var distanceFromStartKm: Double
    var elevationM: Double
    var hasAidStation: Bool
    var latitude: Double? = nil
    var longitude: Double? = nil
}
