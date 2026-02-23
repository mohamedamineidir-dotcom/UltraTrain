import Foundation

enum RaceRemoteMapper {
    static func toUploadDTO(_ race: Race) -> RaceUploadRequestDTO? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        guard let jsonData = try? encoder.encode(race),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        return RaceUploadRequestDTO(
            raceId: race.id.uuidString,
            name: race.name,
            date: formatter.string(from: race.date),
            distanceKm: race.distanceKm,
            elevationGainM: race.elevationGainM,
            priority: race.priority.rawValue,
            raceJson: jsonString,
            idempotencyKey: race.id.uuidString
        )
    }

    static func toDomain(from response: RaceResponseDTO) -> Race? {
        guard let jsonData = response.raceJson.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Race.self, from: jsonData)
    }
}
