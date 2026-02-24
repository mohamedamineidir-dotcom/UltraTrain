import Vapor
import Fluent

struct FriendController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(UserAuthMiddleware())
        protected.get("friends", use: listFriends)
        protected.get("friends", "pending", use: listPending)
        protected.post("friends", "request", use: sendRequest)
        protected.put("friends", ":connectionId", "accept", use: acceptRequest)
        protected.put("friends", ":connectionId", "decline", use: declineRequest)
        protected.delete("friends", ":connectionId", use: removeFriend)
    }

    @Sendable
    func listFriends(req: Request) async throws -> [FriendConnectionResponse] {
        let userId = try req.userId

        let connections = try await FriendConnectionModel.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$requestor.$id == userId)
                group.filter(\.$recipient.$id == userId)
            }
            .filter(\.$status == "accepted")
            .sort(\.$createdAt, .descending)
            .all()

        return try await mapConnections(connections, currentUserId: userId, on: req.db)
    }

    @Sendable
    func listPending(req: Request) async throws -> [FriendConnectionResponse] {
        let userId = try req.userId

        // Show incoming pending requests (where I am the recipient)
        let connections = try await FriendConnectionModel.query(on: req.db)
            .filter(\.$recipient.$id == userId)
            .filter(\.$status == "pending")
            .sort(\.$createdAt, .descending)
            .all()

        return try await mapConnections(connections, currentUserId: userId, on: req.db)
    }

    @Sendable
    func sendRequest(req: Request) async throws -> Response {
        try FriendRequestRequest.validate(content: req)
        let body = try req.content.decode(FriendRequestRequest.self)
        let userId = try req.userId

        guard let recipientId = UUID(uuidString: body.recipientProfileId) else {
            throw Abort(.badRequest, reason: "Invalid recipient profile ID")
        }

        // Can't friend yourself
        guard recipientId != userId else {
            throw Abort(.badRequest, reason: "Cannot send friend request to yourself")
        }

        // Verify recipient exists
        guard try await UserModel.find(recipientId, on: req.db) != nil else {
            throw Abort(.notFound, reason: "User not found")
        }

        // Check for existing connection in either direction
        let existing = try await FriendConnectionModel.query(on: req.db)
            .group(.or) { group in
                group.group(.and) { and in
                    and.filter(\.$requestor.$id == userId)
                    and.filter(\.$recipient.$id == recipientId)
                }
                group.group(.and) { and in
                    and.filter(\.$requestor.$id == recipientId)
                    and.filter(\.$recipient.$id == userId)
                }
            }
            .first()

        if let existing {
            if existing.status == "accepted" {
                throw Abort(.conflict, reason: "Already friends")
            }
            if existing.status == "pending" {
                throw Abort(.conflict, reason: "Friend request already pending")
            }
        }

        let connection = FriendConnectionModel()
        connection.$requestor.id = userId
        connection.$recipient.id = recipientId
        connection.status = "pending"
        try await connection.save(on: req.db)

        let displayName = try await friendDisplayName(userId: recipientId, on: req.db)
        let response = FriendConnectionResponse(from: connection, currentUserId: userId, friendDisplayName: displayName)
        return try await response.encodeResponse(status: .created, for: req)
    }

    @Sendable
    func acceptRequest(req: Request) async throws -> FriendConnectionResponse {
        let userId = try req.userId
        let connection = try await findConnection(req: req)

        // Only the recipient can accept
        guard connection.$recipient.id == userId else {
            throw Abort(.forbidden, reason: "Only the recipient can accept a friend request")
        }

        guard connection.status == "pending" else {
            throw Abort(.badRequest, reason: "Request is not pending")
        }

        connection.status = "accepted"
        connection.acceptedAt = Date()
        try await connection.save(on: req.db)

        let friendId = connection.$requestor.id
        let displayName = try await friendDisplayName(userId: friendId, on: req.db)
        return FriendConnectionResponse(from: connection, currentUserId: userId, friendDisplayName: displayName)
    }

    @Sendable
    func declineRequest(req: Request) async throws -> FriendConnectionResponse {
        let userId = try req.userId
        let connection = try await findConnection(req: req)

        // Only the recipient can decline
        guard connection.$recipient.id == userId else {
            throw Abort(.forbidden, reason: "Only the recipient can decline a friend request")
        }

        guard connection.status == "pending" else {
            throw Abort(.badRequest, reason: "Request is not pending")
        }

        connection.status = "declined"
        try await connection.save(on: req.db)

        let friendId = connection.$requestor.id
        let displayName = try await friendDisplayName(userId: friendId, on: req.db)
        return FriendConnectionResponse(from: connection, currentUserId: userId, friendDisplayName: displayName)
    }

    @Sendable
    func removeFriend(req: Request) async throws -> HTTPStatus {
        let userId = try req.userId
        let connection = try await findConnection(req: req)

        // Either party can remove the friendship
        guard connection.$requestor.id == userId || connection.$recipient.id == userId else {
            throw Abort(.forbidden, reason: "Not authorized to remove this connection")
        }

        try await connection.delete(on: req.db)
        return .noContent
    }

    // MARK: - Helpers

    private func findConnection(req: Request) async throws -> FriendConnectionModel {
        guard let idStr = req.parameters.get("connectionId"),
              let connectionId = UUID(uuidString: idStr) else {
            throw Abort(.badRequest, reason: "Invalid connection ID")
        }

        guard let connection = try await FriendConnectionModel.find(connectionId, on: req.db) else {
            throw Abort(.notFound, reason: "Friend connection not found")
        }

        return connection
    }

    private func friendDisplayName(userId: UUID, on db: Database) async throws -> String {
        if let athlete = try await AthleteModel.query(on: db)
            .filter(\.$user.$id == userId)
            .first() {
            return athlete.displayName.isEmpty ? "\(athlete.firstName) \(athlete.lastName)" : athlete.displayName
        }
        return "Unknown"
    }

    private func mapConnections(_ connections: [FriendConnectionModel], currentUserId: UUID, on db: Database) async throws -> [FriendConnectionResponse] {
        var results: [FriendConnectionResponse] = []
        for connection in connections {
            let friendId = connection.$requestor.id == currentUserId ? connection.$recipient.id : connection.$requestor.id
            let displayName = try await friendDisplayName(userId: friendId, on: db)
            results.append(FriendConnectionResponse(from: connection, currentUserId: currentUserId, friendDisplayName: displayName))
        }
        return results
    }
}
