import Testing
import Foundation
@testable import UltraTrain

struct CertificatePinningDelegateTests {

    @Test func initWithCustomValues() {
        // Should initialize without crashing
        _ = CertificatePinningDelegate(
            pinnedHost: "example.com",
            pinnedHashes: ["abc123"]
        )
    }

    @Test func initWithDefaults() {
        // Should initialize without crashing
        _ = CertificatePinningDelegate()
    }
}
