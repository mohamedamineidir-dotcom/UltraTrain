import Vapor

struct EmailService {
    private let app: Application

    init(app: Application) {
        self.app = app
    }

    func sendPasswordResetCode(to email: String, code: String) async {
        guard let apiKey = Environment.get("RESEND_API_KEY") else {
            app.logger.warning("EmailService: RESEND_API_KEY not set, skipping email. Code: \(code)")
            return
        }

        let fromEmail = Environment.get("FROM_EMAIL") ?? "noreply@ultratrain.app"

        let payload = ResendEmailPayload(
            from: fromEmail,
            to: [email],
            subject: "UltraTrain — Password Reset Code",
            html: """
            <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 480px; margin: 0 auto; padding: 20px;">
                <h2 style="color: #1a1a1a;">Password Reset</h2>
                <p>You requested a password reset for your UltraTrain account.</p>
                <p>Your reset code is:</p>
                <div style="background: #f0f0f0; padding: 16px; border-radius: 8px; text-align: center; margin: 16px 0;">
                    <span style="font-size: 32px; font-weight: bold; letter-spacing: 4px; color: #1a1a1a;">\(code)</span>
                </div>
                <p style="color: #666;">This code expires in 10 minutes.</p>
                <p style="color: #666; font-size: 14px;">If you didn't request this, you can safely ignore this email.</p>
            </div>
            """
        )

        do {
            var headers = HTTPHeaders()
            headers.add(name: .authorization, value: "Bearer \(apiKey)")
            headers.add(name: .contentType, value: "application/json")

            let response = try await app.client.post(
                URI(string: "https://api.resend.com/emails"),
                headers: headers,
                content: payload
            )

            if response.status == .ok || response.status == .created {
                app.logger.info("EmailService: reset code sent to \(email)")
            } else {
                let body = response.body.map { String(buffer: $0) } ?? "no body"
                app.logger.error("EmailService: Resend returned \(response.status): \(body)")
            }
        } catch {
            app.logger.error("EmailService: failed to send email: \(error)")
        }
    }
}

private struct ResendEmailPayload: Content {
    let from: String
    let to: [String]
    let subject: String
    let html: String
}
