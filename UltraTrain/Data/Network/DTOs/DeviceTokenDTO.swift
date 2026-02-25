import Foundation

struct DeviceTokenRequestDTO: Encodable, Sendable {
    let deviceToken: String
    let platform: String
}
