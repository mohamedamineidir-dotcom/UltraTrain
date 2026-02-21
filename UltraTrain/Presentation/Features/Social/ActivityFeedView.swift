import SwiftUI

struct ActivityFeedView: View {
    @State private var viewModel: ActivityFeedViewModel

    init(activityFeedRepository: any ActivityFeedRepository) {
        _viewModel = State(initialValue: ActivityFeedViewModel(
            activityFeedRepository: activityFeedRepository
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.feedItems.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.feedItems.isEmpty {
                emptyState
            } else {
                feedList
            }
        }
        .navigationTitle("Activity Feed")
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

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "No Activity Yet",
            systemImage: "person.3",
            description: Text("Add friends to see their activity here.")
        )
    }

    // MARK: - Feed List

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(viewModel.sortedItems) { item in
                    ActivityFeedCard(
                        item: item,
                        relativeTime: viewModel.relativeTimestamp(item.timestamp),
                        onLike: {
                            Task { await viewModel.toggleLike(itemId: item.id) }
                        },
                        formatDuration: viewModel.formattedDuration,
                        formatPace: viewModel.formattedPace
                    )
                }
            }
            .padding(Theme.Spacing.md)
        }
    }
}
