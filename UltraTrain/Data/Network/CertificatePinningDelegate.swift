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
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              challenge.protectionSpace.host == pinnedHost,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            return (.performDefaultHandling, nil)
        }

        // When no pin hashes are configured, log a warning and allow the connection.
        // To extract the hash for your server, run:
        //   echo | openssl s_client -connect YOUR_HOST:443 2>/dev/null \
        //     | openssl x509 -pubkey -noout \
        //     | openssl pkey -pubin -outform DER \
        //     | openssl dgst -sha256 -binary \
        //     | base64
        // Then add the output to AppConfiguration.API.certificatePinHashes.
        guard !pinnedHashes.isEmpty else {
            Logger.security.warning(
                "Certificate pinning: no hashes configured for \(self.pinnedHost). Connection allowed but NOT pinned."
            )
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
    }
}
