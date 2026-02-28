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

        // Check all certificates in the chain (leaf + intermediates).
        // This way if the leaf cert rotates, the intermediate CA pin still matches.
        guard let certChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
            Logger.security.error("Certificate pinning: failed to read certificate chain")
            return (.cancelAuthenticationChallenge, nil)
        }

        var serverHashes: [String] = []

        for certificate in certChain {
            guard let publicKey = SecCertificateCopyKey(certificate),
                  let keyData = SecKeyCopyExternalRepresentation(publicKey, nil) as? Data else {
                continue
            }
            let hash = SHA256.hash(data: keyData)
            let hashBase64 = Data(hash).base64EncodedString()
            serverHashes.append(hashBase64)

            if pinnedHashes.contains(hashBase64) {
                let credential = URLCredential(trust: serverTrust)
                return (.useCredential, credential)
            }
        }

        Logger.security.error(
            "Certificate pinning: no hash matched for \(self.pinnedHost). Server hashes: \(serverHashes)"
        )
        return (.cancelAuthenticationChallenge, nil)
    }
}
