import Fluent
import Vapor
@preconcurrency import JWT

final class UserModel: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    @OptionalField(key: "refresh_token_hash")
    var refreshTokenHash: String?

    @OptionalField(key: "device_token")
    var deviceToken: String?

    @OptionalField(key: "device_platform")
    var devicePlatform: String?

    @OptionalField(key: "apns_environment")
    var apnsEnvironment: String?

    @OptionalField(key: "reset_code_hash")
    var resetCodeHash: String?

    @OptionalField(key: "reset_code_expires_at")
    var resetCodeExpiresAt: Date?

    @Field(key: "is_email_verified")
    var isEmailVerified: Bool

    @OptionalField(key: "verification_code_hash")
    var verificationCodeHash: String?

    @OptionalField(key: "verification_code_expires_at")
    var verificationCodeExpiresAt: Date?

    @OptionalField(key: "referral_code")
    var referralCode: String?

    @OptionalField(key: "referred_by_user_id")
    var referredByUserId: UUID?

    @OptionalField(key: "apple_user_id")
    var appleUserId: String?

    @OptionalField(key: "google_user_id")
    var googleUserId: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, email: String, passwordHash: String, isEmailVerified: Bool = false) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.isEmailVerified = isEmailVerified
    }

    /// Generate an 8-character uppercase alphanumeric referral code (no ambiguous 0/O/1/I/L).
    static func generateReferralCode() -> String {
        let chars = Array("ABCDEFGHJKMNPQRSTUVWXYZ23456789")
        return String((0..<8).map { _ in chars.randomElement()! })
    }
}

struct UserPayload: JWTPayload, Sendable {
    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var email: String

    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}
