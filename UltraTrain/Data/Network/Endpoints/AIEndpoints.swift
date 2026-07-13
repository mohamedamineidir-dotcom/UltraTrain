import Foundation

enum AIEndpoints {

    /// Sends a resized base64 JPEG to the backend, which holds the OpenAI key
    /// and performs the vision analysis. Auth-required.
    struct AnalyzeFoodPhoto: APIEndpoint {
        typealias RequestBody = FoodPhotoRequestDTO
        typealias ResponseBody = FoodPhotoResponseDTO
        let body: FoodPhotoRequestDTO?
        var path: String { "/ai/food-photo" }
        var method: HTTPMethod { .post }

        init(base64Image: String, languageCode: String = Locale.current.language.languageCode?.identifier ?? "en") {
            self.body = FoodPhotoRequestDTO(image: base64Image, languageCode: languageCode)
        }
    }
}
