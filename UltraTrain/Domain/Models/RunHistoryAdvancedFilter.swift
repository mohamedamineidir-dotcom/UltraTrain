import Foundation

struct RunHistoryAdvancedFilter: Equatable, Sendable {
    var minDistanceKm: Double?
    var maxDistanceKm: Double?
    var minElevationM: Double?
    var maxElevationM: Double?
    var sessionTypes: Set<SessionType> = []
    var gearIds: Set<UUID> = []
    var importSources: Set<ImportSourceFilter> = []
    var activityTypes: Set<ActivityType> = []

    var isActive: Bool {
        activeFilterCount > 0
    }

    var activeFilterCount: Int {
        var count = 0
        if minDistanceKm != nil || maxDistanceKm != nil { count += 1 }
        if minElevationM != nil || maxElevationM != nil { count += 1 }
        if !sessionTypes.isEmpty { count += 1 }
        if !gearIds.isEmpty { count += 1 }
        if !importSources.isEmpty { count += 1 }
        if !activityTypes.isEmpty { count += 1 }
        return count
    }

    mutating func clearAll() {
        minDistanceKm = nil
        maxDistanceKm = nil
        minElevationM = nil
        maxElevationM = nil
        sessionTypes = []
        gearIds = []
        importSources = []
        activityTypes = []
    }
}
