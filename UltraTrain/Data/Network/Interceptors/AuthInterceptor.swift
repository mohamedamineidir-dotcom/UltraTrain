import Foundation
import os

actor AuthInterceptor {
    private let authService: any AuthServiceProtocol
    private var refreshTask: Task<String, Error>?

    init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    func validToken() async throws -> String {
        try await authService.getValidAccessToken()
    }

    func handleUnauthorized() async throws -> String {
        if let existingTask = refreshTask {
            return try await existingTask.value
        }

        let task = Task<String, Error> { [weak self] in
            defer {
                Task { [weak self] in await self?.clearRefreshTask() }
            }
            guard let self else { throw DomainError.unauthorized }
            return try await self.authService.getValidAccessToken()
        }

        refreshTask = task
        return try await task.value
    }

    private func clearRefreshTask() {
        refreshTask = nil
    }
}
