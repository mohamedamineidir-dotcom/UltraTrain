import Foundation
import CryptoKit
import os

struct RequestSigningInterceptor: Sendable {
    private let secret: String

    init(secret: String = AppConfiguration.API.hmacSecret) {
        self.secret = secret
    }

    func sign(_ request: inout URLRequest) {
        guard !secret.isEmpty else {
            Logger.security.warning("HMAC signing secret is empty — skipping request signing")
            return
        }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let body = request.httpBody ?? Data()
        let payload = Data(timestamp.utf8) + body

        guard let keyData = secret.data(using: .utf8) else { return }
        let key = SymmetricKey(data: keyData)
        let signature = HMAC<SHA256>.authenticationCode(for: payload, using: key)
        let signatureBase64 = Data(signature).base64EncodedString()

        request.setValue(signatureBase64, forHTTPHeaderField: "X-Signature")
        request.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
    }
}
