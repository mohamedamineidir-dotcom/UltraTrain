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
            // The server just rejected the current token with a 401 —
            // force a real refresh rather than re-checking local expiry
            // via getValidAccessToken(), which would return the SAME
            // token unchanged if the local clock still considers it
            // valid, retry with it, and 401 again. That silent no-op
            // retry is what surfaced as an "Invalid email or password"
            // error on completely unrelated screens (e.g. food-photo
            // analysis) whenever a slow request crossed the token's
            // expiry boundary while in flight.
            return try await self.authService.forceRefreshAccessToken()
        }

        refreshTask = task
        return try await task.value
    }

    private func clearRefreshTask() {
        refreshTask = nil
    }
}
