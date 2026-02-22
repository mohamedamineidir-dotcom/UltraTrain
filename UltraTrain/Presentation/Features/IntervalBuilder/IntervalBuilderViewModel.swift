import Foundation
import os

@Observable
@MainActor
final class IntervalBuilderViewModel {

    // MARK: - State

    var name: String = ""
    var phases: [IntervalPhase] = []
    var category: WorkoutCategory = .speedWork
    var isSaving = false
    var error: String?
    var didSave = false
    var showPhaseEditor = false
    var editingPhase: IntervalPhase?

    // MARK: - Dependencies

    private let repository: any IntervalWorkoutRepository

    // MARK: - Init

    init(repository: any IntervalWorkoutRepository) {
        self.repository = repository
    }

    // MARK: - Computed

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && phases.contains(where: { $0.phaseType == .work })
    }

    var totalEstimatedDuration: TimeInterval {
        let flattened = IntervalGuidanceHandler.flattenPhases(phases)
        return flattened.reduce(0.0) { total, entry in
            switch entry.phase.trigger {
            case .duration(let seconds): return total + seconds
            case .distance: return total + 300
            }
        }
    }

    var workIntervalCount: Int {
        phases.filter { $0.phaseType == .work }
            .reduce(0) { $0 + $1.repeatCount }
    }

    var workToRestRatio: String {
        let workDuration = phases.filter { $0.phaseType == .work }
            .reduce(0.0) { $0 + $1.totalDuration }
        let recoveryDuration = phases.filter { $0.phaseType == .recovery }
            .reduce(0.0) { $0 + $1.totalDuration }
        guard recoveryDuration > 0 else { return "--" }
        let ratio = workDuration / recoveryDuration
        return String(format: "%.1f:1", ratio)
    }

    // MARK: - Actions

    func addPhase(_ phase: IntervalPhase) {
        guard phases.count < AppConfiguration.IntervalGuidance.maxPhaseCount else { return }
        phases.append(phase)
    }

    func updatePhase(_ phase: IntervalPhase) {
        guard let index = phases.firstIndex(where: { $0.id == phase.id }) else { return }
        phases[index] = phase
    }

    func removePhases(at offsets: IndexSet) {
        phases.remove(atOffsets: offsets)
    }

    func movePhases(from source: IndexSet, to destination: Int) {
        phases.move(fromOffsets: source, toOffset: destination)
    }

    func loadPreset(_ workout: IntervalWorkout) {
        name = workout.name
        phases = workout.phases
        category = workout.category
    }

    func save() async {
        guard isValid else {
            error = "Please add a name and at least one work interval."
            return
        }

        isSaving = true
        error = nil

        let workout = IntervalWorkout(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            descriptionText: "",
            phases: phases,
            category: category,
            estimatedDurationSeconds: totalEstimatedDuration,
            estimatedDistanceKm: 0,
            isUserCreated: true
        )

        do {
            try await repository.saveWorkout(workout)
            didSave = true
            Logger.workouts.info("Interval workout created: \(workout.name)")
        } catch {
            self.error = error.localizedDescription
            Logger.workouts.error("Failed to save interval workout: \(error)")
        }

        isSaving = false
    }
}
