import Foundation
import os

@Observable
@MainActor
final class RunHistoryViewModel {

    // MARK: - Dependencies

    private let runRepository: any RunRepository

    // MARK: - State

    var runs: [CompletedRun] = []
    var isLoading = false
    var error: String?

    // MARK: - Init

    init(runRepository: any RunRepository) {
        self.runRepository = runRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            runs = try await runRepository.getRecentRuns(limit: 100)
        } catch {
            self.error = error.localizedDescription
            Logger.tracking.error("Failed to load run history: \(error)")
        }

        isLoading = false
    }

    // MARK: - Delete

    func deleteRun(id: UUID) async {
        do {
            try await runRepository.deleteRun(id: id)
            runs.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
            Logger.tracking.error("Failed to delete run: \(error)")
        }
    }

    // MARK: - Computed

    var sortedRuns: [CompletedRun] {
        runs.sorted { $0.date > $1.date }
    }
}
