import Foundation

final class RemoteTrainingPlanDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func uploadPlan(_ dto: TrainingPlanUploadRequestDTO) async throws -> TrainingPlanResponseDTO {
        try await apiClient.request(
            path: "/training-plan",
            method: .put,
            body: dto,
            requiresAuth: true
        )
    }

    func fetchPlan() async throws -> TrainingPlanResponseDTO {
        try await apiClient.request(
            path: "/training-plan",
            method: .get,
            requiresAuth: true
        )
    }
}
