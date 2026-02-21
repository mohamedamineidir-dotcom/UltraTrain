import Foundation

enum RaceSwiftDataMapper {
    static func toDomain(_ model: RaceSwiftDataModel) -> Race? {
        guard let priority = RacePriority(rawValue: model.priorityRaw),
              let terrain = TerrainDifficulty(rawValue: model.terrainDifficultyRaw),
              let goal = parseGoal(typeRaw: model.goalTypeRaw, value: model.goalValue) else {
            return nil
        }
        let checkpoints = model.checkpointModels
            .map { cp in
                Checkpoint(
                    id: cp.id,
                    name: cp.name,
                    distanceFromStartKm: cp.distanceFromStartKm,
                    elevationM: cp.elevationM,
                    hasAidStation: cp.hasAidStation
                )
            }
            .sorted { $0.distanceFromStartKm < $1.distanceFromStartKm }

        return Race(
            id: model.id,
            name: model.name,
            date: model.date,
            distanceKm: model.distanceKm,
            elevationGainM: model.elevationGainM,
            elevationLossM: model.elevationLossM,
            priority: priority,
            goalType: goal,
            checkpoints: checkpoints,
            terrainDifficulty: terrain,
            actualFinishTime: model.actualFinishTime,
            linkedRunId: model.linkedRunId,
            locationLatitude: model.locationLatitude,
            locationLongitude: model.locationLongitude,
            forecastedWeather: decodeWeather(model.forecastedWeatherData)
        )
    }

    static func toSwiftData(_ race: Race) -> RaceSwiftDataModel {
        let (goalTypeRaw, goalValue) = encodeGoal(race.goalType)
        let checkpointModels = race.checkpoints.map { cp in
            CheckpointSwiftDataModel(
                id: cp.id,
                name: cp.name,
                distanceFromStartKm: cp.distanceFromStartKm,
                elevationM: cp.elevationM,
                hasAidStation: cp.hasAidStation
            )
        }
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
            terrainDifficultyRaw: race.terrainDifficulty.rawValue,
            checkpointModels: checkpointModels,
            actualFinishTime: race.actualFinishTime,
            linkedRunId: race.linkedRunId,
            locationLatitude: race.locationLatitude,
            locationLongitude: race.locationLongitude,
            forecastedWeatherData: encodeWeather(race.forecastedWeather)
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

    private static func encodeWeather(_ weather: WeatherSnapshot?) -> Data? {
        guard let weather else { return nil }
        return try? JSONEncoder().encode(weather)
    }

    private static func decodeWeather(_ data: Data?) -> WeatherSnapshot? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(WeatherSnapshot.self, from: data)
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
