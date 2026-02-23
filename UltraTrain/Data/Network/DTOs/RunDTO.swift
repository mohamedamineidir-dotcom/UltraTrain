import Foundation

struct TrackPointDTO: Codable, Sendable {
    let latitude: Double
    let longitude: Double
    let altitudeM: Double
    let timestamp: String
    let heartRate: Int?
}

struct SplitDTO: Codable, Sendable {
    let id: String
    let kilometerNumber: Int
    let duration: Double
    let elevationChangeM: Double
    let averageHeartRate: Int?
}

struct RunUploadRequestDTO: Encodable, Sendable {
    let id: String
    let date: String
    let distanceKm: Double
    let elevationGainM: Double
    let elevationLossM: Double
    let duration: Double
    let averageHeartRate: Int?
    let maxHeartRate: Int?
    let averagePaceSecondsPerKm: Double
    let gpsTrack: [TrackPointDTO]
    let splits: [SplitDTO]
    let notes: String?
    let linkedSessionId: String?
    let idempotencyKey: String
    let clientUpdatedAt: String?
}

struct RunResponseDTO: Decodable, Sendable {
    let id: String
    let date: String
    let distanceKm: Double
    let elevationGainM: Double
    let elevationLossM: Double
    let duration: Double
    let averageHeartRate: Int?
    let maxHeartRate: Int?
    let averagePaceSecondsPerKm: Double
    let gpsTrack: [TrackPointDTO]?
    let splits: [SplitDTO]?
    let notes: String?
    let linkedSessionId: String?
    let createdAt: String?
    let updatedAt: String?
}
