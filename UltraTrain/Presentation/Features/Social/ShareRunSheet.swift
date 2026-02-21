import SwiftUI

struct ShareRunSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ShareRunViewModel

    init(
        completedRun: CompletedRun,
        sharedRunRepository: any SharedRunRepository,
        friendRepository: any FriendRepository,
        profileRepository: any SocialProfileRepository
    ) {
        _viewModel = State(initialValue: ShareRunViewModel(
            completedRun: completedRun,
            sharedRunRepository: sharedRunRepository,
            friendRepository: friendRepository,
            profileRepository: profileRepository
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                runSummary
                Divider()
                friendsList
                Spacer()
                shareButton
            }
            .navigationTitle("Share Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await viewModel.loadFriends()
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .onChange(of: viewModel.didShare) { _, shared in
                if shared { dismiss() }
            }
        }
    }

    // MARK: - Run Summary

    private var runSummary: some View {
        HStack(spacing: Theme.Spacing.lg) {
            statLabel(
                value: String(format: "%.1f km", viewModel.completedRun.distanceKm),
                label: "Distance"
            )
            statLabel(
                value: viewModel.completedRun.paceFormatted,
                label: "Pace"
            )
            statLabel(
                value: String(format: "%.0f m", viewModel.completedRun.elevationGainM),
                label: "Elevation"
            )
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.secondaryBackground)
    }

    private func statLabel(value: String, label: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    // MARK: - Friends List

    private var friendsList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.friends.isEmpty {
                ContentUnavailableView(
                    "No Friends Yet",
                    systemImage: "person.2.slash",
                    description: Text("Add friends to share your runs with them.")
                )
            } else {
                List(viewModel.friends) { friend in
                    friendRow(friend)
                }
                .listStyle(.plain)
            }
        }
    }

    private func friendRow(_ friend: FriendConnection) -> some View {
        let isSelected = viewModel.selectedFriendIds.contains(friend.friendProfileId)
        return Button {
            viewModel.toggleFriend(friend.friendProfileId)
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                Text(friend.friendDisplayName)
                    .font(.body)
                    .foregroundStyle(Theme.Colors.label)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryLabel)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button {
            Task { await viewModel.share() }
        } label: {
            HStack {
                Spacer()
                if viewModel.isSharing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Label(
                        "Share with \(viewModel.selectedFriendIds.count) friend\(viewModel.selectedFriendIds.count == 1 ? "" : "s")",
                        systemImage: "paperplane.fill"
                    )
                }
                Spacer()
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.selectedFriendIds.isEmpty || viewModel.isSharing)
        .padding(Theme.Spacing.md)
    }
}
