import Foundation
import os

@Observable
@MainActor
final class CrossTrainingLogViewModel {

    // MARK: - Dependencies

    private let runRepository: any RunRepository
    private let athleteRepository: any AthleteRepository

    // MARK: - State

    var activityType: ActivityType = .cycling
    var date: Date = .now
    var durationMinutes: Int = 45
    var distanceKm: Double = 0
    var elevationGainM: Double = 0
    var notes: String = ""
    var rpe: Int = 5
    var isSaving = false
    var error: String?
    var didSave = false

    var nonRunningTypes: [ActivityType] {
        ActivityType.allCases.filter { !($0 == .running || $0 == .trailRunning) }
    }

    var showDistanceField: Bool {
        activityType.isDistanceBased
    }

    var showElevationField: Bool {
        activityType.isGPSActivity
    }

    // MARK: - Init

    init(
        runRepository: any RunRepository,
        athleteRepository: any AthleteRepository
    ) {
        self.runRepository = runRepository
        self.athleteRepository = athleteRepository
    }

    // MARK: - Save

    func save() async {
        isSaving = true
        error = nil

        do {
            let athlete = try await athleteRepository.getAthlete()
            guard let athlete else {
                error = "Please complete your profile first."
                isSaving = false
                return
            }

            let duration = TimeInterval(durationMinutes * 60)
            let pace = distanceKm > 0 ? duration / distanceKm : 0

            let activity = CompletedRun(
                id: UUID(),
                athleteId: athlete.id,
                date: date,
                distanceKm: distanceKm,
                elevationGainM: elevationGainM,
                elevationLossM: 0,
                duration: duration,
                averagePaceSecondsPerKm: pace,
                gpsTrack: [],
                splits: [],
                notes: notes.isEmpty ? nil : notes,
                pausedDuration: 0,
                rpe: rpe,
                activityType: activityType
            )

            try await runRepository.saveRun(activity)
            didSave = true
            Logger.tracking.info("Cross-training activity saved: \(self.activityType.rawValue)")
        } catch {
            self.error = error.localizedDescription
            Logger.tracking.error("Failed to save cross-training: \(error)")
        }

        isSaving = false
    }
}
