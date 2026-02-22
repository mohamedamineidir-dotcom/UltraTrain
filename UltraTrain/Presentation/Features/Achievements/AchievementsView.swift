import SwiftUI

struct AchievementsView: View {
    @State private var viewModel: AchievementsViewModel

    init(
        achievementRepository: any AchievementRepository,
        runRepository: any RunRepository,
        challengeRepository: any ChallengeRepository,
        raceRepository: any RaceRepository
    ) {
        _viewModel = State(initialValue: AchievementsViewModel(
            achievementRepository: achievementRepository,
            runRepository: runRepository,
            challengeRepository: challengeRepository,
            raceRepository: raceRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                progressHeader
                categoryFilter
                achievementGrid
            }
            .padding()
        }
        .navigationTitle("Achievements")
        .task { await viewModel.load() }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("\(viewModel.unlockedCount) / \(viewModel.totalCount)")
                .font(.title.bold().monospacedDigit())

            ProgressView(
                value: Double(viewModel.unlockedCount),
                total: Double(viewModel.totalCount)
            )
            .tint(Theme.Colors.primary)

            Text("Achievements Unlocked")
                .font(.caption)
                .foregroundStyle(Theme.Colors.secondaryLabel)
        }
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(viewModel.unlockedCount) of \(viewModel.totalCount) achievements unlocked")
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                filterChip(label: "All", category: nil)
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    filterChip(label: category.displayName, category: category)
                }
            }
            .padding(.horizontal, Theme.Spacing.xs)
        }
    }

    private func filterChip(label: String, category: AchievementCategory?) -> some View {
        let isSelected = viewModel.selectedCategory == category
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedCategory = category
            }
        } label: {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryBackground)
                )
                .foregroundStyle(isSelected ? .white : Theme.Colors.label)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Grid

    private var achievementGrid: some View {
        let columns = [
            GridItem(.adaptive(minimum: 80), spacing: Theme.Spacing.md)
        ]

        return LazyVGrid(columns: columns, spacing: Theme.Spacing.lg) {
            ForEach(viewModel.displayedAchievements) { achievement in
                AchievementBadge(
                    achievement: achievement,
                    isUnlocked: viewModel.isUnlocked(achievement),
                    unlockedDate: viewModel.unlockedDate(for: achievement)
                )
            }
        }
    }
}
