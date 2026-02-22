import SwiftUI

struct ChallengesView: View {
    @State private var viewModel: ChallengesViewModel

    init(
        challengeRepository: any ChallengeRepository,
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository
    ) {
        _viewModel = State(initialValue: ChallengesViewModel(
            challengeRepository: challengeRepository,
            runRepository: runRepository,
            athleteRepository: athleteRepository
        ))
    }

    var body: some View {
        NavigationStack {
            List {
                streakSection
                activeChallengesSection
                availableChallengesSection
                completedSection
            }
            .navigationTitle("Challenges")
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
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        Section {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
                Text("\(viewModel.currentStreak)-day streak")
                    .font(.subheadline.bold())
                Spacer()
                Text("Longest: \(viewModel.longestStreak) days")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Current streak: \(viewModel.currentStreak) days, Longest streak: \(viewModel.longestStreak) days")
        }
    }

    // MARK: - Active Challenges

    private var activeChallengesSection: some View {
        Section("Active Challenges") {
            if viewModel.activeProgress.isEmpty {
                Text("No active challenges")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                ForEach(viewModel.activeProgress, id: \.enrollment.id) { progress in
                    ChallengeProgressRow(progress: progress)
                        .swipeActions(edge: .trailing) {
                            Button("Abandon", role: .destructive) {
                                Task {
                                    await viewModel.abandonChallenge(progress.enrollment.id)
                                }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Available Challenges

    private var availableChallengesSection: some View {
        Section("Available Challenges") {
            if viewModel.availableChallenges.isEmpty {
                Text("All challenges started or completed")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryLabel)
            } else {
                ForEach(viewModel.availableChallenges) { definition in
                    ChallengeDefinitionCard(definition: definition) {
                        Task { await viewModel.startChallenge(definition) }
                    }
                }
            }
        }
    }

    // MARK: - Completed

    @ViewBuilder
    private var completedSection: some View {
        if !viewModel.completedEnrollments.isEmpty {
            Section("Completed") {
                ForEach(viewModel.completedEnrollments) { enrollment in
                    if let definition = ChallengeLibrary.definition(
                        for: enrollment.challengeDefinitionId
                    ) {
                        HStack {
                            Image(systemName: definition.iconName)
                                .foregroundStyle(Theme.Colors.success)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading) {
                                Text(definition.name)
                                    .font(.subheadline.bold())
                                if let completedDate = enrollment.completedDate {
                                    Text("Completed \(completedDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(Theme.Colors.secondaryLabel)
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}
