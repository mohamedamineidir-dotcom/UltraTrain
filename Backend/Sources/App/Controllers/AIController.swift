import Vapor

/// Server-side proxy for OpenAI vision calls. The API key lives ONLY here
/// (Railway env `OPENAI_API_KEY`) so it never ships inside the iOS app where it
/// would be extractable from the bundle. The app sends a resized base64 JPEG;
/// we forward it to OpenAI and return the parsed food items.
struct AIController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let ai = routes.grouped("ai").grouped(UserAuthMiddleware())
        // Vision calls are expensive — cap per user.
        let limited = ai.grouped(RateLimitMiddleware(maxRequests: 30, windowSeconds: 3600))
        limited.post("food-photo", use: analyzeFoodPhoto)
    }

    // MARK: - DTOs

    struct FoodPhotoRequest: Content {
        /// Base64-encoded JPEG (no `data:` prefix). The app resizes before sending.
        let image: String
        /// BCP-47 language code from the athlete's device locale (e.g. "fr").
        let languageCode: String
    }

    struct AnalyzedItem: Content {
        let name: String
        let portionGrams: Double
        let calories: Int
        let carbsGrams: Double
        let proteinGrams: Double
        let fatGrams: Double
    }

    struct FoodPhotoResponse: Content {
        let items: [AnalyzedItem]
    }

    // MARK: - Handler

    @Sendable
    func analyzeFoodPhoto(req: Request) async throws -> FoodPhotoResponse {
        _ = try req.userId  // require an authenticated user

        guard let apiKey = Environment.get("OPENAI_API_KEY"), !apiKey.isEmpty else {
            req.logger.error("AIController: OPENAI_API_KEY not configured")
            throw Abort(.serviceUnavailable, reason: "AI analysis is temporarily unavailable.")
        }

        let input = try req.content.decode(FoodPhotoRequest.self)
        // ~6MB base64 ≈ ~4.5MB JPEG; the app caps image dimension well under this.
        guard !input.image.isEmpty, input.image.count < 6_000_000 else {
            throw Abort(.badRequest, reason: "Invalid or oversized image.")
        }

        let languageDisplayName = languageName(forCode: input.languageCode)
        let systemPrompt = """
        You are a precise nutrition analysis expert. Analyze the food in the image and return \
        a JSON object with a single key "items" containing an array. Each item must have exactly \
        these fields: "name" (string, specific food name, written in \(languageDisplayName)), "portionGrams" \
        (number, estimated weight in grams), "calories" (integer, total kcal), "carbsGrams" (number, grams), \
        "proteinGrams" (number, grams), "fatGrams" (number, grams). \
        Estimate portions based on visual cues like plate size, utensils, and food density. \
        Be specific with food names (e.g. the \(languageDisplayName) equivalent of "Grilled Chicken Breast", \
        not just "Chicken"). \
        Return ONLY the JSON object, no other text.
        """

        let openAIBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": [
                    ["type": "image_url",
                     "image_url": ["url": "data:image/jpeg;base64,\(input.image)", "detail": "high"]],
                    ["type": "text",
                     "text": "Identify all food items in this photo with estimated portions and nutritional values."]
                ]]
            ],
            "max_tokens": 1024,
            "response_format": ["type": "json_object"]
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: openAIBody)

        let response = try await req.client.post("https://api.openai.com/v1/chat/completions") { out in
            out.headers.bearerAuthorization = BearerAuthorization(token: apiKey)
            out.headers.contentType = .json
            out.body = ByteBuffer(data: bodyData)
        }

        guard response.status == .ok, let buffer = response.body else {
            let detail = response.body.map { String(buffer: $0) } ?? "no body"
            req.logger.error("AIController: OpenAI returned \(response.status.code): \(detail)")
            throw Abort(.badGateway, reason: "AI analysis failed. Please try again.")
        }

        let items = try parseItems(Data(buffer: buffer), logger: req.logger)
        guard !items.isEmpty else {
            throw Abort(.unprocessableEntity, reason: "No food detected in the photo.")
        }
        return FoodPhotoResponse(items: items)
    }

    // MARK: - Language

    /// Maps the app's supported locales to a full language name — the
    /// vision model follows a plain English instruction like "written in
    /// French" far more reliably than a bare BCP-47 code such as "fr".
    private func languageName(forCode code: String) -> String {
        switch code.lowercased() {
        case "fr": "French"
        default: "English"
        }
    }

    // MARK: - Parsing

    private func parseItems(_ data: Data, logger: Logger) throws -> [AnalyzedItem] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String,
              let contentData = content.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any]
        else {
            logger.error("AIController: could not parse OpenAI response")
            throw Abort(.badGateway, reason: "AI analysis failed. Please try again.")
        }

        let raw = (parsed["items"] as? [[String: Any]]) ?? (parsed["food_items"] as? [[String: Any]]) ?? []
        return raw.compactMap { dict in
            guard let name = dict["name"] as? String else { return nil }
            let calories = (dict["calories"] as? Int) ?? Int((dict["calories"] as? Double) ?? 0)
            return AnalyzedItem(
                name: name,
                portionGrams: (dict["portionGrams"] as? Double) ?? 100,
                calories: calories,
                carbsGrams: (dict["carbsGrams"] as? Double) ?? 0,
                proteinGrams: (dict["proteinGrams"] as? Double) ?? 0,
                fatGrams: (dict["fatGrams"] as? Double) ?? 0
            )
        }
    }
}
