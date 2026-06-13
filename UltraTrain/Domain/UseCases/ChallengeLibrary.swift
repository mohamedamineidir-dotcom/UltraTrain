import Foundation

enum ChallengeLibrary {

    static let all: [ChallengeDefinition] = [
        // Distance
        ChallengeDefinition(
            id: "dist_50km_month", name: String(localized: "chl.001", defaultValue: "50 km Month"),
            descriptionText: String(localized: "chl.002", defaultValue: "Run a total of 50 km in one month."),
            type: .distance, targetValue: 50, duration: .oneMonth,
            iconName: "figure.run"
        ),
        ChallengeDefinition(
            id: "dist_100km_month", name: String(localized: "chl.003", defaultValue: "Century Month"),
            descriptionText: String(localized: "chl.004", defaultValue: "Run a total of 100 km in one month."),
            type: .distance, targetValue: 100, duration: .oneMonth,
            iconName: "figure.run.circle"
        ),
        ChallengeDefinition(
            id: "dist_200km_month", name: String(localized: "chl.005", defaultValue: "Ultra Month"),
            descriptionText: String(localized: "chl.006", defaultValue: "Run a total of 200 km in one month. Ultra distance, ultra commitment."),
            type: .distance, targetValue: 200, duration: .oneMonth,
            iconName: "flame"
        ),

        // Elevation
        ChallengeDefinition(
            id: "elev_2000m_month", name: String(localized: "chl.007", defaultValue: "Mountain Goat"),
            descriptionText: String(localized: "chl.008", defaultValue: "Accumulate 2,000 m of elevation gain in one month."),
            type: .elevation, targetValue: 2000, duration: .oneMonth,
            iconName: "mountain.2"
        ),
        ChallengeDefinition(
            id: "elev_5000m_month", name: String(localized: "chl.009", defaultValue: "Summit Seeker"),
            descriptionText: String(localized: "chl.010", defaultValue: "Accumulate 5,000 m of elevation gain in one month."),
            type: .elevation, targetValue: 5000, duration: .oneMonth,
            iconName: "mountain.2.fill"
        ),

        // Consistency
        ChallengeDefinition(
            id: "consist_3x_4weeks", name: String(localized: "chl.011", defaultValue: "Consistent Runner"),
            descriptionText: String(localized: "chl.012", defaultValue: "Run at least 3 times per week for 4 consecutive weeks."),
            type: .consistency, targetValue: 3, duration: .oneMonth,
            iconName: "calendar.badge.checkmark"
        ),
        ChallengeDefinition(
            id: "consist_5x_4weeks", name: String(localized: "chl.013", defaultValue: "Daily Grinder"),
            descriptionText: String(localized: "chl.014", defaultValue: "Run at least 5 times per week for 4 consecutive weeks."),
            type: .consistency, targetValue: 5, duration: .oneMonth,
            iconName: "calendar.badge.clock"
        ),

        // Streak
        ChallengeDefinition(
            id: "streak_7day", name: String(localized: "chl.015", defaultValue: "7-Day Streak"),
            descriptionText: String(localized: "chl.016", defaultValue: "Run every single day for 7 days straight."),
            type: .streak, targetValue: 7, duration: .oneWeek,
            iconName: "flame.fill"
        ),
        ChallengeDefinition(
            id: "streak_14day", name: String(localized: "chl.017", defaultValue: "14-Day Streak"),
            descriptionText: String(localized: "chl.018", defaultValue: "Run every single day for 14 days straight."),
            type: .streak, targetValue: 14, duration: .twoWeeks,
            iconName: "flame.fill"
        ),
        ChallengeDefinition(
            id: "streak_30day", name: String(localized: "chl.019", defaultValue: "30-Day Streak"),
            descriptionText: String(localized: "chl.020", defaultValue: "Run every single day for 30 days. The ultimate consistency test."),
            type: .streak, targetValue: 30, duration: .oneMonth,
            iconName: "flame.fill"
        ),
    ]

    static func definition(for id: String) -> ChallengeDefinition? {
        all.first { $0.id == id }
    }
}
