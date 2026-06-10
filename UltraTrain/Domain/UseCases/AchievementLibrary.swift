import Foundation

enum AchievementLibrary {

    static let all: [Achievement] = [
        // Distance - Total
        Achievement(id: "total_100km", name: String(localized: "ach.001", defaultValue: "Century Runner"), descriptionText: String(localized: "ach.002", defaultValue: "Run a total of 100 km."), iconName: "figure.run", category: .distance, requirement: .totalDistanceKm(100)),
        Achievement(id: "total_500km", name: String(localized: "ach.003", defaultValue: "Road Warrior"), descriptionText: String(localized: "ach.004", defaultValue: "Run a total of 500 km."), iconName: "figure.run.circle", category: .distance, requirement: .totalDistanceKm(500)),
        Achievement(id: "total_1000km", name: String(localized: "ach.005", defaultValue: "Thousand Miler"), descriptionText: String(localized: "ach.006", defaultValue: "Run a total of 1,000 km."), iconName: "flame", category: .distance, requirement: .totalDistanceKm(1000)),
        Achievement(id: "total_2500km", name: String(localized: "ach.007", defaultValue: "Ultra Legend"), descriptionText: String(localized: "ach.008", defaultValue: "Run a total of 2,500 km."), iconName: "flame.fill", category: .distance, requirement: .totalDistanceKm(2500)),

        // Distance - Single Run
        Achievement(id: "single_10km", name: String(localized: "ach.009", defaultValue: "First 10K"), descriptionText: String(localized: "ach.010", defaultValue: "Complete a single run of 10 km or more."), iconName: "figure.run", category: .distance, requirement: .singleRunDistanceKm(10)),
        Achievement(id: "single_marathon", name: String(localized: "ach.011", defaultValue: "Marathoner"), descriptionText: String(localized: "ach.012", defaultValue: "Complete a single run of 42.2 km or more."), iconName: "medal", category: .distance, requirement: .singleRunDistanceKm(42.2)),
        Achievement(id: "single_50k", name: String(localized: "ach.013", defaultValue: "Ultra Runner"), descriptionText: String(localized: "ach.014", defaultValue: "Complete a single run of 50 km or more."), iconName: "medal.fill", category: .distance, requirement: .singleRunDistanceKm(50)),
        Achievement(id: "single_100k", name: String(localized: "ach.015", defaultValue: "Centurion"), descriptionText: String(localized: "ach.016", defaultValue: "Complete a single run of 100 km or more."), iconName: "star.fill", category: .distance, requirement: .singleRunDistanceKm(100)),

        // Elevation - Total
        Achievement(id: "total_5000m_elev", name: String(localized: "ach.017", defaultValue: "Hill Climber"), descriptionText: String(localized: "ach.018", defaultValue: "Accumulate 5,000 m of total elevation gain."), iconName: "mountain.2", category: .elevation, requirement: .totalElevationM(5000)),
        Achievement(id: "total_10000m_elev", name: String(localized: "ach.019", defaultValue: "Mountain Goat"), descriptionText: String(localized: "ach.020", defaultValue: "Accumulate 10,000 m of total elevation gain."), iconName: "mountain.2.fill", category: .elevation, requirement: .totalElevationM(10000)),
        Achievement(id: "total_25000m_elev", name: String(localized: "ach.021", defaultValue: "Everester"), descriptionText: String(localized: "ach.022", defaultValue: "Accumulate 25,000 m of total elevation gain."), iconName: "arrow.up.right", category: .elevation, requirement: .totalElevationM(25000)),

        // Elevation - Single Run
        Achievement(id: "single_1000m_elev", name: String(localized: "ach.023", defaultValue: "Vertical Kilometer"), descriptionText: String(localized: "ach.024", defaultValue: "Gain 1,000 m of elevation in a single run."), iconName: "arrow.up", category: .elevation, requirement: .singleRunElevationM(1000)),
        Achievement(id: "single_2000m_elev", name: String(localized: "ach.025", defaultValue: "Sky Runner"), descriptionText: String(localized: "ach.026", defaultValue: "Gain 2,000 m of elevation in a single run."), iconName: "cloud", category: .elevation, requirement: .singleRunElevationM(2000)),

        // Consistency
        Achievement(id: "total_10_runs", name: String(localized: "ach.027", defaultValue: "Getting Started"), descriptionText: String(localized: "ach.028", defaultValue: "Complete 10 runs."), iconName: "checkmark.circle", category: .consistency, requirement: .totalRuns(10)),
        Achievement(id: "total_50_runs", name: String(localized: "ach.029", defaultValue: "Dedicated Runner"), descriptionText: String(localized: "ach.030", defaultValue: "Complete 50 runs."), iconName: "checkmark.circle.fill", category: .consistency, requirement: .totalRuns(50)),
        Achievement(id: "total_100_runs", name: String(localized: "ach.031", defaultValue: "Triple Digits"), descriptionText: String(localized: "ach.032", defaultValue: "Complete 100 runs."), iconName: "checkmark.seal", category: .consistency, requirement: .totalRuns(100)),
        Achievement(id: "total_250_runs", name: String(localized: "ach.033", defaultValue: "Unstoppable"), descriptionText: String(localized: "ach.034", defaultValue: "Complete 250 runs."), iconName: "checkmark.seal.fill", category: .consistency, requirement: .totalRuns(250)),
        Achievement(id: "streak_7", name: String(localized: "ach.035", defaultValue: "Week Warrior"), descriptionText: String(localized: "ach.036", defaultValue: "Run every day for 7 days straight."), iconName: "flame", category: .consistency, requirement: .streakDays(7)),
        Achievement(id: "streak_30", name: String(localized: "ach.037", defaultValue: "Iron Will"), descriptionText: String(localized: "ach.038", defaultValue: "Run every day for 30 days straight."), iconName: "flame.fill", category: .consistency, requirement: .streakDays(30)),

        // Race
        Achievement(id: "first_race", name: String(localized: "ach.039", defaultValue: "Race Debut"), descriptionText: String(localized: "ach.040", defaultValue: "Complete your first race."), iconName: "flag", category: .race, requirement: .completedRace),
        Achievement(id: "five_races", name: String(localized: "ach.041", defaultValue: "Seasoned Racer"), descriptionText: String(localized: "ach.042", defaultValue: "Complete 5 races."), iconName: "flag.fill", category: .race, requirement: .completedRaces(5)),

        // Milestone
        Achievement(id: "first_challenge", name: String(localized: "ach.043", defaultValue: "Challenge Accepted"), descriptionText: String(localized: "ach.044", defaultValue: "Complete your first challenge."), iconName: "trophy", category: .milestone, requirement: .completedChallenge(1)),
        Achievement(id: "five_challenges", name: String(localized: "ach.045", defaultValue: "Challenge Champion"), descriptionText: String(localized: "ach.046", defaultValue: "Complete 5 challenges."), iconName: "trophy.fill", category: .milestone, requirement: .completedChallenge(5)),
        Achievement(id: "first_pr", name: String(localized: "ach.047", defaultValue: "Personal Best"), descriptionText: String(localized: "ach.048", defaultValue: "Set your first personal record."), iconName: "star", category: .speed, requirement: .personalRecord),
    ]

    static func definition(for id: String) -> Achievement? {
        all.first { $0.id == id }
    }
}
