import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct SessionDragData: Codable, Sendable, Transferable {
    let sessionId: UUID
    let weekIndex: Int
    let sessionIndex: Int

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}
