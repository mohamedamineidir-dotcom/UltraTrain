import Foundation

struct CreateChallengeRequestDTO: Encodable, Sendable {
    let name: String
    let descriptionText: String
    let type: String
    let targetValue: Double
    let startDate: String
    let endDate: String
    let idempotencyKey: String
}

struct UpdateProgressRequestDTO: Encodable, Sendable {
    let value: Double
}

struct ChallengeParticipantResponseDTO: Decodable, Sendable {
    let id: String
    let displayName: String
    let currentValue: Double
    let joinedDate: String
}

struct GroupChallengeResponseDTO: Decodable, Sendable {
    let id: String
    let creatorProfileId: String
    let creatorDisplayName: String
    let name: String
    let descriptionText: String
    let type: String
    let targetValue: Double
    let startDate: String
    let endDate: String
    let status: String
    let participants: [ChallengeParticipantResponseDTO]
}
