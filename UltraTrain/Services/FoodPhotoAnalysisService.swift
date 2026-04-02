import Foundation
import UIKit
import os

actor FoodPhotoAnalysisService: FoodPhotoAnalysisServiceProtocol {
    private let logger = Logger(subsystem: "com.ultratrain", category: "FoodPhotoAnalysis")
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func analyzePhoto(_ imageData: Data) async throws -> [AnalyzedFoodItem] {
        let apiKey = AppConfiguration.OpenAI.apiKey
        guard !apiKey.isEmpty, apiKey != "YOUR_OPENAI_API_KEY_HERE" else {
            throw FoodPhotoAnalysisError.noApiKey
        }

        let base64Image = try resizeAndEncode(imageData)
        let requestBody = buildRequestBody(base64Image: base64Image)

        var request = URLRequest(url: URL(string: AppConfiguration.OpenAI.apiURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FoodPhotoAnalysisError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = parseAPIError(data: data, statusCode: httpResponse.statusCode)
            logger.error("OpenAI API error (\(httpResponse.statusCode)): \(errorMessage)")
            throw FoodPhotoAnalysisError.apiError(errorMessage)
        }

        let items = try parseResponse(data)
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

        let maxDim = AppConfiguration.OpenAI.maxImageDimension
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
            compressionQuality: AppConfiguration.OpenAI.jpegCompressionQuality
        ) else {
            throw FoodPhotoAnalysisError.imageEncodingFailed
        }

        return jpegData.base64EncodedString()
    }

    // MARK: - Request Building

    private func buildRequestBody(base64Image: String) -> [String: Any] {
        let systemPrompt = """
        You are a precise nutrition analysis expert. Analyze the food in the image and return \
        a JSON object with a single key "items" containing an array. Each item must have exactly \
        these fields: "name" (string, specific food name), "portionGrams" (number, estimated weight \
        in grams), "calories" (integer, total kcal), "carbsGrams" (number, grams), "proteinGrams" \
        (number, grams), "fatGrams" (number, grams). \
        Estimate portions based on visual cues like plate size, utensils, and food density. \
        Be specific with food names (e.g. "Grilled Chicken Breast" not just "Chicken"). \
        Return ONLY the JSON object, no other text.
        """

        return [
            "model": AppConfiguration.OpenAI.visionModel,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)",
                                "detail": "high"
                            ]
                        ],
                        [
                            "type": "text",
                            "text": "Identify all food items in this photo with estimated portions and nutritional values."
                        ]
                    ] as [[String: Any]]
                ] as [String: Any]
            ] as [[String: Any]],
            "max_tokens": AppConfiguration.OpenAI.maxTokens,
            "response_format": ["type": "json_object"]
        ]
    }

    // MARK: - Response Parsing

    private func parseResponse(_ data: Data) throws -> [AnalyzedFoodItem] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw FoodPhotoAnalysisError.invalidResponse
        }

        guard let contentData = content.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
            throw FoodPhotoAnalysisError.invalidResponse
        }

        // Support both {"items": [...]} and direct array
        let itemsArray: [[String: Any]]
        if let items = parsed["items"] as? [[String: Any]] {
            itemsArray = items
        } else if let items = parsed["food_items"] as? [[String: Any]] {
            itemsArray = items
        } else {
            throw FoodPhotoAnalysisError.invalidResponse
        }

        return itemsArray.compactMap { dict -> AnalyzedFoodItem? in
            guard let name = dict["name"] as? String else { return nil }
            return AnalyzedFoodItem(
                id: UUID(),
                name: name,
                portionGrams: (dict["portionGrams"] as? Double) ?? 100,
                calories: (dict["calories"] as? Int) ?? Int((dict["calories"] as? Double) ?? 0),
                carbsGrams: (dict["carbsGrams"] as? Double) ?? 0,
                proteinGrams: (dict["proteinGrams"] as? Double) ?? 0,
                fatGrams: (dict["fatGrams"] as? Double) ?? 0
            )
        }
    }

    // MARK: - Error Parsing

    private func parseAPIError(data: Data, statusCode: Int) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            return message
        }

        switch statusCode {
        case 401: return "Invalid API key. Check your OpenAI API key in settings."
        case 429: return "Rate limit exceeded. Please try again in a moment."
        case 500...599: return "OpenAI server error. Please try again."
        default: return "Request failed with status \(statusCode)."
        }
    }
}
