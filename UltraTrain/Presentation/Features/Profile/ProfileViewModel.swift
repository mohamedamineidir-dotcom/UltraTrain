import Foundation
import os

@Observable
@MainActor
final class ProfileViewModel {

    // MARK: - Dependencies

    private let athleteRepository: any AthleteRepository
    private let raceRepository: any RaceRepository
    private let planRepository: any TrainingPlanRepository
    private let planAutoAdjustmentService: any PlanAutoAdjustmentService
    private let widgetDataWriter: WidgetDataWriter

    // MARK: - State

    var athlete: Athlete?
    var races: [Race] = []
    var isLoading = false
    var error: String?
    var showingEditAthlete = false
    var showingAddRace = false
    var raceToEdit: Race?
    var planWasAutoAdjusted = false

    // MARK: - Init

    init(
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        planRepository: any TrainingPlanRepository,
        planAutoAdjustmentService: any PlanAutoAdjustmentService,
        widgetDataWriter: WidgetDataWriter
    ) {
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
        self.planRepository = planRepository
        self.planAutoAdjustmentService = planAutoAdjustmentService
        self.widgetDataWriter = widgetDataWriter
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            athlete = try await athleteRepository.getAthlete()
            races = try await raceRepository.getRaces()
        } catch {
            self.error = error.localizedDescription
            Logger.app.error("Failed to load profile: \(error)")
        }

        isLoading = false
    }

    // MARK: - Update Athlete

    func updateAthlete(_ athlete: Athlete) async {
        do {
            try await athleteRepository.updateAthlete(athlete)
            self.athlete = athlete
        } catch {
            self.error = error.localizedDescription
            Logger.app.error("Failed to update athlete: \(error)")
        }
    }

    // MARK: - Race CRUD

    func addRace(_ race: Race) async {
        do {
            try await raceRepository.saveRace(race)
            races.append(race)
            await updateWidgets()
            await triggerPlanAutoAdjustment()
        } catch {
            self.error = error.localizedDescription
            Logger.app.error("Failed to add race: \(error)")
        }
    }

    func updateRace(_ race: Race) async {
        do {
            try await raceRepository.updateRace(race)
            if let index = races.firstIndex(where: { $0.id == race.id }) {
                races[index] = race
            }
            await updateWidgets()
            await triggerPlanAutoAdjustment()
        } catch {
            self.error = error.localizedDescription
            Logger.app.error("Failed to update race: \(error)")
        }
    }

    func deleteRace(id: UUID) async {
        do {
            try await raceRepository.deleteRace(id: id)
            races.removeAll { $0.id == id }
            await updateWidgets()
            await triggerPlanAutoAdjustment()
        } catch {
            self.error = error.localizedDescription
            Logger.app.error("Failed to delete race: \(error)")
        }
    }

    private func triggerPlanAutoAdjustment() async {
        do {
            guard let plan = try await planRepository.getActivePlan(),
                  let athlete = try await athleteRepository.getAthlete(),
                  let targetRace = races.first(where: { $0.priority == .aRace }) else { return }

            let intermediateRaces = races.filter {
                $0.priority != .aRace && $0.date < targetRace.date
            }

            if let _ = try await planAutoAdjustmentService.adjustPlanIfNeeded(
                currentPlan: plan,
                currentRaces: intermediateRaces,
                athlete: athlete,
                targetRace: targetRace
            ) {
                planWasAutoAdjusted = true
            }
        } catch {
            Logger.app.error("Plan auto-adjustment failed: \(error)")
        }
    }

    private func updateWidgets() async {
        await widgetDataWriter.writeRaceCountdown()
        widgetDataWriter.reloadWidgets()
    }

    // MARK: - Computed

    var sortedRaces: [Race] {
        races.sorted { $0.date < $1.date }
    }

    var aRace: Race? {
        races.first { $0.priority == .aRace }
    }
}
