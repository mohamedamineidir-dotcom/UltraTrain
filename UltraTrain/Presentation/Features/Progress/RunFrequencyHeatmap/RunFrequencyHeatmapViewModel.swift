import Foundation
import os

@Observable
@MainActor
final class RunFrequencyHeatmapViewModel {

    // MARK: - Dependencies

    private let runRepository: any RunRepository
    private let athleteRepository: any AthleteRepository

    // MARK: - State

    var heatmapCells: [HeatmapCalculator.HeatmapCell] = []
    var isLoading = false
    var error: String?
    var totalRunsIncluded: Int = 0

    // MARK: - Init

    init(
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository
    ) {
        self.runRepository = runRepository
        self.athleteRepository = athleteRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            guard let athlete = try await athleteRepository.getAthlete() else {
                isLoading = false
                return
            }

            let allRuns = try await runRepository.getRuns(for: athlete.id)

            // Limit to the most recent 100 runs
            let recentRuns = Array(
                allRuns
                    .sorted { $0.date > $1.date }
                    .prefix(100)
            )

            // Extract GPS tracks, sampling every 3rd point to reduce density
            let tracks: [[TrackPoint]] = recentRuns.compactMap { run in
                let track = run.gpsTrack
                guard !track.isEmpty else { return nil }

                var sampled: [TrackPoint] = []
                sampled.reserveCapacity(track.count / 3 + 1)
                for index in stride(from: 0, to: track.count, by: 3) {
                    sampled.append(track[index])
                }
                return sampled.isEmpty ? nil : sampled
            }

            guard !tracks.isEmpty else {
                heatmapCells = []
                totalRunsIncluded = 0
                isLoading = false
                return
            }

            heatmapCells = HeatmapCalculator.compute(tracks: tracks)
            totalRunsIncluded = tracks.count
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to load run heatmap: \(error)")
        }

        isLoading = false
    }
}
