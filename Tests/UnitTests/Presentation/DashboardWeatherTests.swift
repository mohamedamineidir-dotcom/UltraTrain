import Foundation
import Testing
@testable import UltraTrain

@Suite("Dashboard Weather Integration Tests")
struct DashboardWeatherTests {

    private let athleteId = UUID()

    private func makeAthlete() -> Athlete {
        Athlete(
            id: athleteId,
            firstName: "Test",
            lastName: "Runner",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: .now)!,
            weightKg: 70,
            heightCm: 175,
            restingHeartRate: 50,
            maxHeartRate: 185,
            experienceLevel: .intermediate,
            weeklyVolumeKm: 50,
            longestRunKm: 30,
            preferredUnit: .metric
        )
    }

    private func makeSnapshot(
        temperatureCelsius: Double = 20,
        condition: WeatherConditionType = .clear
    ) -> WeatherSnapshot {
        WeatherSnapshot(
            temperatureCelsius: temperatureCelsius,
            apparentTemperatureCelsius: temperatureCelsius - 1,
            humidity: 0.5,
            windSpeedKmh: 10,
            windDirectionDegrees: 180,
            condition: condition,
            uvIndex: 3,
            precipitationChance: 0.1,
            symbolName: "sun.max.fill",
            capturedAt: .now,
            locationLatitude: 45.0,
            locationLongitude: 6.0
        )
    }

    @MainActor
    private func makeViewModel(
        athleteRepo: MockAthleteRepository = MockAthleteRepository(),
        raceRepo: MockRaceRepository = MockRaceRepository(),
        weatherService: MockWeatherService? = nil
    ) -> DashboardViewModel {
        DashboardViewModel(
            planRepository: MockTrainingPlanRepository(),
            runRepository: MockRunRepository(),
            athleteRepository: athleteRepo,
            fitnessRepository: MockFitnessRepository(),
            fitnessCalculator: MockCalculateFitnessUseCase(),
            raceRepository: raceRepo,
            finishTimeEstimator: MockEstimateFinishTimeUseCase(),
            finishEstimateRepository: MockFinishEstimateRepository(),
            healthKitService: MockHealthKitService(),
            recoveryRepository: MockRecoveryRepository(),
            weatherService: weatherService
        )
    }

    // MARK: - Weather Loading

    @Test("Load completes without weather service")
    @MainActor
    func loadWithoutWeatherService() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let vm = makeViewModel(athleteRepo: athleteRepo)

        await vm.load()

        #expect(vm.currentWeather == nil)
    }

    @Test("Weather error does not block dashboard load")
    @MainActor
    func weatherErrorDoesNotBlockLoad() async {
        let athleteRepo = MockAthleteRepository()
        athleteRepo.savedAthlete = makeAthlete()
        let weatherService = MockWeatherService()
        weatherService.shouldThrow = true
        let vm = makeViewModel(athleteRepo: athleteRepo, weatherService: weatherService)

        await vm.load()

        #expect(vm.isLoading == false)
        #expect(vm.currentWeather == nil)
    }

    // MARK: - WeatherSnapshot Equatable

    @Test("WeatherSnapshot equality works correctly")
    func snapshotEquality() {
        let now = Date.now
        let a = WeatherSnapshot(
            temperatureCelsius: 20,
            apparentTemperatureCelsius: 19,
            humidity: 0.5,
            windSpeedKmh: 10,
            windDirectionDegrees: 180,
            condition: .clear,
            uvIndex: 3,
            precipitationChance: 0.1,
            symbolName: "sun.max.fill",
            capturedAt: now,
            locationLatitude: 45.0,
            locationLongitude: 6.0
        )
        let b = WeatherSnapshot(
            temperatureCelsius: 20,
            apparentTemperatureCelsius: 19,
            humidity: 0.5,
            windSpeedKmh: 10,
            windDirectionDegrees: 180,
            condition: .clear,
            uvIndex: 3,
            precipitationChance: 0.1,
            symbolName: "sun.max.fill",
            capturedAt: now,
            locationLatitude: 45.0,
            locationLongitude: 6.0
        )
        #expect(a == b)
    }

    @Test("WeatherSnapshot inequality when condition differs")
    func snapshotInequality() {
        let a = makeSnapshot(condition: .clear)
        let b = makeSnapshot(condition: .rain)
        #expect(a != b)
    }

    // MARK: - DailyWeatherForecast

    @Test("DailyWeatherForecast equality works correctly")
    func dailyForecastEquality() {
        let date = Date.now
        let a = DailyWeatherForecast(
            date: date,
            highTemperatureCelsius: 25,
            lowTemperatureCelsius: 15,
            condition: .partlyCloudy,
            precipitationChance: 0.3,
            windSpeedKmh: 15,
            uvIndex: 5,
            symbolName: "cloud.sun.fill"
        )
        let b = DailyWeatherForecast(
            date: date,
            highTemperatureCelsius: 25,
            lowTemperatureCelsius: 15,
            condition: .partlyCloudy,
            precipitationChance: 0.3,
            windSpeedKmh: 15,
            uvIndex: 5,
            symbolName: "cloud.sun.fill"
        )
        #expect(a == b)
    }

    // MARK: - DomainError

    @Test("Weather unavailable error has correct description")
    func weatherUnavailableError() {
        let error = DomainError.weatherUnavailable(reason: "No location")
        #expect(error.localizedDescription.contains("Weather"))
    }
}
