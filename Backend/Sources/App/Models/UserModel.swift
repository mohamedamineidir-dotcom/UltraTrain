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

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, email: String, passwordHash: String) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
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
