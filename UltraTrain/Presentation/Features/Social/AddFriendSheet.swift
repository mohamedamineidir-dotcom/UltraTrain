import SwiftUI

struct AddFriendSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddFriendViewModel

    init(
        friendRepository: any FriendRepository,
        profileRepository: any SocialProfileRepository
    ) {
        _viewModel = State(initialValue: AddFriendViewModel(
            friendRepository: friendRepository,
            profileRepository: profileRepository
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                searchField
                if viewModel.isSearching {
                    ProgressView()
                }
                if let profile = viewModel.foundProfile {
                    profileResult(profile)
                }
                if viewModel.didSend {
                    successMessage
                }
                Spacer()
            }
            .padding(Theme.Spacing.md)
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: Theme.Spacing.sm) {
            TextField("Profile ID or display name", text: $viewModel.searchText)
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { Task { await viewModel.searchProfile() } }

            Button {
                Task { await viewModel.searchProfile() }
            } label: {
                Image(systemName: "magnifyingglass")
            }
            .disabled(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // MARK: - Profile Result

    private func profileResult(_ profile: SocialProfile) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            SocialProfileCard(profile: profile)

            Button {
                Task { await viewModel.sendRequest() }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isSending {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("Send Friend Request", systemImage: "person.badge.plus")
                    }
                    Spacer()
                }
                .padding(.vertical, Theme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSending || viewModel.didSend)
        }
    }

    // MARK: - Success

    private var successMessage: some View {
        Label("Friend request sent!", systemImage: "checkmark.circle.fill")
            .foregroundStyle(Theme.Colors.success)
            .font(.headline)
    }
}
