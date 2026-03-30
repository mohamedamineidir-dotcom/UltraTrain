import Foundation

struct Race: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    var name: String
    var date: Date
    var distanceKm: Double
    var elevationGainM: Double
    var elevationLossM: Double
    var priority: RacePriority
    var goalType: RaceGoal
    var checkpoints: [Checkpoint]
    var terrainDifficulty: TerrainDifficulty
    var raceType: RaceType = .trail
    var actualFinishTime: TimeInterval?
    var linkedRunId: UUID?
    var locationLatitude: Double? = nil
    var locationLongitude: Double? = nil
    var locationName: String? = nil
    var forecastedWeather: WeatherSnapshot? = nil
    var courseRoute: [TrackPoint] = []
    var savedRouteId: UUID? = nil
    var serverUpdatedAt: Date? = nil

    var hasCourseRoute: Bool { !courseRoute.isEmpty }

    var isCompleted: Bool { actualFinishTime != nil }

    var hasLocation: Bool {
        locationLatitude != nil && locationLongitude != nil
    }

    var effectiveDistanceKm: Double {
        distanceKm + (elevationGainM / 100.0)
    }

    /// Estimated race duration based on goal type or effective distance heuristic.
    func estimatedDuration(experience: ExperienceLevel) -> TimeInterval {
        if case .targetTime(let time) = goalType { return time }
        let paceMinPerKm: Double = switch experience {
        case .elite:        8.0
        case .advanced:     9.0
        case .intermediate: 10.0
        case .beginner:     12.0
        }
        return effectiveDistanceKm * paceMinPerKm * 60
    }

    /// Creates a synthetic race for users without a target race.
    /// Used as input to the training plan generator — not saved to the database.
    static func generalFitness(startingFrom date: Date = .now) -> Race {
        let calendar = Calendar.current
        // invariant: Calendar.date(byAdding:) always succeeds for simple offsets
        let endDate = calendar.date(byAdding: .weekOfYear, value: 12, to: date)!
        return Race(
            id: UUID(),
            name: "General Fitness",
            date: endDate,
            distanceKm: 50,
            elevationGainM: 500,
            elevationLossM: 500,
            priority: .aRace,
            goalType: .finish,
            checkpoints: [],
            terrainDifficulty: .easy,
            raceType: .trail
        )
    }
}
