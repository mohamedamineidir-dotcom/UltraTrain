import Foundation
@testable import UltraTrain

final class MockClearAllDataUseCase: ClearAllDataUseCase, @unchecked Sendable {
    var shouldThrow = false
    var executeCalled = false

    func execute() async throws {
        if shouldThrow { throw DomainError.persistenceError(message: "Mock error") }
        executeCalled = true
    }
}
