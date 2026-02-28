import Foundation
import Testing
@testable import UltraTrain

@Suite("BackgroundTaskService Tests")
struct BackgroundTaskServiceTests {

    @Test("HealthKit sync task identifier is correctly defined")
    func healthKitSyncId() {
        #expect(BackgroundTaskService.healthKitSyncId == "com.ultratrain.app.healthkit-sync")
    }

    @Test("Recovery calc task identifier is correctly defined")
    func recoveryCalcId() {
        #expect(BackgroundTaskService.recoveryCalcId == "com.ultratrain.app.recovery-calc")
    }

    @Test("Task identifiers are distinct")
    func taskIdentifiersAreDistinct() {
        #expect(BackgroundTaskService.healthKitSyncId != BackgroundTaskService.recoveryCalcId)
    }

    @Test("Service initializes with mock dependencies")
    func initialization() {
        // Should initialize without crashing
        _ = BackgroundTaskService(
            healthKitService: MockHealthKitService(),
            recoveryRepository: MockRecoveryRepository(),
            fitnessRepository: MockFitnessRepository(),
            fitnessCalculator: MockCalculateFitnessUseCase(),
            runRepository: MockRunRepository()
        )
    }

    @Test("Task identifiers use reverse-DNS format")
    func taskIdentifierFormat() {
        #expect(BackgroundTaskService.healthKitSyncId.hasPrefix("com.ultratrain.app."))
        #expect(BackgroundTaskService.recoveryCalcId.hasPrefix("com.ultratrain.app."))
    }
}
