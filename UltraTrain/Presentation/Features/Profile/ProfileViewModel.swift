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
    /// True while a logged PR is being persisted and the active plan's
    /// future sessions are being walked + their pace targets refreshed.
    /// The PR page observes this to render a blocking overlay so the
    /// athlete sees the work in flight.
    var isRecalibrating = false

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
                  let athlete = try await athleteRepository.getAthlete() else { return }
            // Two-A-race seasons: when multiple A-races exist, the LATEST
            // is the target; earlier A-races become priority-A intermediate
            // races (handled by IntermediateRaceHandler with full taper +
            // recovery). Single-A-race plans behave exactly as before.
            let aRacesByDate = races
                .filter { $0.priority == .aRace }
                .sorted { $0.date < $1.date }
            guard let targetRace = aRacesByDate.last else { return }
            let intermediateRaces = races.filter { race in
                race.id != targetRace.id && race.date < targetRace.date
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

    // MARK: - Post-Race Wizard

    var showingPostRaceWizard: Race?

    // MARK: - Computed

    var sortedRaces: [Race] {
        races.sorted { $0.date < $1.date }
    }

    var completedRaces: [Race] {
        sortedRaces.filter { $0.isCompleted }
    }

    var upcomingRaces: [Race] {
        sortedRaces.filter { !$0.isCompleted }
    }

    var pastUncompletedRaces: [Race] {
        sortedRaces.filter { !$0.isCompleted && $0.date < Date.now }
    }

    var aRace: Race? {
        races.first { $0.priority == .aRace }
    }

    // MARK: - Personal Records

    /// Persists a new (or updated) personal best on the athlete, then
    /// — if the new PR exceeds the athlete's current fitness estimate
    /// at that distance — recomputes the pace profile and walks every
    /// remaining session in the active road plan to refresh both the
    /// structured workout and the coach advice text.
    ///
    /// Returns the count of sessions actually updated, the PR page
    /// uses this to surface a "X sessions updated" summary. Returns 0
    /// when there's no active plan, no A-race, or the delta is too
    /// small to be worth a plan rewrite.
    @discardableResult
    func logPersonalBest(_ newPB: PersonalBest) async -> Int {
        guard var current = athlete else { return 0 }

        isRecalibrating = true
        defer { isRecalibrating = false }

        // Compare against the existing PR at this distance (if any) so
        // we can tell whether the new entry actually represents an
        // improvement. The athlete might be correcting an old entry
        // with a slower time; we still save it, but we don't burn the
        // plan rewrite cycles when nothing materially improved.
        let prior = current.personalBests.first { $0.distance == newPB.distance }
        let isImprovement = prior.map { newPB.timeSeconds < $0.timeSeconds } ?? true

        // Replace existing PR at this distance, or append.
        if let idx = current.personalBests.firstIndex(where: { $0.distance == newPB.distance }) {
            current.personalBests[idx] = newPB
        } else {
            current.personalBests.append(newPB)
        }

        do {
            try await athleteRepository.updateAthlete(current)
            athlete = current
        } catch {
            self.error = error.localizedDescription
            Logger.app.error("Failed to save personal best: \(error)")
            return 0
        }

        guard isImprovement else { return 0 }
        return await applyPaceRecalibration(athlete: current)
    }

    /// Recomputes the pace profile from the updated athlete and walks
    /// the remaining sessions of the active plan to refresh their
    /// targets. Split out so the PR-save path stays readable. Returns
    /// the count of touched sessions.
    private func applyPaceRecalibration(athlete: Athlete) async -> Int {
        do {
            guard var plan = try await planRepository.getActivePlan() else { return 0 }
            // Target A-race: when multiple A-races exist, the LATEST
            // is the season's target (same rule as triggerPlanAutoAdjustment).
            let aRaces = races.filter { $0.priority == .aRace }
                .sorted { $0.date < $1.date }
            guard let targetRace = aRaces.last, targetRace.raceType == .road else { return 0 }

            let goalTime: TimeInterval?
            switch targetRace.goalType {
            case .targetTime(let t): goalTime = t
            case .targetRanking:
                goalTime = targetRace.estimatedDuration(experience: athlete.experienceLevel) * 0.93
            case .finish: goalTime = nil
            }
            let newProfile = RoadPaceCalculator.paceProfile(
                goalTime: goalTime,
                raceDistanceKm: targetRace.distanceKm,
                personalBests: athlete.personalBests,
                vmaKmh: athlete.vmaKmh,
                experience: athlete.experienceLevel
            )

            // Start from the week AFTER the current one so the athlete's
            // in-progress week doesn't have its workouts reshuffled mid-week.
            let nextWeekIndex = (plan.currentWeekIndex ?? -1) + 1
            let fromWeekIndex = max(nextWeekIndex, 0)
            guard fromWeekIndex < plan.weeks.count else { return 0 }

            let updated = PaceProfileApplier.apply(
                to: &plan,
                fromWeekIndex: fromWeekIndex,
                profile: newProfile,
                targetRace: targetRace,
                athlete: athlete
            )

            if updated > 0 {
                try await planRepository.savePlan(plan)
                Logger.training.info("PR recalibration touched \(updated) sessions starting at week \(fromWeekIndex + 1)")
            }
            return updated
        } catch {
            self.error = error.localizedDescription
            Logger.app.error("PR recalibration failed: \(error)")
            return 0
        }
    }
}
