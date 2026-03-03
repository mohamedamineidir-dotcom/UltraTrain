# Developer Setup Guide

## Prerequisites

- macOS 14+ (Sonoma or later)
- Xcode 16.2+
- Homebrew
- Apple Developer account (for device testing, HealthKit, CloudKit)

## 1. Install Tools

```bash
# xcodegen generates .xcodeproj from project.yml
brew install xcodegen

# SwiftLint enforces code style (required before committing)
brew install swiftlint
```

## 2. Configure Secrets

The app requires a `Secrets.xcconfig` file at the project root. This file is in `.gitignore` and must never be committed.

```bash
cat > Secrets.xcconfig << 'EOF'
STRAVA_CLIENT_ID = your_strava_client_id
STRAVA_CLIENT_SECRET = your_strava_client_secret
HMAC_SIGNING_SECRET = your_hmac_secret
EOF
```

For local development without Strava or HMAC, you can use empty values:

```bash
cat > Secrets.xcconfig << 'EOF'
STRAVA_CLIENT_ID =
STRAVA_CLIENT_SECRET =
HMAC_SIGNING_SECRET =
EOF
```

Get Strava credentials at https://www.strava.com/settings/api. The HMAC secret must match the backend's `HMAC_SECRET` environment variable.

## 3. Generate Xcode Project

```bash
xcodegen generate
```

Run this every time you add/remove source files or change `project.yml`. The generated `UltraTrain.xcodeproj` is in `.gitignore`.

## 4. Open and Build

```bash
open UltraTrain.xcodeproj
```

- Select the **UltraTrain** scheme
- Select a simulator (iPhone 17 Pro recommended)
- Build and run (Cmd+R)

## 5. Running Tests

### Unit Tests (2,300+ cases)

```bash
xcodebuild test \
  -project UltraTrain.xcodeproj \
  -scheme UltraTrain \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:UltraTrainTests \
  CODE_SIGNING_ALLOWED=NO
```

### UI Tests

```bash
xcodebuild test \
  -project UltraTrain.xcodeproj \
  -scheme UltraTrain \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:UltraTrainUITests \
  CODE_SIGNING_ALLOWED=NO
```

### SwiftLint

```bash
swiftlint lint
```

Warnings are expected. Errors must be zero before committing.

### Backend Tests

```bash
cd Backend
swift test
```

## 6. Backend (Local Development)

### Option A: Docker (recommended)

```bash
# Start PostgreSQL
docker run -d --name ultratrain-pg \
  -e POSTGRES_USER=ultratrain \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=ultratrain_dev \
  -p 5432:5432 \
  postgres:16
```

### Option B: Local PostgreSQL

```bash
brew install postgresql@16
brew services start postgresql@16
createdb ultratrain_dev
```

### Run the Backend

```bash
cd Backend

# Set environment variables
export DATABASE_URL="postgresql://ultratrain:password@localhost:5432/ultratrain_dev"
export JWT_SECRET="dev-secret-change-in-production"
export HMAC_SECRET="your_hmac_secret"

# Build and run
swift run
```

The backend starts at `http://localhost:8080`. Migrations run automatically on startup.

### Production Backend

The production backend is deployed on Railway:
`https://ultratrain-production.up.railway.app`

The iOS app points to this URL by default (see `AppConfiguration.swift`).

## 7. Simulator Notes

| Feature | Simulator Support |
|---------|-------------------|
| HealthKit | Not available. Features degrade gracefully. |
| GPS | Use Xcode: Debug > Simulate Location |
| Apple Watch | Use Watch Simulator paired with iPhone Simulator |
| CloudKit | Requires iCloud sign-in in Simulator Settings |
| Push Notifications | Not available. Use local notifications for testing. |
| Live Activities | Available in iOS 17+ simulator |
| Biometric Auth | Use Xcode: Features > Face ID > Enrolled/Matching |

## 8. Code Signing (Device Testing)

1. Open project settings in Xcode
2. Select the **UltraTrain** target
3. Under "Signing & Capabilities", select your team
4. Xcode will auto-manage provisioning profiles
5. Required capabilities: HealthKit, Push Notifications, Background Modes, iCloud (CloudKit), App Groups, Associated Domains

## 9. Project Configuration

| Setting | Value |
|---------|-------|
| iOS Deployment Target | 17.0 |
| watchOS Deployment Target | 10.0 |
| Swift Version | 6.0 |
| Strict Concurrency | Complete |
| Project Generator | xcodegen (`project.yml`) |

### Build Targets

| Target | Platform | Type |
|--------|----------|------|
| UltraTrain | iOS | Application |
| UltraTrainWatch | watchOS | Application |
| UltraTrainWidgets | iOS | App Extension |
| UltraTrainWatchWidgets | watchOS | App Extension |
| UltraTrainTests | iOS | Unit Test Bundle |
| UltraTrainUITests | iOS | UI Test Bundle |

## 10. Troubleshooting

| Problem | Solution |
|---------|----------|
| `No such module 'UltraTrain'` | Run `xcodegen generate` |
| SwiftData crash on launch | Delete app from simulator, re-run |
| CloudKit errors in console | Sign into iCloud in Simulator > Settings |
| Build error about Secrets | Create `Secrets.xcconfig` (step 2) |
| Tests fail with "no simulator" | Run `xcrun simctl list devices available` |
| `Scheme UltraTrain not found` | Run `xcodegen generate` to create shared scheme |
| Backend won't start | Check `DATABASE_URL` environment variable |
| Backend migration fails | Ensure PostgreSQL is running and database exists |
