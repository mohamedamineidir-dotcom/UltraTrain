# CLAUDE.md — UltraTrain iOS App

Ultra trail running training app for iOS. All code contributions must follow these rules strictly.

---

## 0. User Context & Communication Rules

**The user is a beginner in iOS development.** When any setup is required (database, backend, certificates, provisioning profiles, Xcode configuration, third-party service accounts, environment variables, etc.):
- **STOP and ASK the user** before proceeding.
- **Explain step-by-step** what needs to be done and why.
- **Tell the user exactly what tool/access you need** and how they can provide it to you.
- **Never assume** the user has developer tools, accounts, or services already configured.
- **Provide terminal commands** the user can copy-paste when manual setup is needed.
- The user is willing and able to do anything — just guide them clearly.

---

## 1. Project Overview

- **App Name:** UltraTrain
- **Purpose:** Training companion for Ultra Trail runners — generates personalized training plans with integrated nutrition, tracks progress, and predicts race finish times.
- **Platform:** iOS (Swift, SwiftUI)
- **Min Target:** iOS 17.0
- **Architecture:** Clean Architecture + MVVM
- **Dependency Management:** Swift Package Manager (SPM) only — no CocoaPods, no Carthage
- **Language:** Swift 6 with strict concurrency checking enabled

### Core Features

1. **Athlete Profile & Onboarding**
   - Collect runner experience level (beginner / intermediate / advanced / elite)
   - Running history (weekly volume, longest run, previous races with times)
   - Physical data (age, weight, resting HR, max HR)
   - HealthKit integration for automatic data import

2. **Race Setup & Goal Definition**
   - Principal objective race: name, date, distance (km), total elevation gain (D+), total elevation loss (D-)
   - Goal type: finish, target time, target ranking
   - Intermediate races: optional B/C races scheduled before the main event, used as training milestones and fitness benchmarks
   - Race priority system: A-race (principal objective), B-race (important intermediate), C-race (training race)

3. **Personalized Training Plan Generation**
   - Plan built from race date backwards (periodization: base → build → peak → taper)
   - Adapts to athlete experience level and current fitness
   - Integrates intermediate races into the plan (taper before B-races, recovery after)
   - Weekly structure: long runs, intervals, tempo, vertical gain sessions, back-to-back long runs, recovery runs
   - Adjustable: athlete can swap/skip/reschedule sessions
   - Progressive overload with appropriate recovery weeks (3:1 or 2:1 cycles)

4. **Nutrition Plan (Integrated with Training)**
   - Race-day nutrition strategy: calories/hour, hydration, electrolytes based on race distance and expected duration
   - Training nutrition: pre-run, during-run, post-run recommendations per session type
   - Gut training protocol: practice race-day nutrition during long training runs
   - Product recommendations (gels, bars, drinks) with customizable preferences
   - Nutrition reminders during tracked runs

5. **Run Tracking & Progress Monitoring**
   - GPS tracking with live pace, distance, elevation, heart rate (via Apple Watch / HealthKit)
   - Auto-pause detection
   - Post-run analysis: splits, elevation profile, HR zones, pace vs. plan comparison
   - Training load tracking: weekly volume (km), elevation (D+), time, TSS-equivalent
   - Progress dashboard: fitness trend, fatigue, form (CTL/ATL/TSB simplified)
   - Plan adherence percentage

6. **Finish Time Estimation**
   - Algorithm inputs: athlete's current fitness (recent training data), race distance, race elevation gain, race terrain difficulty
   - Uses Kilian's coefficient or equivalent (adjusts flat-equivalent km based on elevation)
   - Compares with athlete's recent race results and long-run performances
   - Updates dynamically as training progresses and new data comes in
   - Displays predicted splits per checkpoint/aid station if race profile is known
   - Confidence interval (best case / expected / worst case)

7. **Race Calendar & Intermediate Races**
   - Visual calendar showing all registered races
   - Auto-adjusts training plan when intermediate races are added/removed
   - Post-race analysis for intermediate races feeds back into finish time prediction for A-race
   - Recovery protocol auto-inserted after each race

---

## 2. Project Structure

