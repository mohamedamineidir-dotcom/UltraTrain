import CoreLocation
import Foundation
import os

enum RunState: Equatable {
    case notStarted
    case running
    case paused
    case finished
}

@Observable
@MainActor
final class ActiveRunViewModel {

    // MARK: - Dependencies

    private(set) var locationService: LocationService
    let healthKitService: any HealthKitServiceProtocol
    let runRepository: any RunRepository
    let planRepository: any TrainingPlanRepository
    let raceRepository: any RaceRepository
    private(set) var hapticService: any HapticServiceProtocol
    private(set) var widgetDataWriter: WidgetDataWriter
    let gearRepository: any GearRepository
    let weatherService: (any WeatherServiceProtocol)?

    // MARK: - Handlers

    let nutritionHandler: NutritionReminderHandler
    let racePacingHandler: RacePacingHandler
    let connectivityHandler: ConnectivityHandler
    let voiceCoachingHandler: VoiceCoachingHandler
    let intervalHandler: IntervalGuidanceHandler
    let safetyHandler: SafetyHandler?
    let courseGuidanceHandler: CourseGuidanceHandler?

    // MARK: - Config

    let athlete: Athlete
    let linkedSession: TrainingSession?
    let autoPauseEnabled: Bool
    let raceId: UUID?
    let saveToHealthEnabled: Bool
    let selectedGearIds: [UUID]

    // MARK: - State

    var runState: RunState = .notStarted
    var elapsedTime: TimeInterval = 0
    var pausedDuration: TimeInterval = 0
    var distanceKm: Double = 0
    var elevationGainM: Double = 0
    var elevationLossM: Double = 0
    var currentPace: String = "--:--"
    var currentHeartRate: Int?
    var trackPoints: [TrackPoint] = []
    var routeCoordinates: [CLLocationCoordinate2D] = []
    var error: String?
    var showSummary = false
    var isSaving = false
    var lastSavedRun: CompletedRun?
    var isAutoPaused = false
    var autoMatchedSession: SessionMatcher.MatchResult?
    var weatherAtStart: WeatherSnapshot?

    // MARK: - HR Zone State

    var liveZoneState: LiveHRZoneTracker.LiveZoneState?
    var activeDriftAlert: ZoneDriftAlertCalculator.ZoneDriftAlert?
    var lastDriftAlertDismissTime: Date?

    // MARK: - Internal State (used by extensions)

    var timerTask: Task<Void, Never>?
    var locationTask: Task<Void, Never>?
    var heartRateTask: Task<Void, Never>?
    var autoPauseTimer: TimeInterval = 0
    var pauseStartTime: Date?
    var runningAveragePace: Double = 0
    var lastKnownSpeed: Double = 0
    var arrivedCheckpointIdsForVoice: Set<UUID> = []

    // MARK: - Init

