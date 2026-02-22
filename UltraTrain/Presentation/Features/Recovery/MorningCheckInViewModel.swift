import Foundation
import os

@Observable
@MainActor
final class MorningCheckInViewModel {

    private let morningCheckInRepository: any MorningCheckInRepository

    var perceivedEnergy: Int = 3
    var muscleSoreness: Int = 1
    var mood: Int = 3
    var sleepQualitySubjective: Int = 3
    var notes: String = ""
    var isLoading = false
    var isSaving = false
    var error: String?
    var didSave = false

    private var existingCheckInId: UUID?

    init(morningCheckInRepository: any MorningCheckInRepository) {
        self.morningCheckInRepository = morningCheckInRepository
    }

    func loadTodaysCheckIn() async {
        isLoading = true
        do {
            if let existing = try await morningCheckInRepository.getCheckIn(for: Date.now) {
                existingCheckInId = existing.id
                perceivedEnergy = existing.perceivedEnergy
                muscleSoreness = existing.muscleSoreness
                mood = existing.mood
                sleepQualitySubjective = existing.sleepQualitySubjective
                notes = existing.notes ?? ""
            }
        } catch {
            self.error = error.localizedDescription
            Logger.recovery.error("Failed to load today's check-in: \(error)")
        }
        isLoading = false
    }

    func save() async {
        isSaving = true
        let checkIn = MorningCheckIn(
            id: existingCheckInId ?? UUID(),
            date: Date.now,
            perceivedEnergy: perceivedEnergy,
            muscleSoreness: muscleSoreness,
            mood: mood,
            sleepQualitySubjective: sleepQualitySubjective,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            try await morningCheckInRepository.saveCheckIn(checkIn)
            didSave = true
        } catch {
            self.error = error.localizedDescription
            Logger.recovery.error("Failed to save morning check-in: \(error)")
        }
        isSaving = false
    }
}