```
UltraTrain/
├── App/                        # App entry point, AppDelegate, SceneDelegate
│   ├── UltraTrainApp.swift
│   └── AppConfiguration.swift
├── Core/                       # Shared kernel — no external dependencies
│   ├── Extensions/
│   ├── Protocols/
│   ├── Constants/
│   └── Utilities/
├── Domain/                     # Business logic layer — pure Swift, zero imports
│   ├── Models/                 # Domain entities (Run, TrainingPlan, Athlete, etc.)
│   ├── UseCases/               # Single-responsibility use cases
│   ├── Repositories/           # Repository protocols (interfaces only)
│   └── Errors/                 # Domain-specific error types
├── Data/                       # Data layer — implements Domain interfaces
│   ├── Repositories/           # Concrete repository implementations
│   ├── DataSources/
│   │   ├── Remote/             # API clients, DTOs, request/response mapping
│   │   └── Local/              # SwiftData / CoreData models, persistence
│   ├── Mappers/                # DTO <-> Domain entity mappers
│   └── Network/                # Networking stack (URLSession-based)
├── Presentation/               # UI layer — SwiftUI views + ViewModels
│   ├── Features/               # Feature modules (one folder per feature)
│   │   ├── Onboarding/          # Athlete profile setup, experience level
│   │   ├── Dashboard/           # Home screen, progress overview, fitness trend
│   │   ├── RaceSetup/           # A/B/C race configuration, race calendar
│   │   ├── TrainingPlan/        # Plan view, weekly schedule, session details
│   │   ├── RunTracking/         # Live GPS tracking, active run screen
│   │   ├── RunAnalysis/         # Post-run stats, splits, HR zones
│   │   ├── Nutrition/           # Nutrition plans, race-day strategy, gut training
│   │   ├── FinishEstimation/    # Predicted time, splits, confidence interval
│   │   ├── Progress/            # Training load, volume charts, plan adherence
│   │   ├── Profile/             # Athlete data, settings, HealthKit sync
│   │   └── Settings/            # App preferences, units, notifications
│   ├── Components/             # Reusable UI components
│   ├── Navigation/             # Router / Coordinator
│   └── Theme/                  # Colors, fonts, spacing tokens
├── Services/                   # App-level services
│   ├── LocationService.swift    # GPS tracking, background location
│   ├── HealthKitService.swift   # HR, calories, workout import
│   ├── NotificationService.swift
│   ├── ElevationService.swift   # Elevation data processing & smoothing
│   └── AnalyticsService.swift
├── Resources/                  # Assets, Localizable strings, Info.plist
└── Tests/
    ├── UnitTests/
    │   ├── Domain/
    │   ├── Data/
    │   └── Presentation/
    └── UITests/
```

### Structure Rules

- Every feature folder under `Presentation/Features/` must contain its own `View`, `ViewModel`, and optional `Components/` subfolder.
- Domain layer must NEVER import UIKit, SwiftUI, or any framework. Pure Swift only.
- Data layer depends on Domain. Presentation depends on Domain. Neither Data nor Presentation depend on each other.
- No file should exceed 300 lines. Split aggressively.
- One type per file. File name must match the type name exactly.

---

## 3. Security Rules

### Secrets & Credentials
- NEVER hardcode API keys, tokens, secrets, or passwords in source code.
- Store secrets in Xcode project configuration files (`.xcconfig`) that are listed in `.gitignore`.
- Use Keychain Services (via a `KeychainManager` wrapper) for storing user tokens, session data, and credentials at runtime.
- NEVER log secrets, tokens, or PII — not even in `#if DEBUG` blocks.

### Network Security
- All network requests must use HTTPS. No exceptions. No App Transport Security exemptions unless explicitly approved.
- Pin certificates for the production API domain using `URLSessionDelegate` with `SecTrust` evaluation.
- Set `timeoutInterval` on all requests (30s default, configurable per endpoint).
- Implement request signing with HMAC-SHA256 for all authenticated endpoints.
- Validate all TLS certificates — never disable validation, even in debug.

### Data Protection
- Enable Data Protection entitlement with `NSFileProtectionComplete`.
- All local databases (SwiftData/CoreData) must use encrypted stores.
- Wipe sensitive data from memory after use (`defer { sensitiveData = Data(); }`).
- Biometric authentication (Face ID / Touch ID) required for accessing health and personal data.

### Input Validation
- Validate ALL inputs at the API boundary before passing to domain layer.
- Use strongly-typed models — never pass raw `String` or `Any` for structured data.
- Sanitize all user-entered text before display or storage (prevent injection).
- Validate GPS coordinates, heart rate, pace values against sane ranges before persisting.

### Authentication & Authorization
- Use short-lived JWT access tokens (15 min max) with refresh token rotation.
- Store refresh tokens in Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
- Implement token refresh transparently via a request interceptor / middleware in the networking layer.
- Clear all tokens and cached data on logout.
- Implement jailbreak detection — degrade gracefully (warn user), don't crash.

### Privacy
- Request only necessary permissions (Location, HealthKit, Notifications) — request lazily at point of use, never at launch.
- Provide clear in-app explanations before each permission prompt.
- All analytics must be anonymized. No PII in analytics payloads.
- Comply with App Tracking Transparency (ATT) framework.

---

## 4. API & Networking Rules

