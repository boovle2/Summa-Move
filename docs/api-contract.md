# SummaMove API-contract

Basis-URL: `/api/v1`

Formaat: JSON

Authenticatie: `Authorization: Bearer <sanctum-token>`

## Regels

- `user_id` komt altijd uit het Sanctum-token.
- Een toestel heeft een actieve health-bron.
- Android gebruikt `health_connect` of `samsung_health`; iOS gebruikt `healthkit`.
- De app levert tijden aan als ISO-8601; Laravel slaat ze op in UTC en bewaart de originele tijdzone.
- `records` en `workouts` bevatten samen maximaal 500 items.
- `sync_id` is idempotent.
- Unieke scalar record key: `user_id + source + metric_type + external_id`.
- Cursor wordt alleen bijgewerkt na een volledig geslaagde sync.
- Ontbrekende waarden blijven `null`.
- Workout-calorieen tellen niet mee als algemene actieve calorieen.
- Laravel logt geen volledige health-payloads.

## Metrics

| Type | Eenheid |
|---|---|
| `steps` | `count` |
| `heart_rate` | `bpm` |
| `active_energy_burned` | `kcal` |
| `dietary_energy_consumed` | `kcal` |
| `water_intake` | `ml` |
| `workout_session` | `seconds` |

## Auth

### `POST /auth/register`

```json
{
  "name": "Demo User",
  "email": "demo@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "device_name": "flutter-demo"
}
```

### `POST /auth/login`

```json
{
  "email": "demo@example.com",
  "password": "password123",
  "device_name": "flutter-demo"
}
```

Register en login geven `data.user` en `data.token` terug. Logout gebruikt:

```text
DELETE /auth/logout
```

## Devices

### `PUT /devices/{client_device_id}`

```json
{
  "platform": "android",
  "active_source": "health_connect",
  "app_version": "0.1.0",
  "granted_metrics": ["steps", "heart_rate", "active_energy_burned", "workout_session"]
}
```

De actieve bron moet passen bij het platform en bij de syncbron.

## Health sync

### `POST /health/sync`

```json
{
  "sync_id": "68b344e7-8cb8-45ec-a18c-1863a29387e1",
  "device_id": "summamove-demo-device",
  "source": "health_connect",
  "cursor": "2026-06-16T17:10:31Z",
  "records": [
    {
      "external_id": "steps-2026-06-16",
      "metric_type": "steps",
      "value": 8450,
      "unit": "count",
      "measured_from": "2026-06-15T22:00:00Z",
      "measured_to": "2026-06-16T21:59:59Z",
      "timezone": "Europe/Amsterdam"
    }
  ],
  "workouts": []
}
```

Succesresponse:

```json
{
  "data": {
    "sync_id": "68b344e7-8cb8-45ec-a18c-1863a29387e1",
    "status": "completed",
    "stored": 1,
    "duplicates": 0,
    "rejected": 0,
    "next_cursor": "2026-06-16T17:10:31Z"
  }
}
```

Voorbeelden staan in `docs/fixtures/`.

## Health status en dagoverzicht

```text
GET /health/status?device_id=summamove-demo-device
GET /health/daily-summary?date=2026-06-16&timezone=Europe/Amsterdam
```

Dagoverzicht geeft totalen voor stappen, actieve calorieen, voeding, water en workoutduur. Hartslag geeft `latest`, `average`, `minimum` en `maximum`.

## Productroutes

Deze routes gebruiken dezelfde Sanctum-token:

```text
GET /me/home
GET /me/profile
GET /me/settings
PUT /me/settings

GET /challenges
GET /challenges/{challenge}
POST /challenges/{challenge}/start
GET /challenge-assignments

GET /friends
GET /friend-requests
POST /friend-requests
POST /friend-requests/{request}/accept
POST /friend-requests/{request}/decline
POST /friends/{friend}/challenge

GET /messages/{friend}
POST /messages/{friend}

GET /teams
GET /teams/{team}

GET /shop/items
POST /shop/items/{item}/purchase
PUT /characters/{item}/equip

GET /rankings?period=today|week|progress|friends
```

## Adminroutes

Adminroutes vereisen een gebruiker met rol `admin`.

```text
GET /admin/dashboard
GET|POST|PUT|DELETE /admin/challenges
GET|POST|PUT|DELETE /admin/shop-items
GET|POST|PUT|DELETE /admin/teams
GET|PUT /admin/users
POST /admin/assignments
POST /admin/point-adjustments
POST /admin/demo-health
GET /admin/audits
```

Admin-demo-health gebruikt bron `admin_demo`. Die data telt mee voor profiel/challenges, maar niet voor leaderboards.
