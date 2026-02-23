import Vapor

struct DeviceTokenRequest: Content, Validatable {
    let deviceToken: String
    let platform: String

    static func validations(_ validations: inout Validations) {
        validations.add("deviceToken", as: String.self, is: !.empty)
        validations.add("platform", as: String.self, is: .in("ios", "android"))
    }
}

struct DeviceTokenResponse: Content {
    let message: String
}
