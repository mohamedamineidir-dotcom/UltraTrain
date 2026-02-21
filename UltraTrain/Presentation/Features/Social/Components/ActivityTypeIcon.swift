import SwiftUI

struct ActivityTypeIcon: View {
    let activityType: ActivityType

    var body: some View {
        Image(systemName: iconName)
            .font(.caption)
            .foregroundStyle(.white)
            .padding(Theme.Spacing.xs)
            .background(iconColor, in: Circle())
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