    init(
        locationService: LocationService,
        healthKitService: any HealthKitServiceProtocol,
        runRepository: any RunRepository,
        planRepository: any TrainingPlanRepository,
        raceRepository: any RaceRepository,
        nutritionRepository: any NutritionRepository,
        hapticService: any HapticServiceProtocol,
        connectivityService: PhoneConnectivityService? = nil,
        liveActivityService: any LiveActivityServiceProtocol = LiveActivityService(),
        widgetDataWriter: WidgetDataWriter? = nil,
        stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)? = nil,
        gearRepository: any GearRepository,
        finishEstimateRepository: any FinishEstimateRepository,
        weatherService: (any WeatherServiceProtocol)? = nil,
        athlete: Athlete,
        linkedSession: TrainingSession?,
        autoPauseEnabled: Bool,
        nutritionRemindersEnabled: Bool,
        nutritionAlertSoundEnabled: Bool,
        hydrationIntervalSeconds: TimeInterval = 1200,
        fuelIntervalSeconds: TimeInterval = 2700,
        electrolyteIntervalSeconds: TimeInterval = 0,
        smartRemindersEnabled: Bool = false,
        stravaAutoUploadEnabled: Bool = false,
        saveToHealthEnabled: Bool = false,
        pacingAlertsEnabled: Bool = true,
        raceId: UUID?,
        selectedGearIds: [UUID] = [],
        voiceCoachingService: (any VoiceCoachingServiceProtocol)? = nil,
        voiceCoachingConfig: VoiceCoachingConfig = VoiceCoachingConfig(),
        intervalWorkout: IntervalWorkout? = nil,
        emergencyContactRepository: (any EmergencyContactRepository)? = nil,
        motionService: (any MotionServiceProtocol)? = nil,
        safetyConfig: SafetyConfig = SafetyConfig(),
        raceCourseRoute: [TrackPoint]? = nil,
        raceCheckpoints: [Checkpoint]? = nil,
        raceCheckpointSplits: [CheckpointSplit]? = nil,
        raceTotalDistanceKm: Double? = nil
    ) {
        self.locationService = locationService
        self.healthKitService = healthKitService
        self.runRepository = runRepository
        self.planRepository = planRepository
        self.raceRepository = raceRepository
        self.hapticService = hapticService
        self.widgetDataWriter = widgetDataWriter ?? WidgetDataWriter(
            planRepository: planRepository,
            runRepository: runRepository,
            raceRepository: raceRepository
        )
        self.gearRepository = gearRepository
        self.weatherService = weatherService
        self.athlete = athlete
        self.linkedSession = linkedSession
        self.autoPauseEnabled = autoPauseEnabled
        self.raceId = raceId
        self.saveToHealthEnabled = saveToHealthEnabled
        self.selectedGearIds = selectedGearIds

        self.nutritionHandler = NutritionReminderHandler(
            nutritionRepository: nutritionRepository,
            hapticService: hapticService,
            isEnabled: nutritionRemindersEnabled,
            alertSoundEnabled: nutritionAlertSoundEnabled,
            hydrationInterval: hydrationIntervalSeconds,
            fuelInterval: fuelIntervalSeconds,
            electrolyteInterval: electrolyteIntervalSeconds,
            smartRemindersEnabled: smartRemindersEnabled
        )

        self.racePacingHandler = RacePacingHandler(
            raceRepository: raceRepository,
            runRepository: runRepository,
            finishEstimateRepository: finishEstimateRepository,
            hapticService: hapticService,
            athlete: athlete,
            pacingAlertsEnabled: pacingAlertsEnabled
        )

        self.connectivityHandler = ConnectivityHandler(
            connectivityService: connectivityService,
            liveActivityService: liveActivityService,
            stravaUploadQueueService: stravaUploadQueueService,
            stravaAutoUploadEnabled: stravaAutoUploadEnabled
        )

        self.voiceCoachingHandler = VoiceCoachingHandler(
            voiceService: voiceCoachingService ?? VoiceCoachingService(speechRate: voiceCoachingConfig.speechRate),
            config: voiceCoachingConfig
        )

        self.intervalHandler = IntervalGuidanceHandler(
            hapticService: hapticService,
            intervalWorkout: intervalWorkout
        )

        if let emergencyContactRepository {
            self.safetyHandler = SafetyHandler(
                emergencyContactRepository: emergencyContactRepository,
                motionService: motionService,
                hapticService: hapticService,
                config: safetyConfig
            )
        } else {
            self.safetyHandler = nil
        }

        if let route = raceCourseRoute, route.count >= 2 {
            self.courseGuidanceHandler = CourseGuidanceHandler(
                courseRoute: route,
                checkpoints: raceCheckpoints ?? [],
                checkpointSplits: raceCheckpointSplits,
                totalDistanceKm: raceTotalDistanceKm ?? RunStatisticsCalculator.totalDistanceKm(route)
            )
        } else {
            self.courseGuidanceHandler = nil
        }
    }

    // MARK: - Computed

    var formattedTime: String { RunStatisticsCalculator.formatDuration(elapsedTime) }
    var formattedPace: String { currentPace }

    var formattedDistance: String {
        String(format: "%.2f", UnitFormatter.distanceValue(distanceKm, unit: athlete.preferredUnit))
    }

    var formattedElevation: String {
        let value = UnitFormatter.elevationValue(elevationGainM, unit: athlete.preferredUnit)
        return String(format: "+%.0f %@", value, UnitFormatter.elevationShortLabel(athlete.preferredUnit))
    }

    var formattedTotalTime: String { RunStatisticsCalculator.formatDuration(elapsedTime + pausedDuration) }

    var isRaceModeActive: Bool { raceId != nil && racePacingHandler.isActive }
}
