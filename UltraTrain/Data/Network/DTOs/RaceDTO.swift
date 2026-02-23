import Foundation

struct RaceUploadRequestDTO: Encodable, Sendable {
    let raceId: String
    let name: String
    let date: String
    let distanceKm: Double
    let elevationGainM: Double
    let priority: String
    let raceJson: String
    let idempotencyKey: String
}

struct RaceResponseDTO: Decodable, Sendable {
    let id: String
    let raceId: String
    let name: String
    let date: String
    let distanceKm: Double
    let elevationGainM: Double
    let priority: String
    let raceJson: String
    let createdAt: String?
    let updatedAt: String?
}
