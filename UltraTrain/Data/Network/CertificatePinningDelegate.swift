import Foundation
import CryptoKit
import os

final class CertificatePinningDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {

    private let pinnedHost: String
    private let pinnedHashes: [String]

    init(
        pinnedHost: String = AppConfiguration.API.pinnedHost,
        pinnedHashes: [String] = AppConfiguration.API.certificatePinHashes
    ) {
        self.pinnedHost = pinnedHost
        self.pinnedHashes = pinnedHashes
        super.init()
    }

    nonisolated func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        #if DEBUG
        return (.performDefaultHandling, nil)
        #else
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              challenge.protectionSpace.host == pinnedHost,
              !pinnedHashes.isEmpty,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            return (.performDefaultHandling, nil)
        }

        guard let serverPublicKey = SecTrustCopyKey(serverTrust),
              let serverKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) as? Data else {
            Logger.security.error("Certificate pinning: failed to extract server public key")
            return (.cancelAuthenticationChallenge, nil)
        }

        let hash = SHA256.hash(data: serverKeyData)
        let hashBase64 = Data(hash).base64EncodedString()

        if pinnedHashes.contains(hashBase64) {
            let credential = URLCredential(trust: serverTrust)
            return (.useCredential, credential)
        }

        Logger.security.error("Certificate pinning: hash mismatch for \(self.pinnedHost)")
        return (.cancelAuthenticationChallenge, nil)
        #endif
    }
}
