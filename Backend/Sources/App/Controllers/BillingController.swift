import Vapor
import Fluent
import Crypto

/// Website Stripe billing: create a Checkout Session for an authenticated
/// (just-registered) web account, and receive Stripe's webhook confirming
/// payment so the account can be marked premium. Registered outside the
/// HMAC-protected `api` route group (same reasoning as `WebAuthController`)
/// — `create-checkout-session` relies on JWT auth only, and `webhook` is
/// called directly by Stripe's servers and verifies Stripe's own signature
/// scheme instead.
struct BillingController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let billing = routes.grouped("billing")
        billing.grouped(UserAuthMiddleware()).post("create-checkout-session", use: createCheckoutSession)
        billing.post("webhook", use: webhook)
    }

    // MARK: - DTOs

    struct CreateCheckoutSessionRequest: Content {
        let priceId: String
    }

    struct CreateCheckoutSessionResponse: Content {
        let url: String
    }

    // MARK: - Create Checkout Session

    @Sendable
    func createCheckoutSession(req: Request) async throws -> CreateCheckoutSessionResponse {
        let userId = try req.userId
        guard let user = try await UserModel.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        let input = try req.content.decode(CreateCheckoutSessionRequest.self)
        guard !input.priceId.isEmpty else {
            throw Abort(.badRequest, reason: "Missing priceId.")
        }

        guard let secretKey = Environment.get("STRIPE_SECRET_KEY"), !secretKey.isEmpty else {
            req.logger.error("Billing: STRIPE_SECRET_KEY not configured")
            throw Abort(.serviceUnavailable, reason: "Billing is temporarily unavailable.")
        }

        let customerId: String
        if let existing = user.stripeCustomerId, !existing.isEmpty {
            customerId = existing
        } else {
            customerId = try await createStripeCustomer(email: user.email, secretKey: secretKey, req: req)
            user.stripeCustomerId = customerId
            try await user.save(on: req.db)
        }

        let successUrl = Environment.get("WEB_CHECKOUT_SUCCESS_URL") ?? "https://ultratrain.app/checkout-success.html"
        let cancelUrl = Environment.get("WEB_CHECKOUT_CANCEL_URL") ?? "https://ultratrain.app/checkout.html"

        let params: [String: String] = [
            "mode": "subscription",
            "customer": customerId,
            "line_items[0][price]": input.priceId,
            "line_items[0][quantity]": "1",
            "success_url": successUrl + "?session_id={CHECKOUT_SESSION_ID}",
            "cancel_url": cancelUrl,
            "client_reference_id": userId.uuidString
        ]

        let response = try await stripePost(path: "checkout/sessions", params: params, secretKey: secretKey, req: req)
        guard let url = response["url"] as? String else {
            throw Abort(.badGateway, reason: "Could not start checkout. Please try again.")
        }
        return CreateCheckoutSessionResponse(url: url)
    }

    private func createStripeCustomer(email: String, secretKey: String, req: Request) async throws -> String {
        let response = try await stripePost(path: "customers", params: ["email": email], secretKey: secretKey, req: req)
        guard let id = response["id"] as? String else {
            throw Abort(.badGateway, reason: "Could not create billing customer.")
        }
        return id
    }

    /// Minimal Stripe REST client. Vapor's `req.client` already wraps
    /// AsyncHTTPClient (see `StravaIntegrationController`), so no extra
    /// dependency is needed for the handful of calls this integration makes.
    private func stripePost(
        path: String,
        params: [String: String],
        secretKey: String,
        req: Request
    ) async throws -> [String: Any] {
        let bodyString = params.map { key, value in
            "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value)"
        }.joined(separator: "&")

        let url = URI(string: "https://api.stripe.com/v1/\(path)")
        let response = try await req.client.post(url) { (out: inout ClientRequest) in
            out.headers.bearerAuthorization = BearerAuthorization(token: secretKey)
            out.headers.contentType = .urlEncodedForm
            out.body = ByteBuffer(string: bodyString)
        }

        guard let buffer = response.body else {
            throw Abort(.badGateway, reason: "Stripe returned an empty response.")
        }
        let data = Data(buffer: buffer)

        guard response.status == .ok else {
            let detail = String(decoding: data, as: UTF8.self)
            req.logger.error("Billing: Stripe \(path) call failed \(response.status.code): \(detail)")
            throw Abort(.badGateway, reason: "Billing request failed. Please try again.")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw Abort(.badGateway, reason: "Billing request failed. Please try again.")
        }
        return json
    }

    // MARK: - Webhook

    @Sendable
    func webhook(req: Request) async throws -> HTTPStatus {
        guard let webhookSecret = Environment.get("STRIPE_WEBHOOK_SECRET"), !webhookSecret.isEmpty else {
            req.logger.error("Billing: STRIPE_WEBHOOK_SECRET not configured")
            throw Abort(.serviceUnavailable)
        }
        guard let signatureHeader = req.headers.first(name: "Stripe-Signature") else {
            throw Abort(.badRequest, reason: "Missing Stripe-Signature header.")
        }

        // The body must be fully buffered before reading it raw, otherwise
        // a body split across multiple network reads silently comes back
        // nil/partial and signature verification fails for no visible reason
        // (same class of bug hit previously with the app's own HMAC middleware).
        _ = try await req.body.collect().get()
        guard let bodyBuffer = req.body.data else {
            throw Abort(.badRequest, reason: "Missing request body.")
        }
        let rawBody = Data(buffer: bodyBuffer)

        guard verifyStripeSignature(header: signatureHeader, payload: rawBody, secret: webhookSecret) else {
            req.logger.warning("Billing: webhook signature verification failed")
            throw Abort(.badRequest, reason: "Invalid signature.")
        }

        guard let json = try? JSONSerialization.jsonObject(with: rawBody) as? [String: Any],
              let type = json["type"] as? String,
              let dataObj = json["data"] as? [String: Any],
              let object = dataObj["object"] as? [String: Any] else {
            throw Abort(.badRequest, reason: "Malformed event.")
        }

        switch type {
        case "customer.subscription.created", "customer.subscription.updated":
            try await handleSubscriptionEvent(object, req: req)
        default:
            break // ignore events we don't act on
        }

        return .ok
    }

    private func handleSubscriptionEvent(_ object: [String: Any], req: Request) async throws {
        guard let customerId = object["customer"] as? String,
              let status = object["status"] as? String,
              let subscriptionId = object["id"] as? String else { return }

        guard let user = try await UserModel.query(on: req.db)
            .filter(\.$stripeCustomerId == customerId)
            .first() else {
            req.logger.warning("Billing: webhook for unknown Stripe customer \(customerId)")
            return
        }

        user.stripeSubscriptionId = subscriptionId

        if status == "active" || status == "trialing" {
            if let periodEnd = (object["current_period_end"] as? NSNumber)?.doubleValue {
                user.webPremiumUntil = Date(timeIntervalSince1970: periodEnd)
            }
        } else {
            // past_due, canceled, unpaid, incomplete_expired, etc. — fail closed
            user.webPremiumUntil = nil
        }

        try await user.save(on: req.db)
    }

    /// Verifies Stripe's webhook signature scheme: header is
    /// `t=<timestamp>,v1=<hex hmac>`, and the signed payload is
    /// `"<timestamp>.<raw body>"` HMAC-SHA256'd with the webhook secret.
    private func verifyStripeSignature(header: String, payload: Data, secret: String) -> Bool {
        var timestamp: String?
        var v1Signature: String?
        for pair in header.split(separator: ",") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            if parts[0] == "t" { timestamp = String(parts[1]) }
            if parts[0] == "v1" { v1Signature = String(parts[1]) }
        }
        guard let timestamp, let v1Signature, let expectedBytes = hexDecode(v1Signature) else { return false }

        let signedPayload = "\(timestamp).\(String(decoding: payload, as: UTF8.self))"
        let key = SymmetricKey(data: Data(secret.utf8))
        return HMAC<SHA256>.isValidAuthenticationCode(expectedBytes, authenticating: Data(signedPayload.utf8), using: key)
    }

    private func hexDecode(_ hex: String) -> [UInt8]? {
        guard hex.count % 2 == 0 else { return nil }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(hex.count / 2)
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
            bytes.append(byte)
            index = next
        }
        return bytes
    }
}
