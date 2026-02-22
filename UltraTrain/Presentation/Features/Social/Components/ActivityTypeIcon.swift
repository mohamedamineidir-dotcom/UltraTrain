import SwiftUI

struct ActivityTypeIcon: View {
    let activityType: FeedActivityType

    var body: some View {
        Image(systemName: iconName)
            .font(.caption)
            .foregroundStyle(.white)
            .padding(Theme.Spacing.xs)
            .background(iconColor, in: Circle())
            .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        switch activityType {
        case .completedRun: "Completed run"
        case .personalRecord: "Personal record"
        case .challengeCompleted: "Challenge completed"
        case .raceFinished: "Race finished"
        case .weeklyGoalMet: "Weekly goal met"
        case .friendJoined: "Friend joined"
        }
    }

    private var iconName: String {
        switch activityType {
        case .completedRun: "figure.run"
        case .personalRecord: "star.fill"
        case .challengeCompleted: "trophy.fill"
        case .raceFinished: "flag.checkered.2.crossed"
        case .weeklyGoalMet: "target"
        case .friendJoined: "person.badge.plus"
        }
    }

    private var iconColor: Color {
        switch activityType {
        case .completedRun: Theme.Colors.primary
        case .personalRecord: Theme.Colors.warning
        case .challengeCompleted: Theme.Colors.success
        case .raceFinished: Theme.Colors.info
        case .weeklyGoalMet: Theme.Colors.success
        case .friendJoined: Theme.Colors.primary
        }
    }
}