### Client Architecture
```
Network/
├── APIClient.swift              # Single entry point, generic request executor
├── APIEndpoint.swift            # Protocol defining endpoint contract
├── Endpoints/                   # Concrete endpoint definitions per feature
│   ├── AuthEndpoints.swift
│   ├── TrainingEndpoints.swift
│   ├── RunEndpoints.swift
│   └── NutritionEndpoints.swift
├── Interceptors/                # Request/response middleware
│   ├── AuthInterceptor.swift
│   ├── LoggingInterceptor.swift
│   └── RetryInterceptor.swift
├── DTOs/                        # Data Transfer Objects (Codable structs)
└── APIError.swift               # Typed API errors
```

### Endpoint Definition Pattern
```swift
// Every endpoint must conform to this protocol
protocol APIEndpoint {
    associatedtype RequestBody: Encodable
    associatedtype ResponseBody: Decodable

    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: RequestBody? { get }
    var queryItems: [URLQueryItem]? { get }
    var requiresAuth: Bool { get }
}
```

### Networking Rules
- Use `URLSession` with async/await — no third-party HTTP libraries (no Alamofire, no Moya).
- All API calls must return `Result<T, APIError>` or throw typed errors — never force-unwrap responses.
- Implement exponential backoff retry (max 3 attempts) for 5xx errors and network timeouts.
- No retry on 4xx errors — surface them immediately.
- All DTOs must be separate from Domain models. Map at the Data layer boundary.
- Use `JSONDecoder` with `keyDecodingStrategy = .convertFromSnakeCase`.
- All requests must include: `Accept: application/json`, `Content-Type: application/json`, and an `X-Client-Version` header.
- Implement request deduplication — identical in-flight requests must be coalesced.
- Support offline mode: queue mutations locally and sync when connectivity resumes.

### Server Actions / Backend Integration
- Define server actions as use cases in the Domain layer (`protocol`), implemented in the Data layer.
- Group server-triggered mutations (sync training plan, upload run data) in a `SyncService`.
- Use background URLSession for uploading run GPS tracks and large payloads.
- Implement idempotency keys for all POST/PUT/PATCH requests to prevent duplicate writes.
- All sync operations must be resumable — persist sync state to handle app termination.
- Use push notifications (APNs) for server-initiated updates, not polling.

---

## 5. Code Quality & Performance

### Swift Conventions
- Use `struct` over `class` unless reference semantics are explicitly required.
- Mark all classes as `final` unless designed for inheritance.
- Use `private` by default. Expand access only as needed (`internal`, then `public`).
- Use `@MainActor` for all ViewModels. Use structured concurrency (`Task`, `TaskGroup`, `AsyncStream`) — no raw GCD.
- Prefer `[weak self]` in closures. Never create retain cycles.
- Use `guard` for early exits. Avoid deeply nested `if` statements.
- No force unwraps (`!`) except in tests or with a preceding comment explaining the invariant.
- No `print()` statements — use `os.Logger` with appropriate log levels.

### Performance
- Lazy-load all heavy resources (images, map tiles, large datasets).
- Use `LazyVStack` / `LazyHStack` for scrollable lists — never render all items eagerly.
- Profile with Instruments before optimizing. Don't optimize speculatively.
- GPS tracking must use `CLLocationManager` with appropriate `desiredAccuracy` and `distanceFilter` to balance accuracy vs battery:
  - Active run: `kCLLocationAccuracyBest`, `distanceFilter: 5`
  - Background: `kCLLocationAccuracyNearestTenMeters`, `distanceFilter: 20`
- Cache API responses with TTL. Use `URLCache` for GET requests and in-memory cache for computed data.
- Debounce user input (search, filters) at 300ms minimum.

### SwiftUI Specifics
- Extract subviews when a `body` exceeds 40 lines.
- Use `@Observable` (Observation framework, iOS 17+) instead of `ObservableObject` / `@Published`.
- Never perform I/O or heavy computation inside `body`. Use `.task {}` modifier.
- Use `EnvironmentKey` for dependency injection into the view hierarchy.
- Prefer `ViewModifier` over `View` extension for reusable styling.

---

## 6. Data & Persistence

- Use **SwiftData** as the primary local persistence framework.
- Define `@Model` classes only in `Data/DataSources/Local/`.
- Map SwiftData models to Domain entities at the repository boundary — never expose `@Model` types to Presentation or Domain.
- All database writes must happen on a background `ModelContext`.
- Implement data migration strategy from day one — never assume schema won't change.
- HealthKit data (heart rate, calories, steps) read via `HealthKitService` and mapped to domain models. Never store raw HealthKit data locally — query on demand.

---

## 7. Error Handling

- Define a `DomainError` enum with human-readable cases (`case networkUnavailable`, `case invalidTrainingPlan(reason: String)`, etc.).
- Map all lower-level errors (API, database, system) to `DomainError` before they reach ViewModels.
- Every ViewModel must expose an `error` state that the View observes and displays.
- Use `.alert` or a reusable `ErrorBannerView` — never silently swallow errors.
- Log all errors with `os.Logger` including context (endpoint, parameters, stack).

