import SwiftUI

struct GroupChallengesView: View {
    @State private var viewModel: GroupChallengesViewModel

    private let challengeRepository: any GroupChallengeRepository
    private let profileRepository: any SocialProfileRepository
    private let friendRepository: any FriendRepository

    init(
        challengeRepository: any GroupChallengeRepository,
        profileRepository: any SocialProfileRepository,
        friendRepository: any FriendRepository
    ) {
        self.challengeRepository = challengeRepository
        self.profileRepository = profileRepository
        self.friendRepository = friendRepository
        _viewModel = State(initialValue: GroupChallengesViewModel(
            challengeRepository: challengeRepository,
            profileRepository: profileRepository
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.activeChallenges.isEmpty && viewModel.completedChallenges.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.activeChallenges.isEmpty && viewModel.completedChallenges.isEmpty {
                emptyState
            } else {
                challengeList
            }
        }
        .navigationTitle("Group Challenges")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .sheet(isPresented: $viewModel.showingCreateSheet) {
            Task { await viewModel.load() }
        } content: {
            CreateGroupChallengeSheet(
                challengeRepository: challengeRepository,
                profileRepository: profileRepository,
                friendRepository: friendRepository
            )
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "No Group Challenges",
            systemImage: "person.3",
            description: Text("Create a challenge and invite friends to compete together.")
        )
    }

    // MARK: - Challenge List

    private var challengeList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                if !viewModel.activeChallenges.isEmpty {
                    challengeSection(title: "Active Challenges", challenges: viewModel.activeChallenges)
                }
                if !viewModel.completedChallenges.isEmpty {
                    challengeSection(title: "Completed", challenges: viewModel.completedChallenges)
                }
            }
            .padding(Theme.Spacing.md)
        }
    }

    private func challengeSection(title: String, challenges: [GroupChallenge]) -> some View {
        Section {
            ForEach(challenges) { challenge in
                NavigationLink(value: challenge.id) {
                    GroupChallengeCard(challenge: challenge)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
