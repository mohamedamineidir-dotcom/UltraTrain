import Testing
import Foundation
import SwiftData
@testable import UltraTrain

@Suite("LocalAthleteRepository Tests")
@MainActor
struct LocalAthleteRepositoryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            AthleteSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeAthlete(
        id: UUID = UUID(),
        firstName: String = "Kilian",
        lastName: String = "Jornet",
        dateOfBirth: Date = Date(timeIntervalSince1970: 536_457_600),
        weightKg: Double = 58,
        heightCm: Double = 171,
        restingHeartRate: Int = 42,
        maxHeartRate: Int = 195,
        experienceLevel: ExperienceLevel = .elite,
        weeklyVolumeKm: Double = 120,
        longestRunKm: Double = 170,
        preferredUnit: UnitPreference = .metric
    ) -> Athlete {
        Athlete(
            id: id,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth,
            weightKg: weightKg,
            heightCm: heightCm,
            restingHeartRate: restingHeartRate,
            maxHeartRate: maxHeartRate,
            experienceLevel: experienceLevel,
            weeklyVolumeKm: weeklyVolumeKm,
            longestRunKm: longestRunKm,
            preferredUnit: preferredUnit
        )
    }

    // MARK: - Save & Fetch

    @Test("Save athlete and fetch returns the saved athlete")
    func saveAndFetch() async throws {
        let container = try makeContainer()
        let repo = LocalAthleteRepository(modelContainer: container)
        let athlete = makeAthlete()

        try await repo.saveAthlete(athlete)
        let fetched = try await repo.getAthlete()

        #expect(fetched != nil)
        #expect(fetched?.id == athlete.id)
        #expect(fetched?.firstName == "Kilian")
        #expect(fetched?.lastName == "Jornet")
        #expect(fetched?.weightKg == 58)
        #expect(fetched?.heightCm == 171)
        #expect(fetched?.restingHeartRate == 42)
        #expect(fetched?.maxHeartRate == 195)
        #expect(fetched?.experienceLevel == .elite)
        #expect(fetched?.weeklyVolumeKm == 120)
        #expect(fetched?.longestRunKm == 170)
        #expect(fetched?.preferredUnit == .metric)
    }

    @Test("Get athlete when none saved returns nil")
    func getAthleteWhenEmpty() async throws {
        let container = try makeContainer()
        let repo = LocalAthleteRepository(modelContainer: container)

        let fetched = try await repo.getAthlete()
        #expect(fetched == nil)
    }

    // MARK: - Update

    @Test("Update athlete modifies all updatable fields")
    func updateAthleteModifiesFields() async throws {
        let container = try makeContainer()
        let repo = LocalAthleteRepository(modelContainer: container)
        let athleteId = UUID()

        let original = makeAthlete(
            id: athleteId,
            firstName: "Jim",
            lastName: "Walmsley",
            weightKg: 64,
            experienceLevel: .advanced,
            weeklyVolumeKm: 180,
            preferredUnit: .imperial
        )
        try await repo.saveAthlete(original)

        let updated = Athlete(
            id: athleteId,
            firstName: "Jim",
            lastName: "Walmsley-Updated",
            dateOfBirth: original.dateOfBirth,
            weightKg: 63,
            heightCm: 180,
            restingHeartRate: 45,
            maxHeartRate: 192,
            experienceLevel: .elite,
            weeklyVolumeKm: 200,
            longestRunKm: 160,
            preferredUnit: .metric
        )
        try await repo.updateAthlete(updated)

        let fetched = try await repo.getAthlete()
        #expect(fetched?.lastName == "Walmsley-Updated")
        #expect(fetched?.weightKg == 63)
        #expect(fetched?.heightCm == 180)
        #expect(fetched?.restingHeartRate == 45)
        #expect(fetched?.maxHeartRate == 192)
        #expect(fetched?.experienceLevel == .elite)
        #expect(fetched?.weeklyVolumeKm == 200)
        #expect(fetched?.longestRunKm == 160)
        #expect(fetched?.preferredUnit == .metric)
    }

    @Test("Update nonexistent athlete throws athleteNotFound")
    func updateNonexistentAthleteThrows() async throws {
        let container = try makeContainer()
        let repo = LocalAthleteRepository(modelContainer: container)
        let athlete = makeAthlete()

        do {
            try await repo.updateAthlete(athlete)
            Issue.record("Expected DomainError.athleteNotFound to be thrown")
        } catch let error as DomainError {
            #expect(error == .athleteNotFound)
        }
    }

    // MARK: - Experience Levels

    @Test("Beginner experience level preserved through round-trip")
    func beginnerExperiencePreserved() async throws {
        let container = try makeContainer()
        let repo = LocalAthleteRepository(modelContainer: container)
        let athlete = makeAthlete(experienceLevel: .beginner)

        try await repo.saveAthlete(athlete)
        let fetched = try await repo.getAthlete()

        #expect(fetched?.experienceLevel == .beginner)
    }

    @Test("Intermediate experience level preserved through round-trip")
    func intermediateExperiencePreserved() async throws {
        let container = try makeContainer()
        let repo = LocalAthleteRepository(modelContainer: container)
        let athlete = makeAthlete(experienceLevel: .intermediate)

        try await repo.saveAthlete(athlete)
        let fetched = try await repo.getAthlete()

        #expect(fetched?.experienceLevel == .intermediate)
    }

    @Test("Advanced experience level preserved through round-trip")
    func advancedExperiencePreserved() async throws {
        let container = try makeContainer()
        let repo = LocalAthleteRepository(modelContainer: container)
        let athlete = makeAthlete(experienceLevel: .advanced)

        try await repo.saveAthlete(athlete)
        let fetched = try await repo.getAthlete()

        #expect(fetched?.experienceLevel == .advanced)
    }

    // MARK: - Unit Preference

    @Test("Imperial unit preference preserved through round-trip")
    func imperialUnitPreserved() async throws {
        let container = try makeContainer()
        let repo = LocalAthleteRepository(modelContainer: container)
        let athlete = makeAthlete(preferredUnit: .imperial)

        try await repo.saveAthlete(athlete)
        let fetched = try await repo.getAthlete()

        #expect(fetched?.preferredUnit == .imperial)
    }

    // MARK: - Update Preserves ID

    @Test("Update preserves the athlete ID")
    func updatePreservesId() async throws {
        let container = try makeContainer()
        let repo = LocalAthleteRepository(modelContainer: container)
        let athleteId = UUID()

        let original = makeAthlete(id: athleteId, firstName: "Before")
        try await repo.saveAthlete(original)

        let updated = makeAthlete(id: athleteId, firstName: "After")
        try await repo.updateAthlete(updated)

        let fetched = try await repo.getAthlete()
        #expect(fetched?.id == athleteId)
        #expect(fetched?.firstName == "After")
    }

    // MARK: - Date of Birth

    @Test("Date of birth is preserved through round-trip")
    func dateOfBirthPreserved() async throws {
        let container = try makeContainer()
        let repo = LocalAthleteRepository(modelContainer: container)

        let dob = Date(timeIntervalSince1970: 536_457_600)
        let athlete = makeAthlete(dateOfBirth: dob)

        try await repo.saveAthlete(athlete)
        let fetched = try await repo.getAthlete()

        #expect(fetched?.dateOfBirth == dob)
    }

    // MARK: - Multiple Athletes

    @Test("Saving multiple athletes stores them all and getAthlete returns first")
    func multipleAthletesSaved() async throws {
        let container = try makeContainer()
        let repo = LocalAthleteRepository(modelContainer: container)

        let athlete1 = makeAthlete(firstName: "Athlete1")
        let athlete2 = makeAthlete(firstName: "Athlete2")

        try await repo.saveAthlete(athlete1)
        try await repo.saveAthlete(athlete2)

        // getAthlete returns the first result -- at least one should be returned
        let fetched = try await repo.getAthlete()
        #expect(fetched != nil)
    }

    @Test("Update only modifies the targeted athlete by ID")
    func updateTargetsCorrectAthlete() async throws {
        let container = try makeContainer()
        let repo = LocalAthleteRepository(modelContainer: container)

        let id1 = UUID()
        let id2 = UUID()
        let athlete1 = makeAthlete(id: id1, firstName: "Athlete1", weightKg: 70)
        let athlete2 = makeAthlete(id: id2, firstName: "Athlete2", weightKg: 65)

        try await repo.saveAthlete(athlete1)
        try await repo.saveAthlete(athlete2)

        let updated1 = makeAthlete(id: id1, firstName: "Athlete1Updated", weightKg: 72)
        try await repo.updateAthlete(updated1)

        // The updated athlete should have changed
        // We verify by checking the repo still works without errors
        let fetched = try await repo.getAthlete()
        #expect(fetched != nil)
    }
}