---

## 8. Testing

- Minimum 80% code coverage on Domain and Data layers.
- All use cases must have unit tests.
- All ViewModels must have unit tests using mock repositories.
- Use Swift Testing framework (`@Test`, `#expect`) — not XCTest for new tests.
- Name tests descriptively: `func testStartRun_whenGPSUnavailable_returnsLocationError()`.
- Use protocol-based dependency injection — every external dependency must be injectable via protocol.
- No singletons. Use dependency injection containers.
- UI tests for critical flows: onboarding, start/stop run, view training plan.

---

## 9. Git & Workflow

- Branch naming: `feature/`, `fix/`, `refactor/`, `test/` prefixes.
- Commit messages: imperative mood, max 72 chars subject line.
- Never commit `.xcconfig` files, `Secrets/`, or any file containing credentials.
- Run `swiftlint` and all tests before committing.
- One feature per branch. Small, focused PRs.

---

## 10. Dependencies (Approved List)

Only these external packages are approved. Any addition requires explicit approval:

| Package | Purpose |
|---|---|
| swift-algorithms | Collection algorithms |
| swift-collections | Deque, OrderedSet, etc. |
| swift-dependencies | DI container (Point-Free) |
| Kingfisher | Image loading/caching |
| MapboxMaps or MapKit | Route mapping |

No Firebase unless explicitly approved. No third-party analytics SDKs without privacy review.

---

## 11. Domain-Specific Algorithms & Models

### Finish Time Estimation
- Use **effort-based distance** (Kilian's coefficient or equivalent): `effective_km = horizontal_km + (elevation_gain_m / 100)`. One formula: every 100m D+ adds ~1 km equivalent effort.
- Calibrate per athlete using their actual race/training data (recent long runs with elevation).
- Model: `predicted_time = effective_km * pace_per_effective_km`, where pace is derived from athlete's recent performances adjusted for fatigue/taper.
- Provide 3 scenarios: **optimistic** (best recent form, good conditions), **expected** (average recent form), **conservative** (fatigue, bad weather, rough terrain).
- Recalculate whenever new training data is logged.

### Training Plan Periodization
- **Phases:** Base (aerobic foundation) → Build (race-specific intensity) → Peak (sharpening) → Taper (reduction before race).
- Phase durations scale with weeks available and race distance.
- Long run progression: never increase weekly D+ or distance by more than 10% week-over-week.
- Recovery weeks: reduce volume by 30-40% every 3rd or 4th week.
- B-race integration: insert a mini-taper (3-5 days) before and recovery (3-7 days) after intermediate races.

### Training Load Metrics
- **Volume:** total km, total D+, total time per week.
- **Monotony:** stddev of daily load — flag if training is too monotonous or too erratic.
- **Acute-to-Chronic ratio:** 7-day load / 28-day average load. Flag if > 1.5 (injury risk) or < 0.8 (detraining).
- Simplified **Fitness** (42-day EMA of load), **Fatigue** (7-day EMA), **Form** (Fitness - Fatigue).

### Nutrition Calculation
- Race-day caloric need: `calories_per_hour = body_weight_kg * 4 to 6` (adjustable by intensity).
- Hydration: 400-800 ml/hour depending on heat/humidity (user can set conditions).
- Electrolytes: ~500-700 mg sodium/hour for ultras.
- Gut training: flag long runs (>2h) where athlete should practice race nutrition.

### Key Domain Entities
```
Athlete          — profile, experience, physical data, fitness metrics
Race             — name, date, distance, D+, D-, priority (A/B/C), checkpoints
TrainingPlan     — periodized plan linked to A-race, contains TrainingWeeks
TrainingWeek     — collection of TrainingSessions, phase label, volume targets
TrainingSession  — type, distance, D+, duration, intensity, nutrition notes
CompletedRun     — GPS track, splits, HR data, actual vs. planned comparison
NutritionPlan    — race-day strategy, per-session recommendations
NutritionEntry   — product, calories, timing, quantity
FinishEstimate   — predicted time (3 scenarios), per-checkpoint splits, confidence
FitnessSnapshot  — daily CTL/ATL/TSB, weekly volume summary
```

---

## Quick Reference: What NOT To Do

- Do NOT use `UserDefaults` for anything sensitive (tokens, PII, health data).
- Do NOT use `Any`, `AnyObject`, or untyped dictionaries in interfaces.
- Do NOT use storyboards or XIBs — SwiftUI only.
- Do NOT use Combine for new code — use async/await and Observation.
- Do NOT import the entire module when you need one type — use `@_exported` sparingly.
- Do NOT create god objects. No manager/helper/utility class over 200 lines.
- Do NOT use third-party libraries without checking their license, maintenance status, and security track record.
