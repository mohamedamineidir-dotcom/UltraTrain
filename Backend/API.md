# UltraTrain API Reference

## Base URL

```
Production: https://ultratrain-production.up.railway.app/v1
Local:      http://localhost:8080/v1
```

## Request Headers

All requests must include:

| Header | Value | Required |
|--------|-------|----------|
| `Accept` | `application/json` | Yes |
| `Content-Type` | `application/json` | Yes (for POST/PUT) |
| `Authorization` | `Bearer <access_token>` | For authenticated endpoints |
| `X-Client-Version` | App version (e.g. `1.0.0`) | Yes |
| `X-Signature` | HMAC-SHA256 signature | When HMAC is enabled |
| `X-Timestamp` | Unix timestamp | When HMAC is enabled |

## Authentication

- Access tokens are JWTs with 15-minute expiry
- Refresh tokens are UUIDs, hashed with SHA256 server-side
- Use `POST /auth/refresh` to obtain new tokens before expiry
- All tokens are invalidated on logout and password change

## Data Formats

- Dates: ISO 8601 (e.g. `2026-03-01T12:00:00Z`)
- JSON keys: `snake_case` (server encodes/decodes with `convertToSnakeCase`)
- Pagination: cursor-based with `next_cursor` (ISO 8601 date) and `has_more`
- Large data: GPS tracks, race configs, and training plans stored as JSON strings

## Idempotency

POST/PUT endpoints for runs, races, plans, activities, challenges, and shared runs accept an `idempotency_key` field. Duplicate requests with the same key return `200 OK` with the existing resource.

## Conflict Detection

Run and race updates support `client_updated_at`. If the server's `updated_at` is newer, the server returns `409 Conflict`.

---

## Auth

Rate limit: 5 requests / 60 seconds on public endpoints.

### POST /auth/register

Register a new account.

**Request:**
```json
{
  "email": "runner@example.com",
  "password": "securePassword123"
}
```

**Response (200):**
```json
{
  "access_token": "eyJhbGciOi...",
  "refresh_token": "550e8400-e29b-41d4-a716-446655440000",
  "expires_in": 900,
  "token_type": "Bearer"
}
```

### POST /auth/login

**Request:**
```json
{
  "email": "runner@example.com",
  "password": "securePassword123"
}
```

**Response:** Same as register.

### POST /auth/refresh

