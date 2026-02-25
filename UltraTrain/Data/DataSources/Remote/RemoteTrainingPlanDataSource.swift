import Foundation

final class RemoteTrainingPlanDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func uploadPlan(_ dto: TrainingPlanUploadRequestDTO) async throws -> TrainingPlanResponseDTO {
        try await apiClient.send(TrainingPlanEndpoints.Upload(body: dto))
    }

    func fetchPlan() async throws -> TrainingPlanResponseDTO {
        try await apiClient.send(TrainingPlanEndpoints.Fetch())
    }
}
