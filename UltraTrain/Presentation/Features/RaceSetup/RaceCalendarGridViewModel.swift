import Foundation
import os.log

@Observable
@MainActor
final class RaceCalendarGridViewModel {
    private let raceRepository: any RaceRepository
    private let planRepository: any TrainingPlanRepository
    private let logger = Logger.training

    var races: [Race] = []
    var plan: TrainingPlan?
    var selectedDate: Date?
    var displayedMonth: Date = .now.startOfMonth
    var isLoading = false
    var error: String?
    var showingAddRace = false
    var raceToEdit: Race?

    init(
        raceRepository: any RaceRepository,
        planRepository: any TrainingPlanRepository
    ) {
        self.raceRepository = raceRepository
        self.planRepository = planRepository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let fetchedRaces = raceRepository.getRaces()
            async let fetchedPlan = planRepository.getActivePlan()
            races = try await fetchedRaces
            plan = try await fetchedPlan
        } catch {
            logger.error("Failed to load race calendar: \(error.localizedDescription)")
            self.error = "Failed to load data. Please try again."
        }
    }

    func addRace(_ race: Race) async {
        do {
            try await raceRepository.saveRace(race)
            races.append(race)
        } catch {
            logger.error("Failed to save race: \(error.localizedDescription)")
            self.error = "Failed to save race."
        }
    }

    func updateRace(_ race: Race) async {
        do {
            try await raceRepository.updateRace(race)
            if let index = races.firstIndex(where: { $0.id == race.id }) {
                races[index] = race
            }
        } catch {
            logger.error("Failed to update race: \(error.localizedDescription)")
            self.error = "Failed to update race."
        }
    }

    func deleteRace(id: UUID) async {
        do {
            try await raceRepository.deleteRace(id: id)
            races.removeAll { $0.id == id }
        } catch {
            logger.error("Failed to delete race: \(error.localizedDescription)")
            self.error = "Failed to delete race."
        }
    }

    // MARK: - Computed Lookups

    func phaseForDate(_ date: Date) -> TrainingPhase? {
        guard let plan else { return nil }
        return plan.weeks.first { week in
            date >= week.startDate.startOfDay && date <= week.endDate.startOfDay
        }?.phase
    }

    func raceForDate(_ date: Date) -> Race? {
        races.first { $0.date.isSameDay(as: date) }
    }

    func sessionsForDate(_ date: Date) -> [TrainingSession] {
        guard let plan else { return [] }
        return plan.weeks
            .flatMap(\.sessions)
            .filter { $0.date.isSameDay(as: date) }
    }

    var upcomingRaces: [Race] {
        let today = Date.now.startOfDay
        return races
            .filter { $0.date >= today }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Calendar Grid

    func daysInMonth(for date: Date) -> [Date?] {
        let calendar = Calendar.current
        let firstDay = date.startOfMonth
        let leadingBlanks = firstDay.weekdayIndex

        guard let range = calendar.range(of: .day, in: .month, for: firstDay) else {
            return []
        }

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            if let dayDate = calendar.date(bySetting: .day, value: day, of: firstDay) {
                days.append(dayDate)
            }
        }
        return days
    }

    func navigateMonth(by offset: Int) {
        displayedMonth = displayedMonth.adding(months: offset)
    }
}
