import SwiftUI

struct SharedWithMeView: View {
    @State private var viewModel: SharedWithMeViewModel

    init(sharedRunRepository: any SharedRunRepository) {
        _viewModel = State(initialValue: SharedWithMeViewModel(
            sharedRunRepository: sharedRunRepository
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.sharedRuns.isEmpty {
                emptyState
            } else {
                runsList
            }
        }
        .navigationTitle("Shared With Me")
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
            "No Shared Runs",
            systemImage: "person.2.slash",
            description: Text("Runs shared by your friends will appear here.")
        )
    }

    // MARK: - Runs List

    private var runsList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(viewModel.sortedRuns) { run in
                    SharedRunCard(
                        run: run,
                        formattedPace: viewModel.formattedPace(run.averagePaceSecondsPerKm),
                        formattedDuration: viewModel.formattedDuration(run.duration),
                        formattedDate: viewModel.formattedDate(run.date)
                    )
                }
            }
            .padding(Theme.Spacing.md)
        }
    }
}
