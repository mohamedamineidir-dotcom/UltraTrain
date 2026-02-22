import Foundation
import Testing
@testable import UltraTrain

@Suite("AuthToken Tests")
struct AuthTokenTests {

    private func makeToken(expiresAt: Date) -> AuthToken {
        AuthToken(
            accessToken: "access-abc",
            refreshToken: "refresh-xyz",
            expiresAt: expiresAt,
            userId: "user-123",
            email: "runner@ultratrain.app"
        )
    }

    // MARK: - Expiration

    @Test("Token expiring in 1 hour is not expired")
    func notExpiredWhenExpiresInOneHour() {
        let token = makeToken(expiresAt: Date().addingTimeInterval(3600))
        #expect(token.isExpired == false)
    }

    @Test("Token that expired 1 minute ago is expired")
    func expiredWhenOneMinuteAgo() {
        let token = makeToken(expiresAt: Date().addingTimeInterval(-60))
        #expect(token.isExpired == true)
    }

    @Test("Token expiring in 10 seconds is expired due to 30-second buffer")
    func expiredWithin30SecondBuffer() {
        let token = makeToken(expiresAt: Date().addingTimeInterval(10))
        #expect(token.isExpired == true)
    }

    // MARK: - Codable

    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let original = makeToken(expiresAt: Date(timeIntervalSince1970: 1_700_000_000))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let decoded = try decoder.decode(AuthToken.self, from: data)

        #expect(decoded.accessToken == original.accessToken)
        #expect(decoded.refreshToken == original.refreshToken)
        #expect(decoded.expiresAt == original.expiresAt)
        #expect(decoded.userId == original.userId)
        #expect(decoded.email == original.email)
    }
}
