import Vapor

struct PrivacyController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("privacy") { _ -> Response in
            let response = Response(status: .ok, body: .init(string: Self.privacyHTML))
            response.headers.replaceOrAdd(name: .contentType, value: "text/html; charset=utf-8")
            return response
        }

        routes.get("terms") { _ -> Response in
            let response = Response(status: .ok, body: .init(string: Self.termsHTML))
            response.headers.replaceOrAdd(name: .contentType, value: "text/html; charset=utf-8")
            return response
        }
    }

    // swiftlint:disable function_body_length

    private static let privacyHTML = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>UltraTrain — Privacy Policy</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 700px; margin: 40px auto; padding: 0 20px; line-height: 1.6; color: #222; }
            h1 { font-size: 1.8em; }
            h2 { font-size: 1.3em; margin-top: 2em; }
            p, li { font-size: 0.95em; }
            .updated { color: #666; font-size: 0.85em; }
        </style>
    </head>
    <body>
        <h1>UltraTrain Privacy Policy</h1>
        <p class="updated">Last updated: February 25, 2026</p>

        <h2>1. Introduction</h2>
        <p>UltraTrain ("we", "our", "the app") is a training companion for ultra trail runners. We take your privacy seriously. This policy explains what data we collect, how we use it, and your rights.</p>

        <h2>2. Data We Collect</h2>
        <h3>Data you provide</h3>
        <ul>
            <li><strong>Account information:</strong> email address and password (password is hashed and never stored in plain text).</li>
            <li><strong>Athlete profile:</strong> age, weight, height, resting heart rate, max heart rate, experience level, weekly running volume.</li>
            <li><strong>Race information:</strong> race names, dates, distances, and elevation data you enter.</li>
            <li><strong>Run notes:</strong> perceived exertion, terrain type, and free-text notes you add after runs.</li>
        </ul>

        <h3>Data collected automatically</h3>
        <ul>
            <li><strong>GPS location data:</strong> collected only during active run tracking, used to record your route, distance, and pace. We do not track your location outside of active runs.</li>
            <li><strong>Health data (via Apple HealthKit):</strong> heart rate, resting heart rate, workouts, and activity data. This data is read only with your explicit permission and is never sold or shared with advertisers.</li>
            <li><strong>Device token:</strong> used solely for sending push notifications you have opted into.</li>
        </ul>

        <h3>Data we do NOT collect</h3>
        <ul>
            <li>We do not collect advertising identifiers.</li>
            <li>We do not use third-party analytics SDKs.</li>
            <li>We do not sell, rent, or share your personal data with third parties for marketing purposes.</li>
        </ul>

        <h2>3. How We Use Your Data</h2>
        <ul>
            <li>Generate personalized training plans based on your fitness level and race goals.</li>
            <li>Track and analyze your running performance over time.</li>
            <li>Estimate finish times for your target races.</li>
            <li>Create nutrition plans tailored to your body weight and race distance.</li>
            <li>Send training reminders and race countdown notifications (if enabled).</li>
            <li>Sync your data across devices when you are signed in.</li>
        </ul>

        <h2>4. Apple HealthKit Data</h2>
        <p>We comply with Apple's HealthKit guidelines:</p>
        <ul>
            <li>HealthKit data is used exclusively to enhance your training experience.</li>
            <li>HealthKit data is <strong>never</strong> used for advertising, shared with third parties, or sold.</li>
            <li>HealthKit data is not stored on our servers. It is queried on-device and displayed locally.</li>
            <li>You can revoke HealthKit access at any time in iOS Settings > Health > Data Access.</li>
        </ul>

        <h2>5. Data Storage & Security</h2>
        <ul>
            <li>Your data is stored locally on your device using encrypted storage (iOS Data Protection).</li>
            <li>When synced, data is transmitted over HTTPS with certificate pinning.</li>
            <li>Server-side data is stored in a PostgreSQL database with encrypted connections.</li>
            <li>Authentication tokens are stored in the iOS Keychain, the most secure storage on the device.</li>
            <li>Passwords are hashed using bcrypt before storage — we never store plain-text passwords.</li>
        </ul>

        <h2>6. Third-Party Services</h2>
        <ul>
            <li><strong>Strava (optional):</strong> if you connect your Strava account, we share run data (GPS track, distance, duration) with Strava at your request. You can disconnect at any time.</li>
            <li><strong>Apple WeatherKit:</strong> we request weather forecasts for your run locations. No personal data is shared with Apple beyond the location coordinates.</li>
            <li><strong>Resend:</strong> used to deliver email verification and password reset emails. Only your email address is shared.</li>
        </ul>

        <h2>7. Data Retention</h2>
        <p>Your data is retained as long as your account is active. You can delete your account at any time from Settings, which permanently removes all your data from our servers within 30 days.</p>

        <h2>8. Your Rights</h2>
        <p>You have the right to:</p>
        <ul>
            <li>Access all data we hold about you (export from Settings).</li>
            <li>Correct inaccurate data (edit your profile).</li>
            <li>Delete your account and all associated data.</li>
            <li>Revoke permissions (HealthKit, Location, Notifications) at any time.</li>
        </ul>

        <h2>9. Children's Privacy</h2>
        <p>UltraTrain is not intended for children under 13. We do not knowingly collect data from children.</p>

        <h2>10. Changes to This Policy</h2>
        <p>We may update this policy from time to time. We will notify you of material changes via the app or email.</p>

        <h2>11. Contact</h2>
        <p>For privacy questions or data requests, contact us at: <strong>privacy@ultratrain.app</strong></p>
    </body>
    </html>
    """

    private static let termsHTML = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>UltraTrain — Terms of Service</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 700px; margin: 40px auto; padding: 0 20px; line-height: 1.6; color: #222; }
            h1 { font-size: 1.8em; }
            h2 { font-size: 1.3em; margin-top: 2em; }
            p, li { font-size: 0.95em; }
            .updated { color: #666; font-size: 0.85em; }
        </style>
    </head>
    <body>
        <h1>UltraTrain — Terms of Service</h1>
        <p class="updated">Last updated: February 25, 2026</p>

        <h2>1. Acceptance</h2>
        <p>By using UltraTrain, you agree to these terms. If you do not agree, do not use the app.</p>

        <h2>2. Service Description</h2>
        <p>UltraTrain provides training plan generation, run tracking, nutrition planning, and performance analysis for trail runners. The app is provided "as is" without warranties.</p>

        <h2>3. Health Disclaimer</h2>
        <p>UltraTrain is not a medical device. Training plans, nutrition advice, and performance estimates are for informational purposes only. Always consult a healthcare professional before starting a new training program, especially for ultra-distance events.</p>

        <h2>4. User Responsibilities</h2>
        <ul>
            <li>You are responsible for maintaining the security of your account credentials.</li>
            <li>You must provide accurate information in your athlete profile for safe training recommendations.</li>
            <li>You assume all risk associated with your training activities.</li>
        </ul>

        <h2>5. Acceptable Use</h2>
        <p>You agree not to misuse the service, attempt to access other users' data, or reverse-engineer the app.</p>

        <h2>6. Termination</h2>
        <p>You may delete your account at any time. We reserve the right to suspend accounts that violate these terms.</p>

        <h2>7. Contact</h2>
        <p>Questions about these terms: <strong>support@ultratrain.app</strong></p>
    </body>
    </html>
    """

    // swiftlint:enable function_body_length
}
