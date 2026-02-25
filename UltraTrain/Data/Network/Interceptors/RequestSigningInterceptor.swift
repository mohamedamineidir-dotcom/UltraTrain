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

        var keyData = Data(secret.utf8)
        defer { keyData.resetBytes(in: 0..<keyData.count) }
        let key = SymmetricKey(data: keyData)
        var signatureData = Data(HMAC<SHA256>.authenticationCode(for: payload, using: key))
        defer { signatureData.resetBytes(in: 0..<signatureData.count) }
        let signatureBase64 = signatureData.base64EncodedString()

        request.setValue(signatureBase64, forHTTPHeaderField: "X-Signature")
        request.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
    }
}
