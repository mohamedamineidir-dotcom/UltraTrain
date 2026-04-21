import Foundation
import Testing
import SwiftData
@testable import UltraTrain

@Suite("SyncedNutritionRepository Tests", .serialized)
@MainActor
struct SyncedNutritionRepositoryTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            NutritionPlanSwiftDataModel.self,
            NutritionEntrySwiftDataModel.self,
            NutritionProductSwiftDataModel.self,
            NutritionPreferencesSwiftDataModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: config)
    }

    private func makeProduct(
        name: String = "Maurten Gel 100",
        type: ProductType = .gel,
        caloriesPerServing: Int = 100
    ) -> NutritionProduct {
        NutritionProduct(
            id: UUID(),
            name: name,
            type: type,
            caloriesPerServing: caloriesPerServing,
            carbsGramsPerServing: 25,
            sodiumMgPerServing: 30,
            caffeineMgPerServing: 0
        )
    }

    private func makeEntry(product: NutritionProduct? = nil) -> NutritionEntry {
        NutritionEntry(
            id: UUID(),
            product: product ?? makeProduct(),
            timingMinutes: 30,
            quantity: 1,
            notes: nil
        )
    }

    private func makePlan(
        id: UUID = UUID(),
        raceId: UUID = UUID(),
        caloriesPerHour: Int = 250,
        entries: [NutritionEntry]? = nil
    ) -> NutritionPlan {
        NutritionPlan(
            id: id,
            raceId: raceId,
            carbsPerHour: caloriesPerHour / 4,
            caloriesPerHour: caloriesPerHour,
            hydrationMlPerHour: 500,
            sodiumMgPerHour: 600,
            totalCaffeineMg: 0,
            entries: entries ?? [makeEntry()],
            gutTrainingSessionIds: []
        )
    }

    private func makeStubAPIClient() -> APIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [NutritionStubURLProtocol.self]
        let session = URLSession(configuration: config)
        return APIClient(
            baseURL: URL(string: "https://stub.test")!,
            session: session,
            authInterceptor: nil,
            retryInterceptor: RetryInterceptor(maxAttempts: 1)
        )
    }

    private func makeSUT(
        container: ModelContainer? = nil,
        authenticated: Bool = false
    ) throws -> (SyncedNutritionRepository, LocalNutritionRepository) {
        let cont = try container ?? makeContainer()
        let local = LocalNutritionRepository(modelContainer: cont)
        let auth = MockAuthService()
        auth.isLoggedIn = authenticated
        let remote = RemoteNutritionDataSource(apiClient: makeStubAPIClient())
        let syncService = NutritionSyncService(remote: remote, authService: auth)
        let sut = SyncedNutritionRepository(local: local, syncService: syncService)
        return (sut, local)
    }

    // MARK: - getNutritionPlan

    @Test("getNutritionPlan returns locally stored plan")
    func getNutritionPlanReturnsLocal() async throws {
        let (sut, local) = try makeSUT()
        let raceId = UUID()
        let plan = makePlan(raceId: raceId, caloriesPerHour: 300)
        try await local.saveNutritionPlan(plan)

        let result = try await sut.getNutritionPlan(for: raceId)

        #expect(result != nil)
        #expect(result?.raceId == raceId)
        #expect(result?.caloriesPerHour == 300)
    }

    @Test("getNutritionPlan returns nil when no local data and not authenticated")
    func getNutritionPlanReturnsNilWhenNoLocalAndNotAuth() async throws {
        let (sut, _) = try makeSUT(authenticated: false)

        let result = try await sut.getNutritionPlan(for: UUID())

        #expect(result == nil)
    }

    // MARK: - saveNutritionPlan

    @Test("saveNutritionPlan persists locally")
    func saveNutritionPlanPersistsLocally() async throws {
        let (sut, local) = try makeSUT()
        let raceId = UUID()
        let plan = makePlan(raceId: raceId, caloriesPerHour: 280)

        try await sut.saveNutritionPlan(plan)

        let saved = try await local.getNutritionPlan(for: raceId)
        #expect(saved != nil)
        #expect(saved?.caloriesPerHour == 280)
    }

    @Test("saveNutritionPlan replaces existing plan for same race")
    func saveNutritionPlanReplacesExisting() async throws {
        let (sut, local) = try makeSUT()
        let raceId = UUID()

        let plan1 = makePlan(raceId: raceId, caloriesPerHour: 200)
        try await sut.saveNutritionPlan(plan1)

        let plan2 = makePlan(raceId: raceId, caloriesPerHour: 350)
        try await sut.saveNutritionPlan(plan2)

        let fetched = try await local.getNutritionPlan(for: raceId)
        #expect(fetched?.caloriesPerHour == 350)
    }

    // MARK: - updateNutritionPlan

    @Test("updateNutritionPlan persists changes locally")
    func updateNutritionPlanPersistsLocally() async throws {
        let (sut, local) = try makeSUT()
        let planId = UUID()
        let raceId = UUID()
        let plan = makePlan(id: planId, raceId: raceId, caloriesPerHour: 250)
        try await local.saveNutritionPlan(plan)

        let updated = NutritionPlan(
            id: planId,
            raceId: raceId,
            carbsPerHour: 100,
            caloriesPerHour: 400,
            hydrationMlPerHour: 700,
            sodiumMgPerHour: 800,
            totalCaffeineMg: 0,
            entries: [],
            gutTrainingSessionIds: []
        )
        try await sut.updateNutritionPlan(updated)

        let fetched = try await local.getNutritionPlan(for: raceId)
        #expect(fetched?.caloriesPerHour == 400)
        #expect(fetched?.hydrationMlPerHour == 700)
    }

    // MARK: - Products (delegated to local)

    @Test("getProducts returns locally saved products")
    func getProductsReturnsLocal() async throws {
        let (sut, local) = try makeSUT()
        let product = makeProduct(name: "SiS Go Gel")
        try await local.saveProduct(product)

        let products = try await sut.getProducts()

        #expect(products.count == 1)
        #expect(products.first?.name == "SiS Go Gel")
    }

    @Test("saveProduct persists through synced repository")
    func saveProductPersists() async throws {
        let (sut, local) = try makeSUT()
        let product = makeProduct(name: "Tailwind Endurance")

        try await sut.saveProduct(product)

        let products = try await local.getProducts()
        #expect(products.count == 1)
        #expect(products.first?.name == "Tailwind Endurance")
    }

    // MARK: - Preferences (delegated to local)

    @Test("getNutritionPreferences returns default when none saved")
    func getPreferencesReturnsDefault() async throws {
        let (sut, _) = try makeSUT()

        let prefs = try await sut.getNutritionPreferences()
        #expect(prefs == .default)
    }

    @Test("saveNutritionPreferences persists through synced repository")
    func savePreferencesPersists() async throws {
        let (sut, local) = try makeSUT()
        var prefs = NutritionPreferences.default
        prefs.avoidCaffeine = true

        try await sut.saveNutritionPreferences(prefs)

        let fetched = try await local.getNutritionPreferences()
        #expect(fetched.avoidCaffeine == true)
    }
}

// MARK: - Stub URL Protocol

private final class NutritionStubURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("{}".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
