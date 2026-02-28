import Foundation

enum FitnessRemoteMapper {
    static func toUploadDTO(_ snapshot: FitnessSnapshot) -> FitnessSnapshotUploadRequestDTO? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        guard let jsonData = try? encoder.encode(snapshot),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        return FitnessSnapshotUploadRequestDTO(
            snapshotId: snapshot.id.uuidString,
            date: formatter.string(from: snapshot.date),
            fitness: snapshot.fitness,
            fatigue: snapshot.fatigue,
            form: snapshot.form,
            fitnessJson: jsonString,
            idempotencyKey: snapshot.id.uuidString,
            clientUpdatedAt: nil
        )
    }

    static func toDomain(from response: FitnessSnapshotResponseDTO) -> FitnessSnapshot? {
        guard let jsonData = response.fitnessJson.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(FitnessSnapshot.self, from: jsonData)
    }
}
