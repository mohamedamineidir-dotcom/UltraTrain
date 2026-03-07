import Foundation

enum ReferralEndpoints {

    struct GetMyCode: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = ReferralCodeResponseDTO
        var path: String { "/referral/me" }
        var method: HTTPMethod { .get }
    }

    struct ApplyCode: APIEndpoint {
        typealias RequestBody = ApplyReferralRequestDTO
        typealias ResponseBody = MessageResponseDTO
        let body: ApplyReferralRequestDTO?
        var path: String { "/referral/apply" }
        var method: HTTPMethod { .post }

        init(code: String) {
            self.body = ApplyReferralRequestDTO(code: code)
        }
    }
}
