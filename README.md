# UltraTrain

Training companion app for ultra trail runners. Generates personalized training plans with integrated nutrition, tracks runs with GPS, and predicts race finish times.

## Features

- **Personalized Training Plans** -- Periodized plans (base / build / peak / taper) adapted to your race distance, elevation, and fitness level
- **GPS Run Tracking** -- Live pace, distance, elevation, heart rate with Apple Watch integration and Live Activities on the lock screen
- **Race Finish Prediction** -- Dynamic time estimation using effort-based distance (Kilian's coefficient), updated as training progresses
- **Nutrition Planning** -- Race-day strategy with calorie, hydration, and electrolyte targets plus gut-training protocols
- **Training Load Monitoring** -- Fitness / fatigue / form tracking with acute-to-chronic workload ratio alerts
- **Social Features** -- Share runs, crew tracking, group challenges, activity feed
- **Strava Integration** -- Import and export runs
- **Apple Watch App** -- Standalone run tracking with phone connectivity
- **Widgets** -- iOS and watchOS home screen widgets for fitness trend, next session, race countdown
- **Safety** -- SOS alerts, fall detection, emergency contacts, safety timer

## Tech Stack

| Component | Technology |
|-----------|------------|
| iOS App | Swift 6, SwiftUI, iOS 17+ |
| Architecture | Clean Architecture + MVVM |
| Local Storage | SwiftData + CloudKit sync |
| Watch App | SwiftUI, watchOS 10+ |
| Widgets | WidgetKit + ActivityKit (Live Activities) |
| Backend | Vapor 4, PostgreSQL |
| Auth | JWT (15-min access tokens) + refresh token rotation + HMAC request signing |
| CI/CD | GitHub Actions (4 jobs: backend tests, SwiftLint, unit tests, UI tests) |
| Dependencies | SPM only (no CocoaPods, no Carthage) |
| Localization | English, French |

## Quick Start

```bash
# Clone
git clone https://github.com/mohamedamineidir-dotcom/UltraTrain.git
cd UltraTrain

# Install tools
brew install xcodegen swiftlint

# Create Secrets.xcconfig (required -- listed in .gitignore)
cat > Secrets.xcconfig << 'EOF'
STRAVA_CLIENT_ID = your_strava_client_id
STRAVA_CLIENT_SECRET = your_strava_client_secret
HMAC_SIGNING_SECRET = your_hmac_secret
EOF

# Generate Xcode project
xcodegen generate

# Open in Xcode
open UltraTrain.xcodeproj
```

See [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md) for full setup instructions including backend, simulator, and code signing.

## Project Structure

```
UltraTrain/
  App/              App entry point, configuration, dependency container
  Core/             Shared utilities, extensions, protocols, constants
  Domain/           Business logic (models, use cases, repository protocols, errors)
  Data/             Data layer (repositories, data sources, network, mappers)
  Presentation/     UI layer (28 feature modules, components, navigation, theme)
  Services/         App-level services (location, HealthKit, notifications, etc.)
  Shared/           Code shared between iOS and watchOS targets
  Resources/        Assets, localization, Info.plist

UltraTrainWatch/    watchOS companion app
UltraTrainWidgets/  iOS widget extension
UltraTrainWatchWidgets/  watchOS widget extension
Backend/            Vapor 4 server (PostgreSQL, JWT, APNs)
Tests/              Unit tests + UI tests (2,300+ test cases)
```

## Documentation

- [DEVELOPER_SETUP.md](DEVELOPER_SETUP.md) -- Local development setup
- [Backend/API.md](Backend/API.md) -- REST API reference (42 endpoints)
- [CLAUDE.md](CLAUDE.md) -- Architecture guide and coding conventions

## Running Tests

```bash
# Unit tests
xcodebuild test \
  -project UltraTrain.xcodeproj \
  -scheme UltraTrain \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:UltraTrainTests \
  CODE_SIGNING_ALLOWED=NO

# Backend tests
cd Backend && swift test
```

## License

Proprietary. All rights reserved.
