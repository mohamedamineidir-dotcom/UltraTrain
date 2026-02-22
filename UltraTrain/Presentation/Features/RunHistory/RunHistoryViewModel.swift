import Foundation
import os

enum RunTimePeriod: String, CaseIterable, Identifiable {
    case all = "All"
    case thisWeek = "Week"
    case thisMonth = "Month"
    case thisYear = "Year"
    case custom = "Custom"

    var id: String { rawValue }
}

enum RunSortOption: String, CaseIterable, Identifiable {
    case dateNewest = "Newest First"
    case dateOldest = "Oldest First"
    case distanceLongest = "Longest"
    case distanceShortest = "Shortest"
    case paceFastest = "Fastest Pace"
    case paceSlowest = "Slowest Pace"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .dateNewest, .dateOldest: return "calendar"
        case .distanceLongest, .distanceShortest: return "arrow.left.arrow.right"
        case .paceFastest, .paceSlowest: return "speedometer"
        }
    }
}

@Observable
@MainActor
final class RunHistoryViewModel {

    // MARK: - Dependencies

    private let runRepository: any RunRepository
    private let planRepository: (any TrainingPlanRepository)?
    private let gearRepository: (any GearRepository)?

    // MARK: - State

    var runs: [CompletedRun] = []
    var isLoading = false
    var error: String?
    var searchText: String = ""
    var selectedTimePeriod: RunTimePeriod = .all
    var sortOption: RunSortOption = .dateNewest
    var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    var customEndDate: Date = .now
    var advancedFilter = RunHistoryAdvancedFilter()
    var availableGear: [GearItem] = []
    var sessionTypeLookup: [UUID: SessionType] = [:]

    // MARK: - Init

    init(
        runRepository: any RunRepository,
        planRepository: (any TrainingPlanRepository)? = nil,
        gearRepository: (any GearRepository)? = nil
    ) {
        self.runRepository = runRepository
        self.planRepository = planRepository
        self.gearRepository = gearRepository
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            runs = try await runRepository.getRecentRuns(limit: 10000)
        } catch {
            self.error = error.localizedDescription
            Logger.tracking.error("Failed to load run history: \(error)")
        }

        if let gearRepository {
            do {
                availableGear = try await gearRepository.getGearItems()
            } catch {
                Logger.tracking.debug("Could not load gear for filters: \(error)")
            }
        }

        if let planRepository {
            do {
                if let plan = try await planRepository.getActivePlan() {
                    var lookup: [UUID: SessionType] = [:]
                    for week in plan.weeks {
                        for session in week.sessions {
                            lookup[session.id] = session.type
                        }
                    }
                    sessionTypeLookup = lookup
                }
            } catch {
                Logger.tracking.debug("Could not load plan for session type filters: \(error)")
            }
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

    // MARK: - Filtered & Sorted

    var filteredRuns: [CompletedRun] {
        var result = runs

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { $0.notes?.lowercased().contains(query) == true }
        }

        let now = Date.now
        switch selectedTimePeriod {
        case .all:
            break
        case .thisWeek:
            let weekStart = now.startOfWeek
            result = result.filter { $0.date >= weekStart }
        case .thisMonth:
            let calendar = Calendar.current
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            result = result.filter { $0.date >= monthStart }
        case .thisYear:
            let calendar = Calendar.current
            let yearStart = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
            result = result.filter { $0.date >= yearStart }
        case .custom:
            result = result.filter {
                $0.date >= customStartDate.startOfDay && $0.date <= customEndDate.adding(days: 1).startOfDay
            }
        }

        result = applyAdvancedFilters(to: result)

        switch sortOption {
        case .dateNewest: result.sort { $0.date > $1.date }
        case .dateOldest: result.sort { $0.date < $1.date }
        case .distanceLongest: result.sort { $0.distanceKm > $1.distanceKm }
        case .distanceShortest: result.sort { $0.distanceKm < $1.distanceKm }
        case .paceFastest: result.sort { $0.averagePaceSecondsPerKm < $1.averagePaceSecondsPerKm }
        case .paceSlowest: result.sort { $0.averagePaceSecondsPerKm > $1.averagePaceSecondsPerKm }
        }

        return result
    }

    // MARK: - Advanced Filters

    var activeFilterCount: Int { advancedFilter.activeFilterCount }

    var availableSessionTypes: [SessionType] {
        let typesInRuns = runs.compactMap { run -> SessionType? in
            guard let sessionId = run.linkedSessionId else { return nil }
            return sessionTypeLookup[sessionId]
        }
        return Array(Set(typesInRuns)).sorted { $0.rawValue < $1.rawValue }
    }

    private func applyAdvancedFilters(to runs: [CompletedRun]) -> [CompletedRun] {
        guard advancedFilter.isActive else { return runs }

        return runs.filter { run in
            if let min = advancedFilter.minDistanceKm, run.distanceKm < min { return false }
            if let max = advancedFilter.maxDistanceKm, run.distanceKm > max { return false }
            if let min = advancedFilter.minElevationM, run.elevationGainM < min { return false }
            if let max = advancedFilter.maxElevationM, run.elevationGainM > max { return false }

            if !advancedFilter.sessionTypes.isEmpty {
                guard let sessionId = run.linkedSessionId,
                      let sessionType = sessionTypeLookup[sessionId],
                      advancedFilter.sessionTypes.contains(sessionType) else {
                    return false
                }
            }

            if !advancedFilter.gearIds.isEmpty {
                let runGearSet = Set(run.gearIds)
                if runGearSet.isDisjoint(with: advancedFilter.gearIds) { return false }
            }

            if !advancedFilter.importSources.isEmpty {
                let source = importSource(for: run)
                if !advancedFilter.importSources.contains(source) { return false }
            }

            if !advancedFilter.activityTypes.isEmpty {
                if !advancedFilter.activityTypes.contains(run.activityType) { return false }
            }

            return true
        }
    }

    private func importSource(for run: CompletedRun) -> ImportSourceFilter {
        if run.isStravaImport { return .strava }
        if run.isHealthKitImport { return .healthKit }
        return .manual
    }

    // MARK: - Summary

    var filteredRunCount: Int { filteredRuns.count }

    var filteredTotalDistanceKm: Double {
        filteredRuns.reduce(0) { $0 + $1.distanceKm }
    }

    var filteredTotalElevationM: Double {
        filteredRuns.reduce(0) { $0 + $1.elevationGainM }
    }

    var filteredTotalDuration: TimeInterval {
        filteredRuns.reduce(0) { $0 + $1.duration }
    }
}
