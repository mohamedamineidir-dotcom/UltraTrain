import Foundation

enum FinishEstimateRemoteMapper {
    static func toUploadDTO(_ estimate: FinishEstimate) -> FinishEstimateUploadRequestDTO? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        guard let jsonData = try? encoder.encode(estimate),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }

        return FinishEstimateUploadRequestDTO(
            estimateId: estimate.id.uuidString,
            raceId: estimate.raceId.uuidString,
            expectedTime: estimate.expectedTime,
            confidencePercent: estimate.confidencePercent,
            estimateJson: jsonString,
            idempotencyKey: estimate.id.uuidString,
            clientUpdatedAt: nil
        )
    }

    static func toDomain(from response: FinishEstimateResponseDTO) -> FinishEstimate? {
        guard let jsonData = response.estimateJson.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(FinishEstimate.self, from: jsonData)
    }
}
