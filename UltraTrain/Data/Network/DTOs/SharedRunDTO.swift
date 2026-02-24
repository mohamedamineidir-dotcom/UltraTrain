import Foundation

struct ShareRunRequestDTO: Encodable, Sendable {
    let id: String
    let date: String
    let distanceKm: Double
    let elevationGainM: Double
    let elevationLossM: Double
    let duration: Double
    let averagePace: Double
    let gpsTrack: [TrackPointDTO]
    let splits: [SplitDTO]
    let notes: String?
    let recipientProfileIds: [String]
    let idempotencyKey: String
}

struct SharedRunResponseDTO: Decodable, Sendable {
    let id: String
    let sharedByProfileId: String
    let sharedByDisplayName: String
    let date: String
    let distanceKm: Double
    let elevationGainM: Double
    let elevationLossM: Double
    let duration: Double
    let averagePace: Double
    let gpsTrack: [TrackPointDTO]?
    let splits: [SplitDTO]?
    let notes: String?
    let sharedAt: String
    let likeCount: Int
    let commentCount: Int
}
