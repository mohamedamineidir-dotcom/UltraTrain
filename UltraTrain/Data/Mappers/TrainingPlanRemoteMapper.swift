import Foundation

enum TrainingPlanRemoteMapper {
    static func toUploadDTO(
        plan: TrainingPlan,
        raceName: String,
        raceDate: Date
    ) -> TrainingPlanUploadRequestDTO? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        guard let jsonData = try? encoder.encode(plan),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        return TrainingPlanUploadRequestDTO(
            planId: plan.id.uuidString,
            targetRaceName: raceName,
            targetRaceDate: formatter.string(from: raceDate),
            totalWeeks: plan.weeks.count,
            planJson: jsonString,
            idempotencyKey: plan.id.uuidString
        )
    }
}
