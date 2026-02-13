import Foundation

enum RaceSwiftDataMapper {
    static func toDomain(_ model: RaceSwiftDataModel) -> Race? {
        guard let priority = RacePriority(rawValue: model.priorityRaw),
              let terrain = TerrainDifficulty(rawValue: model.terrainDifficultyRaw),
              let goal = parseGoal(typeRaw: model.goalTypeRaw, value: model.goalValue) else {
            return nil
        }
        return Race(
            id: model.id,
            name: model.name,
            date: model.date,
            distanceKm: model.distanceKm,
            elevationGainM: model.elevationGainM,
            elevationLossM: model.elevationLossM,
            priority: priority,
            goalType: goal,
            checkpoints: [],
            terrainDifficulty: terrain
        )
    }

    static func toSwiftData(_ race: Race) -> RaceSwiftDataModel {
        let (goalTypeRaw, goalValue) = encodeGoal(race.goalType)
        return RaceSwiftDataModel(
            id: race.id,
            name: race.name,
            date: race.date,
            distanceKm: race.distanceKm,
            elevationGainM: race.elevationGainM,
            elevationLossM: race.elevationLossM,
            priorityRaw: race.priority.rawValue,
            goalTypeRaw: goalTypeRaw,
            goalValue: goalValue,
            terrainDifficultyRaw: race.terrainDifficulty.rawValue
        )
    }

    private static func parseGoal(typeRaw: String, value: Double?) -> RaceGoal? {
        switch typeRaw {
        case "finish":
            return .finish
        case "targetTime":
            guard let v = value else { return nil }
            return .targetTime(v)
        case "targetRanking":
            guard let v = value else { return nil }
            return .targetRanking(Int(v))
        default:
            return nil
        }
    }

    private static func encodeGoal(_ goal: RaceGoal) -> (String, Double?) {
        switch goal {
        case .finish:
            return ("finish", nil)
        case .targetTime(let interval):
            return ("targetTime", interval)
        case .targetRanking(let rank):
            return ("targetRanking", Double(rank))
        }
    }
}
