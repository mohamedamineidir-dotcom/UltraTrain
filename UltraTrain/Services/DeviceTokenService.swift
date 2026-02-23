import Foundation
import os

actor DeviceTokenService {

    private let apiClient: APIClient
    private var currentToken: String?
    private var hasSentToken = false

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func registerToken(_ token: String) {
        currentToken = token
        hasSentToken = false
        Logger.notification.info("Device token registered locally")
    }

    func sendPendingTokenIfNeeded() async {
        guard let token = currentToken, !hasSentToken else { return }
        do {
            let body = DeviceTokenRequestDTO(
                deviceToken: token,
                platform: "ios"
            )
            try await apiClient.requestVoid(
                path: "device-token",
                method: .put,
                body: body,
                requiresAuth: true
            )
            hasSentToken = true
            Logger.notification.info("Device token sent to backend")
        } catch {
            Logger.notification.error("Failed to send device token: \(error)")
        }
    }
}
