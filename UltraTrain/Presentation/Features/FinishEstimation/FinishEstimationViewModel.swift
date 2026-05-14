import Foundation
import os

@Observable
@MainActor
final class FinishEstimationViewModel {

    // MARK: - Dependencies

    private let finishTimeEstimator: any EstimateFinishTimeUseCase
    private let athleteRepository: any AthleteRepository
    private let runRepository: any RunRepository
    private let fitnessCalculator: any CalculateFitnessUseCase
    private let raceRepository: any RaceRepository
    private let finishEstimateRepository: any FinishEstimateRepository
    private let weatherService: (any WeatherServiceProtocol)?

    // MARK: - State

    let race: Race
    var estimate: FinishEstimate?
    var isLoading = false
    var error: String?
    var weatherImpact: WeatherImpactCalculator.WeatherImpact?
    var weatherSnapshot: WeatherSnapshot?
    var dailyForecast: DailyWeatherForecast?
    /// Exposed so the evolution graph can size its improvement curve
    /// per the athlete's tier (beginner improves more across a prep
    /// than elite). Falls back to .intermediate when athlete missing.
    var athleteExperience: ExperienceLevel = .intermediate

    // MARK: - Init

    init(
        race: Race,
        finishTimeEstimator: any EstimateFinishTimeUseCase,
        athleteRepository: any AthleteRepository,
        runRepository: any RunRepository,
        fitnessCalculator: any CalculateFitnessUseCase,
        raceRepository: any RaceRepository,
        finishEstimateRepository: any FinishEstimateRepository,
        weatherService: (any WeatherServiceProtocol)? = nil
    ) {
        self.race = race
        self.finishTimeEstimator = finishTimeEstimator
        self.athleteRepository = athleteRepository
        self.runRepository = runRepository
        self.fitnessCalculator = fitnessCalculator
        self.raceRepository = raceRepository
        self.finishEstimateRepository = finishEstimateRepository
        self.weatherService = weatherService
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        error = nil

        do {
            guard let athlete = try await athleteRepository.getAthlete() else {
                error = "Athlete profile not found"
                isLoading = false
                return
            }
            athleteExperience = athlete.experienceLevel

            // Day-0 prediction: athletes get a credible estimate from
            // their PBs alone before logging any training. The estimator
            // builds the pace anchor from runs when available, falls
            // back to PBs (Riegel + Kilian for trail), then to an
            // experience-level fallback. Range widens as data quality
            // decreases.
            let runs = try await runRepository.getRuns(for: athlete.id)

            var fitness: FitnessSnapshot?
            if !runs.isEmpty {
                do {
                    fitness = try await fitnessCalculator.execute(runs: runs, asOf: .now)
                } catch {
                    Logger.fitness.warning("Could not calculate fitness for estimation: \(error)")
                }
            }

            let calibrations = await buildCalibrations()
            await fetchRaceWeather()
            estimate = try await finishTimeEstimator.execute(
                athlete: athlete,
                race: race,
                recentRuns: runs,
                currentFitness: fitness,
                pastRaceCalibrations: calibrations,
                weatherImpact: weatherImpact
            )
        } catch {
            self.error = error.localizedDescription
            Logger.training.error("Failed to estimate finish time: \(error)")
        }

        isLoading = false
    }

    // MARK: - Calibration

    private func buildCalibrations() async -> [RaceCalibration] {
        do {
            let allRaces = try await raceRepository.getRaces()
            var calibrations: [RaceCalibration] = []
            for race in allRaces where race.actualFinishTime != nil {
                guard let saved = try await finishEstimateRepository.getEstimate(for: race.id) else { continue }
                calibrations.append(RaceCalibration(
                    raceId: race.id,
                    predictedTime: saved.expectedTime,
                    actualTime: race.actualFinishTime!,
                    raceDistanceKm: race.distanceKm,
                    raceElevationGainM: race.elevationGainM
                ))
            }
            return calibrations
        } catch {
            return []
        }
    }

    // MARK: - Weather

    private func fetchRaceWeather() async {
        guard let service = weatherService,
              let lat = race.locationLatitude,
              let lon = race.locationLongitude else { return }

        let daysUntilRace = Calendar.current.dateComponents([.day], from: .now, to: race.date).day ?? 0
        guard daysUntilRace >= 0 && daysUntilRace <= AppConfiguration.Weather.maxForecastDays else { return }

        do {
            if daysUntilRace <= 2 {
                let hourly = try await service.hourlyForecast(latitude: lat, longitude: lon, hours: 24)
                if let snapshot = hourly.first {
                    self.weatherSnapshot = snapshot
                    self.weatherImpact = WeatherImpactCalculator.calculateImpact(weather: snapshot)
                }
            } else {
                let daily = try await service.dailyForecast(latitude: lat, longitude: lon, days: daysUntilRace + 1)
                if let forecast = daily.last {
                    self.dailyForecast = forecast
                    self.weatherImpact = WeatherImpactCalculator.calculateImpact(forecast: forecast)
                }
            }
        } catch {
            Logger.weather.warning("Could not fetch race weather: \(error)")
        }
    }
}
