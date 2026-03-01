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
            let environment = Self.detectAPNSEnvironment()
            try await apiClient.sendVoid(
                DeviceTokenEndpoints.Register(deviceToken: token, apnsEnvironment: environment)
            )
            hasSentToken = true
            Logger.notification.info("Device token sent to backend (environment: \(environment))")
        } catch {
            Logger.notification.error("Failed to send device token: \(error)")
        }
    }

    /// Detects whether the app is running in sandbox or production APNs environment.
    /// TestFlight and App Store builds have no embedded.mobileprovision and use production.
    /// Xcode/debug builds have a provisioning profile with aps-environment = development.
    private static func detectAPNSEnvironment() -> String {
        #if targetEnvironment(simulator)
        return "sandbox"
        #else
        guard let profileURL = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: profileURL) else {
            // No provisioning profile = TestFlight / App Store = production
            return "production"
        }

        let profileString = String(decoding: data, as: UTF8.self)

        guard let start = profileString.range(of: "<plist"),
              let end = profileString.range(of: "</plist>") else {
            return "production"
        }

        let plistData = Data(profileString[start.lowerBound..<end.upperBound].utf8)

        guard let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
              let entitlements = plist["Entitlements"] as? [String: Any],
              let apsEnvironment = (entitlements["aps-environment"] ?? entitlements["com.apple.developer.aps-environment"]) as? String else {
            return "production"
        }

        return apsEnvironment == "development" ? "sandbox" : "production"
        #endif
    }
}
