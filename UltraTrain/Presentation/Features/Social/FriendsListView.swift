import SwiftUI

struct FriendsListView: View {
    @State private var viewModel: FriendsListViewModel
    @State private var showingAddFriend = false

    private let friendRepository: any FriendRepository
    private let profileRepository: any SocialProfileRepository

    init(
        friendRepository: any FriendRepository,
        profileRepository: any SocialProfileRepository
    ) {
        self.friendRepository = friendRepository
        self.profileRepository = profileRepository
        _viewModel = State(initialValue: FriendsListViewModel(
            friendRepository: friendRepository,
            profileRepository: profileRepository
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.friends.isEmpty && viewModel.pendingRequests.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.friends.isEmpty && viewModel.pendingRequests.isEmpty {
                emptyState
            } else {
                friendsList
            }
        }
        .navigationTitle("Friends")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddFriend = true
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
        .sheet(isPresented: $showingAddFriend) {
            AddFriendSheet(
                friendRepository: friendRepository,
                profileRepository: profileRepository
            )
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "No Friends Yet",
            systemImage: "person.2",
            description: Text("Tap + to add friends and share your runs.")
        )
    }

    // MARK: - Friends List

    private var friendsList: some View {
        List {
            if !viewModel.pendingRequests.isEmpty {
                Section("Pending Requests") {
                    ForEach(viewModel.pendingRequests) { request in
                        FriendRequestCard(
                            connection: request,
                            onAccept: { Task { await viewModel.acceptRequest(request.id) } },
                            onDecline: { Task { await viewModel.declineRequest(request.id) } }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }
            }

            Section("Friends") {
                ForEach(viewModel.friends) { friend in
                    FriendRow(connection: friend)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await viewModel.removeFriend(friend.id) }
                            } label: {
                                Label("Remove", systemImage: "person.badge.minus")
                            }
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
