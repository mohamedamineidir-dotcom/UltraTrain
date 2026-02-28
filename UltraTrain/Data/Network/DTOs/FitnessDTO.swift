import Foundation

struct FitnessSnapshotUploadRequestDTO: Encodable, Sendable {
    let snapshotId: String
    let date: String
    let fitness: Double
    let fatigue: Double
    let form: Double
    let fitnessJson: String
    let idempotencyKey: String
    let clientUpdatedAt: String?
}

struct FitnessSnapshotResponseDTO: Decodable, Sendable {
    let id: String
    let snapshotId: String
    let date: String
    let fitness: Double
    let fatigue: Double
    let form: Double
    let fitnessJson: String
    let createdAt: String?
    let updatedAt: String?
}
