import Foundation

enum IntervalPerformanceFeedbackMapper {

    static func toDomain(_ model: IntervalPerformanceFeedbackSwiftDataModel) -> IntervalPerformanceFeedback {
        // -1 sentinel means the record pre-dates the completedRepCount
        // field. Treat the boolean as authoritative in that case so legacy
        // records don't suddenly report "0 reps done".
        let count: Int? = model.completedRepCount >= 0 ? model.completedRepCount : nil
        return IntervalPerformanceFeedback(
            id: model.id,
            sessionId: model.sessionId,
            sessionType: SessionType(rawValue: model.sessionTypeRaw) ?? .intervals,
            targetPacePerKmAtTime: model.targetPacePerKmAtTime,
            prescribedRepCount: model.prescribedRepCount,
            actualPacesPerKm: decodePaces(from: model.actualPacesData),
            completedAllReps: model.completedAllReps,
            completedRepCount: count,
            perceivedEffort: model.perceivedEffort,
            notes: model.notes,
            createdAt: model.createdAt
        )
    }

    static func toSwiftData(_ feedback: IntervalPerformanceFeedback) -> IntervalPerformanceFeedbackSwiftDataModel {
        IntervalPerformanceFeedbackSwiftDataModel(
            id: feedback.id,
            sessionId: feedback.sessionId,
            sessionTypeRaw: feedback.sessionType.rawValue,
            targetPacePerKmAtTime: feedback.targetPacePerKmAtTime,
            prescribedRepCount: feedback.prescribedRepCount,
            actualPacesData: encodePaces(feedback.actualPacesPerKm),
            completedAllReps: feedback.completedAllReps,
            completedRepCount: feedback.completedRepCount ?? -1,
            perceivedEffort: feedback.perceivedEffort,
            notes: feedback.notes,
            createdAt: feedback.createdAt
        )
    }

    private static func encodePaces(_ paces: [Double]) -> Data {
        (try? JSONEncoder().encode(paces)) ?? Data()
    }

    private static func decodePaces(from data: Data) -> [Double] {
        guard !data.isEmpty else { return [] }
        return (try? JSONDecoder().decode([Double].self, from: data)) ?? []
    }
}
