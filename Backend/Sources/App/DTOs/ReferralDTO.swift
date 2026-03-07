import Vapor

struct ReferralCodeResponse: Content {
    let referralCode: String
    let referralCount: Int
}

struct ApplyReferralRequest: Content, Validatable {
    let code: String

    static func validations(_ validations: inout Validations) {
        validations.add("code", as: String.self, is: .count(8...8) && .alphanumeric)
    }
}
