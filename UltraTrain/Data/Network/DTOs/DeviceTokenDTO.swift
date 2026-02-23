import Foundation

struct DeviceTokenRequestDTO: Encodable {
    let deviceToken: String
    let platform: String
}
