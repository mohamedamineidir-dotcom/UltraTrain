import Testing
import Foundation
@testable import UltraTrain

struct CertificatePinningDelegateTests {

    @Test func initWithCustomValues() {
        let delegate = CertificatePinningDelegate(
            pinnedHost: "example.com",
            pinnedHashes: ["abc123"]
        )
        // Should initialize without crashing
        #expect(delegate != nil)
    }

    @Test func initWithDefaults() {
        let delegate = CertificatePinningDelegate()
        #expect(delegate != nil)
    }
}
