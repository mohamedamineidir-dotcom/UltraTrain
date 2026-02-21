import SwiftUI

struct CreateGroupChallengeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateGroupChallengeViewModel

    init(
        challengeRepository: any GroupChallengeRepository,
        profileRepository: any SocialProfileRepository,
        friendRepository: any FriendRepository
    ) {
        _viewModel = State(initialValue: CreateGroupChallengeViewModel(
            challengeRepository: challengeRepository,
            profileRepository: profileRepository,
            friendRepository: friendRepository
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                targetSection
                datesSection
                inviteFriendsSection
            }
            .navigationTitle("New Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    createButton
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
            .onChange(of: viewModel.didCreate) { _, created in
                if created { dismiss() }
            }
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        Section("Details") {
            TextField("Challenge Name", text: $viewModel.name)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Description")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
                TextEditor(text: $viewModel.descriptionText)
                    .frame(minHeight: 60)
            }
            Picker("Type", selection: $viewModel.challengeType) {
                ForEach(ChallengeType.allCases, id: \.self) { type in
                    Text(type.rawValue.capitalized).tag(type)
                }
            }
        }
    }

    // MARK: - Target

    private var targetSection: some View {
        Section("Target") {
            TextField("Target Value", text: $viewModel.targetValue)
                .keyboardType(.decimalPad)
            Text("Unit: \(unitLabel)")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
    }

    private var unitLabel: String {
        switch viewModel.challengeType {
        case .distance: return "km"
        case .elevation: return "m D+"
        case .consistency: return "runs"
        case .streak: return "days"
        }
    }

    // MARK: - Dates

    private var datesSection: some View {
        Section("Schedule") {
            DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
            DatePicker("End Date", selection: $viewModel.endDate, displayedComponents: .date)
        }
    }

    // MARK: - Invite Friends

    private var inviteFriendsSection: some View {
        Section("Invite Friends") {
            if viewModel.friends.isEmpty {
                Text("No friends to invite yet.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                ForEach(viewModel.friends) { friend in
                    friendRow(friend)
                }
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

    // MARK: - Create Button

    private var createButton: some View {
        Button {
            Task { await viewModel.createChallenge() }
        } label: {
            if viewModel.isCreating {
                ProgressView()
            } else {
                Text("Create")
            }
        }
        .disabled(!viewModel.isValid || viewModel.isCreating)
    }
}
