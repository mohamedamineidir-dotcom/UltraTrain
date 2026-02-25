import Foundation

enum TrainingPlanEndpoints {

    struct Fetch: APIEndpoint {
        typealias RequestBody = EmptyRequestBody
        typealias ResponseBody = TrainingPlanResponseDTO
        var path: String { "/training-plan" }
        var method: HTTPMethod { .get }
    }

    struct Upload: APIEndpoint {
        typealias RequestBody = TrainingPlanUploadRequestDTO
        typealias ResponseBody = TrainingPlanResponseDTO
        let body: TrainingPlanUploadRequestDTO?
        var path: String { "/training-plan" }
        var method: HTTPMethod { .put }

        init(body: TrainingPlanUploadRequestDTO) {
            self.body = body
        }
    }
}
