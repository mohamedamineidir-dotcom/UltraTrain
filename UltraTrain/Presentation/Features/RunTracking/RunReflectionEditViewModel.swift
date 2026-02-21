import Foundation
import os

@Observable
@MainActor
final class RunReflectionEditViewModel {
    private let runRepository: any RunRepository

    var run: CompletedRun
    var rpe: Int?
    var perceivedFeeling: PerceivedFeeling?
    var terrainType: TerrainType?
    var notes: String
    var isSaving = false
    var error: String?
    var didSave = false

    init(run: CompletedRun, runRepository: any RunRepository) {
        self.runRepository = runRepository
        self.run = run
        self.rpe = run.rpe
        self.perceivedFeeling = run.perceivedFeeling
        self.terrainType = run.terrainType
        self.notes = run.notes ?? ""
    }

    func save() async {
        isSaving = true
        defer { isSaving = false }

        var updatedRun = run
        updatedRun.rpe = rpe
        updatedRun.perceivedFeeling = perceivedFeeling
        updatedRun.terrainType = terrainType
        updatedRun.notes = notes.isEmpty ? nil : notes

        do {
            try await runRepository.updateRun(updatedRun)
            run = updatedRun
            didSave = true
        } catch {
            self.error = error.localizedDescription
            Logger.tracking.error("Failed to save reflection: \(error)")
        }
    }
}
