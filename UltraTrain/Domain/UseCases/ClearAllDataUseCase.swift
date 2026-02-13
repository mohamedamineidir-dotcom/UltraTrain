import Foundation

protocol ClearAllDataUseCase: Sendable {
    func execute() async throws
}
