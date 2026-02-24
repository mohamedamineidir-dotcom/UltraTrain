import Fluent
import Vapor

final class SharedRunRecipientModel: Model, Content, @unchecked Sendable {
    static let schema = "shared_run_recipients"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "shared_run_id")
    var sharedRun: SharedRunModel

    @Parent(key: "recipient_id")
    var recipient: UserModel

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}
}
