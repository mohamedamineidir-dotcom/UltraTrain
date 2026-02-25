import Foundation

struct SafetyAlert: Identifiable, Sendable {
    let id: UUID
    var type: SafetyAlertType
    var triggeredAt: Date
    var latitude: Double?
    var longitude: Double?
    var message: String
    var status: SafetyAlertStatus
}
