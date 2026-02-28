import Foundation

struct FinishEstimateUploadRequestDTO: Encodable, Sendable {
    let estimateId: String
    let raceId: String
    let expectedTime: Double
    let confidencePercent: Double
    let estimateJson: String
    let idempotencyKey: String
    let clientUpdatedAt: String?
}

struct FinishEstimateResponseDTO: Decodable, Sendable {
    let id: String
    let estimateId: String
    let raceId: String
    let expectedTime: Double
    let confidencePercent: Double
    let estimateJson: String
    let createdAt: String?
    let updatedAt: String?
}
