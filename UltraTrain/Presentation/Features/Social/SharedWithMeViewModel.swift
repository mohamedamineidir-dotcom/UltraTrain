import Foundation
import os

@Observable
@MainActor
final class SharedWithMeViewModel {

    // MARK: - Dependencies

    private let sharedRunRepository: any SharedRunRepository

    // MARK: - State

    var sharedRuns: [SharedRun] = []
    var isLoading = false
    var error: String?

    // MARK: - Init

    init(sharedRunRepository: any SharedRunRepository) {
        self.sharedRunRepository = sharedRunRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil
        do {
            sharedRuns = try await sharedRunRepository.fetchSharedRuns()
        } catch {
            self.error = error.localizedDescription
            Logger.social.error("Failed to load shared runs: \(error)")
        }
        isLoading = false
    }

    // MARK: - Computed

    var sortedRuns: [SharedRun] {
        sharedRuns.sorted { $0.sharedAt > $1.sharedAt }
    }

    // MARK: - Formatting

    func formattedPace(_ secondsPerKm: Double) -> String {
        let minutes = Int(secondsPerKm) / 60
        let seconds = Int(secondsPerKm) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }

    func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        }
        return String(format: "%dm", minutes)
    }

    func formattedDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}