**Request:**
```json
{
  "refresh_token": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response:** Same as register (new token pair).

### POST /auth/forgot-password

Sends a 6-digit reset code via email. Code expires in 10 minutes.

**Request:**
```json
{
  "email": "runner@example.com"
}
```

**Response:**
```json
{
  "message": "If an account exists with that email, a reset code has been sent."
}
```

### POST /auth/reset-password

**Request:**
```json
{
  "email": "runner@example.com",
  "code": "123456",
  "new_password": "newSecurePassword"
}
```

### POST /auth/logout `Auth`

Invalidates refresh token. Returns `204 No Content`.

### POST /auth/change-password `Auth`

Invalidates all sessions.

**Request:**
```json
{
  "current_password": "oldPassword",
  "new_password": "newPassword123"
}
```

### DELETE /auth/account `Auth`

Permanently deletes account and all associated data (runs, races, plans, athlete profile, social data). Returns `204 No Content`.

### POST /auth/verify-email `Auth`

**Request:**
```json
{
  "code": "123456"
}
```

### POST /auth/resend-verification `Auth`

Resends verification code if email not yet verified.

---

## Athlete

All endpoints require authentication.

### GET /athlete

Returns the authenticated user's athlete profile. Returns `404` if not created yet.

**Response:**
```json
{
  "id": "uuid",
  "first_name": "Mohamed",
  "last_name": "Idir",
  "date_of_birth": "1990-01-15T00:00:00Z",
  "weight_kg": 72.0,
  "height_cm": 178.0,
  "resting_heart_rate": 55,
  "max_heart_rate": 185,
  "experience_level": "intermediate",
  "weekly_volume_km": 45.0,
  "longest_run_km": 42.0,
  "updated_at": "2026-03-01T12:00:00Z"
}
```

### PUT /athlete

Create or update athlete profile.

**Request:**
```json
{
  "first_name": "Mohamed",
  "last_name": "Idir",
  "date_of_birth": "1990-01-15T00:00:00Z",
  "weight_kg": 72.0,
  "height_cm": 178.0,
  "resting_heart_rate": 55,
  "max_heart_rate": 185,
  "experience_level": "intermediate",
  "weekly_volume_km": 45.0,
  "longest_run_km": 42.0
}
```

**Validation:** weight 20-300, height 100-250, resting HR 30-120, max HR 100-230.

---

## Runs

All endpoints require authentication.

### POST /runs

Upload a new run. GPS track limited to 100,000 points, splits to 1,000.

**Request:**
```json
{
  "id": "uuid",
  "date": "2026-03-01T08:30:00Z",
  "distance_km": 21.1,
  "elevation_gain_m": 850,
  "elevation_loss_m": 820,
  "duration": 7200,
  "average_heart_rate": 152,
  "max_heart_rate": 178,
  "average_pace_seconds_per_km": 341,
  "gps_track": [
    {"latitude": 45.123, "longitude": 6.456, "altitude_m": 1200, "timestamp": "2026-03-01T08:30:00Z", "heart_rate": 145}
  ],
  "splits": [
    {"id": "uuid", "kilometer_number": 1, "duration": 320, "elevation_change_m": 45, "average_heart_rate": 148}
  ],
  "notes": "Felt strong on the climbs",
  "linked_session_id": "uuid-of-training-session",
  "idempotency_key": "unique-key"
}
```

**Response (201):** Full run object with server timestamps.

### GET /runs

List runs (paginated, cursor-based, newest first).

**Query parameters:** `since` (ISO 8601), `cursor` (ISO 8601), `limit` (default 20, max 100).

**Response:**
```json
{
  "items": [...],
  "next_cursor": "2026-02-28T12:00:00Z",
  "has_more": true
}
```

### GET /runs/:runId

Fetch single run by ID. Returns `404` if not found.

### PUT /runs/:runId

Update run. Supports conflict detection via `client_updated_at`.

### DELETE /runs/:runId

Delete run. Returns `204 No Content`.

---

## Races

All endpoints require authentication.

### PUT /races

Upsert race (insert or update by `race_id`). Supports idempotency and conflict detection.

**Request:**
```json
{
  "race_id": "unique-race-id",
  "name": "UTMB 2026",
  "date": "2026-08-29T04:00:00Z",
  "distance_km": 171,
  "elevation_gain_m": 10000,
  "priority": "aRace",
  "race_json": "{...}",
  "idempotency_key": "unique-key"
}
```

**Priority values:** `aRace`, `bRace`, `cRace`.

### GET /races

List races (paginated, sorted ascending by date).

**Query parameters:** `cursor`, `limit` (default 20, max 100).

### DELETE /races/:raceId

Delete race. Returns `204 No Content`.

---

## Training Plan

All endpoints require authentication. One plan per user.

### PUT /training-plan

Create or replace training plan.

**Request:**
```json
{
  "plan_id": "uuid",
  "target_race_name": "UTMB 2026",
  "target_race_date": "2026-08-29T04:00:00Z",
  "total_weeks": 24,
  "plan_json": "{...}",
  "idempotency_key": "unique-key"
}
```

### GET /training-plan

Fetch the user's training plan. Returns `404` if none exists.

---

## Social Profile

All endpoints require authentication.

### GET /social/profile

Get authenticated user's social profile with aggregated stats.

**Response:**
```json
{
  "id": "uuid",
  "display_name": "Mohamed I.",
  "bio": "Ultra trail runner",
  "experience_level": "intermediate",
  "is_public_profile": true,
  "total_distance_km": 1250.5,
  "total_elevation_gain_m": 45000,
  "total_runs": 87,
  "joined_date": "2025-06-15T10:00:00Z"
}
```

### PUT /social/profile

Update display name, bio, and visibility.

**Request:**
```json
{
  "display_name": "Mohamed I.",
  "bio": "Ultra trail runner",
  "is_public_profile": true
}
```

### GET /social/profile/:profileId

Get another user's public profile. Returns `404` if private.

### GET /social/search?q=query

Search public profiles by name. Returns up to 20 results.

---

## Friends

All endpoints require authentication.

### POST /friends/request

Send friend request.

**Request:**
```json
{
  "recipient_profile_id": "uuid"
}
```

### GET /friends

List accepted friends.

### GET /friends/pending

List incoming pending requests.

### PUT /friends/:connectionId/accept

Accept pending request. Only the recipient can accept.

### PUT /friends/:connectionId/decline

Decline pending request.

### DELETE /friends/:connectionId

Remove friend connection. Either party can remove.

**Response format for all friend endpoints:**
```json
{
  "id": "uuid",
  "friend_profile_id": "uuid",
  "friend_display_name": "Alice R.",
  "status": "accepted",
  "created_date": "2026-02-15T10:00:00Z",
  "accepted_date": "2026-02-15T12:00:00Z"
}
```

---

## Activity Feed

All endpoints require authentication.

### GET /feed?limit=50

Get activity feed (own + accepted friends). Sorted newest first. Default limit 50.

### POST /feed

Publish activity to feed.

**Request:**
```json
{
  "activity_type": "completedRun",
  "title": "Morning long run",
  "subtitle": "21km with 850m D+",
  "distance_km": 21.1,
  "elevation_gain_m": 850,
  "duration": 7200,
  "average_pace": 341,
  "timestamp": "2026-03-01T10:30:00Z",
  "idempotency_key": "unique-key"
}
```

**Activity types:** `completedRun`, `personalRecord`, `challengeCompleted`, `raceFinished`, `weeklyGoalMet`, `friendJoined`.

### POST /feed/:itemId/like

Toggle like (add or remove). Returns `{ "liked": true, "like_count": 5 }`.

---

## Shared Runs

All endpoints require authentication.

### POST /shared-runs

Share a run with accepted friends. GPS track limited to 100,000 points.

**Request:**
```json
{
  "id": "uuid",
  "date": "2026-03-01T08:30:00Z",
  "distance_km": 21.1,
  "elevation_gain_m": 850,
  "elevation_loss_m": 820,
  "duration": 7200,
  "average_pace": 341,
  "gps_track": [...],
  "splits": [...],
  "recipient_profile_ids": ["uuid-1", "uuid-2"],
  "idempotency_key": "unique-key"
}
```

### GET /shared-runs?limit=20

List runs shared with me (newest first).

### GET /shared-runs/mine

List runs I have shared.

### DELETE /shared-runs/:sharedRunId

Revoke a shared run. Only the sharer can delete.

---

## Group Challenges

All endpoints require authentication.

### POST /challenges

Create a new challenge. Creator is auto-added as participant.

**Request:**
```json
{
  "name": "March Distance Challenge",
  "description_text": "Run 200km total this month",
  "type": "distance",
  "target_value": 200,
  "start_date": "2026-03-01T00:00:00Z",
  "end_date": "2026-03-31T23:59:59Z",
  "idempotency_key": "unique-key"
}
```

**Challenge types:** `distance`, `elevation`, `consistency`, `streak`.

### GET /challenges?status=active

List challenges user participates in. Optional status filter.

### GET /challenges/:challengeId

Get challenge details with all participants and their progress.

### POST /challenges/:challengeId/join

Join an active challenge.

### POST /challenges/:challengeId/leave

Leave a challenge. Creator cannot leave.

### PUT /challenges/:challengeId/progress

Update your progress.

**Request:**
```json
{
  "value": 45.5
}
```

---

## Device Token

### PUT /device-token `Auth`

Register device for push notifications.

**Request:**
```json
{
  "device_token": "apns-token-hex-string",
  "platform": "ios",
  "apns_environment": "production"
}
```

---

## Health Check

### GET /health

No authentication required. Returns `{ "status": "ok" }`.

---

## Privacy / Terms

### GET /privacy

Returns HTML privacy policy. No authentication.

### GET /terms

Returns HTML terms of service. No authentication.

---

## Error Responses

All errors follow this format:

```json
{
  "error": true,
  "reason": "Human-readable error description"
}
```

| Status | Meaning |
|--------|---------|
| 400 | Bad request / validation error |
| 401 | Unauthorized / invalid or expired token |
| 403 | Forbidden |
| 404 | Resource not found |
| 409 | Conflict (server version newer than client) |
| 429 | Rate limit exceeded |
| 500 | Internal server error |
