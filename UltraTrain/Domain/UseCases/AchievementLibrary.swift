import Foundation

enum AchievementLibrary {

    static let all: [Achievement] = [
        // Distance - Total
        Achievement(id: "total_100km", name: "Century Runner", descriptionText: "Run a total of 100 km.", iconName: "figure.run", category: .distance, requirement: .totalDistanceKm(100)),
        Achievement(id: "total_500km", name: "Road Warrior", descriptionText: "Run a total of 500 km.", iconName: "figure.run.circle", category: .distance, requirement: .totalDistanceKm(500)),
        Achievement(id: "total_1000km", name: "Thousand Miler", descriptionText: "Run a total of 1,000 km.", iconName: "flame", category: .distance, requirement: .totalDistanceKm(1000)),
        Achievement(id: "total_2500km", name: "Ultra Legend", descriptionText: "Run a total of 2,500 km.", iconName: "flame.fill", category: .distance, requirement: .totalDistanceKm(2500)),

        // Distance - Single Run
        Achievement(id: "single_10km", name: "First 10K", descriptionText: "Complete a single run of 10 km or more.", iconName: "figure.run", category: .distance, requirement: .singleRunDistanceKm(10)),
        Achievement(id: "single_marathon", name: "Marathoner", descriptionText: "Complete a single run of 42.2 km or more.", iconName: "medal", category: .distance, requirement: .singleRunDistanceKm(42.2)),
        Achievement(id: "single_50k", name: "Ultra Runner", descriptionText: "Complete a single run of 50 km or more.", iconName: "medal.fill", category: .distance, requirement: .singleRunDistanceKm(50)),
        Achievement(id: "single_100k", name: "Centurion", descriptionText: "Complete a single run of 100 km or more.", iconName: "star.fill", category: .distance, requirement: .singleRunDistanceKm(100)),

        // Elevation - Total
        Achievement(id: "total_5000m_elev", name: "Hill Climber", descriptionText: "Accumulate 5,000 m of total elevation gain.", iconName: "mountain.2", category: .elevation, requirement: .totalElevationM(5000)),
        Achievement(id: "total_10000m_elev", name: "Mountain Goat", descriptionText: "Accumulate 10,000 m of total elevation gain.", iconName: "mountain.2.fill", category: .elevation, requirement: .totalElevationM(10000)),
        Achievement(id: "total_25000m_elev", name: "Everester", descriptionText: "Accumulate 25,000 m of total elevation gain.", iconName: "arrow.up.right", category: .elevation, requirement: .totalElevationM(25000)),

        // Elevation - Single Run
        Achievement(id: "single_1000m_elev", name: "Vertical Kilometer", descriptionText: "Gain 1,000 m of elevation in a single run.", iconName: "arrow.up", category: .elevation, requirement: .singleRunElevationM(1000)),
        Achievement(id: "single_2000m_elev", name: "Sky Runner", descriptionText: "Gain 2,000 m of elevation in a single run.", iconName: "cloud", category: .elevation, requirement: .singleRunElevationM(2000)),

        // Consistency
        Achievement(id: "total_10_runs", name: "Getting Started", descriptionText: "Complete 10 runs.", iconName: "checkmark.circle", category: .consistency, requirement: .totalRuns(10)),
        Achievement(id: "total_50_runs", name: "Dedicated Runner", descriptionText: "Complete 50 runs.", iconName: "checkmark.circle.fill", category: .consistency, requirement: .totalRuns(50)),
        Achievement(id: "total_100_runs", name: "Triple Digits", descriptionText: "Complete 100 runs.", iconName: "checkmark.seal", category: .consistency, requirement: .totalRuns(100)),
        Achievement(id: "total_250_runs", name: "Unstoppable", descriptionText: "Complete 250 runs.", iconName: "checkmark.seal.fill", category: .consistency, requirement: .totalRuns(250)),
        Achievement(id: "streak_7", name: "Week Warrior", descriptionText: "Run every day for 7 days straight.", iconName: "flame", category: .consistency, requirement: .streakDays(7)),
        Achievement(id: "streak_30", name: "Iron Will", descriptionText: "Run every day for 30 days straight.", iconName: "flame.fill", category: .consistency, requirement: .streakDays(30)),

        // Race
        Achievement(id: "first_race", name: "Race Debut", descriptionText: "Complete your first race.", iconName: "flag", category: .race, requirement: .completedRace),
        Achievement(id: "five_races", name: "Seasoned Racer", descriptionText: "Complete 5 races.", iconName: "flag.fill", category: .race, requirement: .completedRaces(5)),

        // Milestone
        Achievement(id: "first_challenge", name: "Challenge Accepted", descriptionText: "Complete your first challenge.", iconName: "trophy", category: .milestone, requirement: .completedChallenge(1)),
        Achievement(id: "five_challenges", name: "Challenge Champion", descriptionText: "Complete 5 challenges.", iconName: "trophy.fill", category: .milestone, requirement: .completedChallenge(5)),
        Achievement(id: "first_pr", name: "Personal Best", descriptionText: "Set your first personal record.", iconName: "star", category: .speed, requirement: .personalRecord),
    ]

    static func definition(for id: String) -> Achievement? {
        all.first { $0.id == id }
    }
}
