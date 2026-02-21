import SwiftUI

struct SocialTabView: View {
    private let friendRepository: any FriendRepository
    private let profileRepository: any SocialProfileRepository
    private let athleteRepository: any AthleteRepository
    private let runRepository: any RunRepository
    private let activityFeedRepository: any ActivityFeedRepository
    private let sharedRunRepository: any SharedRunRepository

    init(
        friendRepository: any FriendRepository,
        profileRepository: any SocialProfileRepository,
        athleteRepository: any AthleteRepository,
        runRepository: any RunRepository,
        activityFeedRepository: any ActivityFeedRepository,
        sharedRunRepository: any SharedRunRepository
    ) {
        self.friendRepository = friendRepository
        self.profileRepository = profileRepository
        self.athleteRepository = athleteRepository
        self.runRepository = runRepository
        self.activityFeedRepository = activityFeedRepository
        self.sharedRunRepository = sharedRunRepository
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    myProfileRow
                    friendsRow
                    activityFeedRow
                    sharedWithMeRow
                }
            }
            .navigationTitle("Social")
        }
    }

    // MARK: - Rows

    private var myProfileRow: some View {
        NavigationLink {
            SocialProfileView(
                profileRepository: profileRepository,
                athleteRepository: athleteRepository,
                runRepository: runRepository
            )
        } label: {
            Label {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("My Profile")
                        .font(.body)
                    Text("Manage your social profile and privacy")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            } icon: {
                Image(systemName: "person.circle")
                    .foregroundStyle(Theme.Colors.primary)
            }
        }
    }

    private var friendsRow: some View {
        NavigationLink {
            FriendsListView(
                friendRepository: friendRepository,
                profileRepository: profileRepository
            )
        } label: {
            Label {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Friends")
                        .font(.body)
                    Text("View and manage your friends")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            } icon: {
                Image(systemName: "person.2")
                    .foregroundStyle(Theme.Colors.primary)
            }
        }
    }

    private var activityFeedRow: some View {
        NavigationLink {
            ActivityFeedView(activityFeedRepository: activityFeedRepository)
        } label: {
            Label {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Activity Feed")
                        .font(.body)
                    Text("See what your friends are up to")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            } icon: {
                Image(systemName: "bolt.heart")
                    .foregroundStyle(Theme.Colors.primary)
            }
        }
    }

    private var sharedWithMeRow: some View {
        NavigationLink {
            SharedWithMeView(sharedRunRepository: sharedRunRepository)
        } label: {
            Label {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Shared With Me")
                        .font(.body)
                    Text("Runs shared by your friends")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.secondaryLabel)
                }
            } icon: {
                Image(systemName: "tray.and.arrow.down")
                    .foregroundStyle(Theme.Colors.primary)
            }
        }
    }
}
