import Foundation

struct TrainingPlanUploadRequestDTO: Encodable, Sendable {
    let planId: String
    let targetRaceName: String
    let targetRaceDate: String
    let totalWeeks: Int
    let planJson: String
    let idempotencyKey: String
}

struct TrainingPlanResponseDTO: Decodable, Sendable {
    let id: String
    let targetRaceName: String
    let targetRaceDate: String
    let totalWeeks: Int
    let planJson: String
    let createdAt: String?
    let updatedAt: String?
}
