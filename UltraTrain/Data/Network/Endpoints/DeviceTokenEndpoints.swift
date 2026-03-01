import Foundation

enum DeviceTokenEndpoints {

    struct Register: APIEndpoint {
        typealias RequestBody = DeviceTokenRequestDTO
        typealias ResponseBody = EmptyResponseBody
        let body: DeviceTokenRequestDTO?
        var path: String { "device-token" }
        var method: HTTPMethod { .put }

        init(deviceToken: String, apnsEnvironment: String) {
            self.body = DeviceTokenRequestDTO(
                deviceToken: deviceToken,
                platform: "ios",
                apnsEnvironment: apnsEnvironment
            )
        }
    }
}
