import Foundation
import UIKit
import os

/// Food-photo nutrition analysis. The image is resized on-device, then sent to
/// the backend, which holds the OpenAI key and performs the vision call. The
/// key never ships in the app, so it can't be extracted from the bundle.
actor FoodPhotoAnalysisService: FoodPhotoAnalysisServiceProtocol {
    private let logger = Logger(subsystem: "com.ultratrain", category: "FoodPhotoAnalysis")
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func analyzePhoto(_ imageData: Data) async throws -> [AnalyzedFoodItem] {
        let base64Image = try resizeAndEncode(imageData)

        let response: FoodPhotoResponseDTO
        do {
            response = try await apiClient.send(AIEndpoints.AnalyzeFoodPhoto(base64Image: base64Image))
        } catch {
            logger.error("Food photo analysis failed: \(error.localizedDescription)")
            throw FoodPhotoAnalysisError.apiError(error.localizedDescription)
        }

        let items = response.items.map { dto in
            AnalyzedFoodItem(
                id: UUID(),
                name: dto.name,
                portionGrams: dto.portionGrams,
                calories: dto.calories,
                carbsGrams: dto.carbsGrams,
                proteinGrams: dto.proteinGrams,
                fatGrams: dto.fatGrams
            )
        }
        guard !items.isEmpty else {
            throw FoodPhotoAnalysisError.noFoodDetected
        }

        logger.info("Analyzed photo: found \(items.count) food items")
        return items
    }

    // MARK: - Image Processing

    private func resizeAndEncode(_ imageData: Data) throws -> String {
        guard let image = UIImage(data: imageData) else {
            throw FoodPhotoAnalysisError.imageEncodingFailed
        }

        let maxDim = AppConfiguration.FoodPhoto.maxImageDimension
        let resized: UIImage
        if max(image.size.width, image.size.height) > maxDim {
            let scale = maxDim / max(image.size.width, image.size.height)
            let newSize = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )
            let renderer = UIGraphicsImageRenderer(size: newSize)
            resized = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        } else {
            resized = image
        }

        guard let jpegData = resized.jpegData(
            compressionQuality: AppConfiguration.FoodPhoto.jpegCompressionQuality
        ) else {
            throw FoodPhotoAnalysisError.imageEncodingFailed
        }

        return jpegData.base64EncodedString()
    }
}
