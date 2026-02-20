import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard

    private let athleteRepository: any AthleteRepository
    private let raceRepository: any RaceRepository
    private let planRepository: any TrainingPlanRepository
    private let planGenerator: any GenerateTrainingPlanUseCase
    private let nutritionRepository: any NutritionRepository
    private let nutritionGenerator: any GenerateNutritionPlanUseCase
    private let runRepository: any RunRepository
    private let locationService: LocationService
    private let fitnessRepository: any FitnessRepository
    private let fitnessCalculator: any CalculateFitnessUseCase
    private let finishTimeEstimator: any EstimateFinishTimeUseCase
    private let appSettingsRepository: any AppSettingsRepository
    private let clearAllDataUseCase: any ClearAllDataUseCase
    private let healthKitService: any HealthKitServiceProtocol
    private let hapticService: any HapticServiceProtocol
    private let trainingLoadCalculator: any CalculateTrainingLoadUseCase
    private let sessionNutritionAdvisor: any SessionNutritionAdvisor
    private let connectivityService: PhoneConnectivityService?
    private let widgetDataWriter: WidgetDataWriter
    private let exportService: any ExportServiceProtocol
    private let runImportUseCase: any RunImportUseCase
    private let stravaAuthService: any StravaAuthServiceProtocol
    private let stravaUploadService: (any StravaUploadServiceProtocol)?
    private let stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)?
    private let stravaImportService: (any StravaImportServiceProtocol)?
    private let notificationService: any NotificationServiceProtocol
    private let biometricAuthService: any BiometricAuthServiceProtocol
    private let gearRepository: any GearRepository
    private let finishEstimateRepository: any FinishEstimateRepository
    private let planAutoAdjustmentService: any PlanAutoAdjustmentService

    init(
        athleteRepository: any AthleteRepository,
        raceRepository: any RaceRepository,
        planRepository: any TrainingPlanRepository,
        planGenerator: any GenerateTrainingPlanUseCase,
        nutritionRepository: any NutritionRepository,
        nutritionGenerator: any GenerateNutritionPlanUseCase,
        runRepository: any RunRepository,
        locationService: LocationService,
        fitnessRepository: any FitnessRepository,
        fitnessCalculator: any CalculateFitnessUseCase,
        finishTimeEstimator: any EstimateFinishTimeUseCase,
        appSettingsRepository: any AppSettingsRepository,
        clearAllDataUseCase: any ClearAllDataUseCase,
        healthKitService: any HealthKitServiceProtocol,
        hapticService: any HapticServiceProtocol,
        trainingLoadCalculator: any CalculateTrainingLoadUseCase,
        sessionNutritionAdvisor: any SessionNutritionAdvisor,
        connectivityService: PhoneConnectivityService? = nil,
        widgetDataWriter: WidgetDataWriter,
        exportService: any ExportServiceProtocol,
        runImportUseCase: any RunImportUseCase,
        stravaAuthService: any StravaAuthServiceProtocol,
        stravaUploadService: (any StravaUploadServiceProtocol)? = nil,
        stravaUploadQueueService: (any StravaUploadQueueServiceProtocol)? = nil,
        stravaImportService: (any StravaImportServiceProtocol)? = nil,
        notificationService: any NotificationServiceProtocol,
        biometricAuthService: any BiometricAuthServiceProtocol,
        gearRepository: any GearRepository,
        finishEstimateRepository: any FinishEstimateRepository,
        planAutoAdjustmentService: any PlanAutoAdjustmentService
    ) {
        self.athleteRepository = athleteRepository
        self.raceRepository = raceRepository
        self.planRepository = planRepository
        self.planGenerator = planGenerator
        self.nutritionRepository = nutritionRepository
        self.nutritionGenerator = nutritionGenerator
        self.runRepository = runRepository
        self.locationService = locationService
        self.fitnessRepository = fitnessRepository
        self.fitnessCalculator = fitnessCalculator
        self.finishTimeEstimator = finishTimeEstimator
        self.appSettingsRepository = appSettingsRepository
        self.clearAllDataUseCase = clearAllDataUseCase
        self.healthKitService = healthKitService
        self.hapticService = hapticService
        self.trainingLoadCalculator = trainingLoadCalculator
        self.sessionNutritionAdvisor = sessionNutritionAdvisor
        self.connectivityService = connectivityService
        self.widgetDataWriter = widgetDataWriter
        self.exportService = exportService
        self.runImportUseCase = runImportUseCase
        self.stravaAuthService = stravaAuthService
        self.stravaUploadService = stravaUploadService
        self.stravaUploadQueueService = stravaUploadQueueService
        self.stravaImportService = stravaImportService
        self.notificationService = notificationService
        self.biometricAuthService = biometricAuthService
        self.gearRepository = gearRepository
        self.finishEstimateRepository = finishEstimateRepository
        self.planAutoAdjustmentService = planAutoAdjustmentService
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(
                selectedTab: $selectedTab,
                planRepository: planRepository,
                runRepository: runRepository,
                athleteRepository: athleteRepository,
                fitnessRepository: fitnessRepository,
                fitnessCalculator: fitnessCalculator,
                trainingLoadCalculator: trainingLoadCalculator,
                raceRepository: raceRepository,
                finishTimeEstimator: finishTimeEstimator,
                finishEstimateRepository: finishEstimateRepository,
                nutritionRepository: nutritionRepository,
                nutritionGenerator: nutritionGenerator
            )
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(Tab.dashboard)

            TrainingPlanView(
                planRepository: planRepository,
                athleteRepository: athleteRepository,
                raceRepository: raceRepository,
                planGenerator: planGenerator,
                nutritionRepository: nutritionRepository,
                sessionNutritionAdvisor: sessionNutritionAdvisor,
                widgetDataWriter: widgetDataWriter
            )
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }
                .tag(Tab.plan)

            RunTrackingLaunchView(
                athleteRepository: athleteRepository,
                planRepository: planRepository,
                runRepository: runRepository,
                raceRepository: raceRepository,
                locationService: locationService,
                healthKitService: healthKitService,
                appSettingsRepository: appSettingsRepository,
                nutritionRepository: nutritionRepository,
                hapticService: hapticService,
                connectivityService: connectivityService,
                widgetDataWriter: widgetDataWriter,
                exportService: exportService,
                runImportUseCase: runImportUseCase,
                stravaUploadService: stravaUploadService,
                stravaUploadQueueService: stravaUploadQueueService,
                stravaImportService: stravaImportService,
                stravaAuthService: stravaAuthService,
                gearRepository: gearRepository,
                finishTimeEstimator: finishTimeEstimator,
                finishEstimateRepository: finishEstimateRepository
            )
                .tabItem {
                    Label("Run", systemImage: "figure.run")
                }
                .tag(Tab.run)

            NutritionView(
                nutritionRepository: nutritionRepository,
                athleteRepository: athleteRepository,
                raceRepository: raceRepository,
                planRepository: planRepository,
                nutritionGenerator: nutritionGenerator
            )
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }
                .tag(Tab.nutrition)

            ProfileView(
                athleteRepository: athleteRepository,
                raceRepository: raceRepository,
                runRepository: runRepository,
                fitnessCalculator: fitnessCalculator,
                finishTimeEstimator: finishTimeEstimator,
                finishEstimateRepository: finishEstimateRepository,
                appSettingsRepository: appSettingsRepository,
                clearAllDataUseCase: clearAllDataUseCase,
                healthKitService: healthKitService,
                widgetDataWriter: widgetDataWriter,
                exportService: exportService,
                stravaAuthService: stravaAuthService,
                stravaUploadQueueService: stravaUploadQueueService,
                notificationService: notificationService,
                planRepository: planRepository,
                biometricAuthService: biometricAuthService,
                gearRepository: gearRepository,
                planAutoAdjustmentService: planAutoAdjustmentService,
                nutritionRepository: nutritionRepository,
                nutritionGenerator: nutritionGenerator
            )
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
    }
}

enum Tab: Hashable {
    case dashboard
    case plan
    case run
    case nutrition
    case profile
}
