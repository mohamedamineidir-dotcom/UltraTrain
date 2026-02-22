import Vapor
import JWT

struct UserAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let authHeader = request.headers.bearerAuthorization else {
            throw Abort(.unauthorized, reason: "Missing authorization header")
        }

        let payload: UserPayload
        do {
            payload = try request.jwt.verify(authHeader.token, as: UserPayload.self)
        } catch {
            throw Abort(.unauthorized, reason: "Invalid or expired token")
        }

        request.storage[UserPayloadKey.self] = payload
        return try await next.respond(to: request)
    }
}

struct UserPayloadKey: StorageKey {
    typealias Value = UserPayload
}

extension Request {
    var userPayload: UserPayload {
        get throws {
            guard let payload = storage[UserPayloadKey.self] else {
                throw Abort(.unauthorized, reason: "Not authenticated")
            }
            return payload
        }
    }

    var userId: UUID {
        get throws {
            let payload = try userPayload
            guard let id = UUID(uuidString: payload.subject.value) else {
                throw Abort(.unauthorized, reason: "Invalid user ID in token")
            }
            return id
        }
    }
}
